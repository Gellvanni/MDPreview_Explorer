using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32.SafeHandles;

namespace MdExplorerPreview.AutoUnblocker
{
    internal sealed class AutoUnblockerHost : IDisposable
    {
        private readonly AutoUnblockerSettings settings;
        private readonly string settingsPath;
        private readonly AutoUnblockerLogger logger;
        private readonly List<FileSystemWatcher> watchers = new List<FileSystemWatcher>();
        private readonly ConcurrentDictionary<string, PendingFileCandidate> pendingFiles =
            new ConcurrentDictionary<string, PendingFileCandidate>(StringComparer.OrdinalIgnoreCase);
        private readonly CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();

        private Task? processingTask;
        private bool disposed;

        public AutoUnblockerHost(
            AutoUnblockerSettings settings,
            string settingsPath,
            AutoUnblockerLogger logger)
        {
            this.settings = settings;
            this.settingsPath = settingsPath;
            this.logger = logger;
        }

        public bool Start()
        {
            if (!settings.AutoUnblockEnabled)
            {
                logger.Log("info", "watcher", settingsPath, null, null, false, "disabled", "Auto-unblock is disabled in settings.");
                return false;
            }

            var enabledFolders = settings.EnabledWatchFolders.ToArray();
            if (enabledFolders.Length == 0)
            {
                logger.Log("warn", "watcher", settingsPath, null, null, false, "no-folders", "No enabled watch folders were found in settings.");
                return false;
            }

            logger.Log(
                "info",
                "startup",
                settingsPath,
                null,
                null,
                false,
                "settings-loaded",
                $"Folders={enabledFolders.Length}; Extensions={settings.AllowedExtensionsNormalized.Count}; ScanOnStartup={settings.ScanOnStartup}; UnblockZipOnArrival={settings.UnblockZipOnArrival}; DryRun={settings.DryRun}.");

            processingTask = Task.Run(ProcessPendingLoopAsync);

            foreach (var folder in enabledFolders)
            {
                var expandedPath = folder.ExpandedPath;
                Directory.CreateDirectory(expandedPath);

                var watcher = new FileSystemWatcher(expandedPath)
                {
                    IncludeSubdirectories = folder.Recursive,
                    NotifyFilter = NotifyFilters.FileName | NotifyFilters.CreationTime | NotifyFilters.LastWrite | NotifyFilters.Size,
                    Filter = "*.*",
                    InternalBufferSize = 64 * 1024
                };

                watcher.Created += (sender, args) => SchedulePath(args.FullPath, folder, "created");
                watcher.Changed += (sender, args) => SchedulePath(args.FullPath, folder, "changed");
                watcher.Renamed += (sender, args) => SchedulePath(args.FullPath, folder, "renamed");
                watcher.Error += (sender, args) =>
                    logger.Log("error", "watcher", expandedPath, folder.Name, null, false, "watcher-error", args.GetException()?.Message ?? "Unknown FileSystemWatcher error.");

                watcher.EnableRaisingEvents = true;
                watchers.Add(watcher);

                logger.Log("info", "watcher", expandedPath, folder.Name, null, false, "watching", $"Recursive={folder.Recursive}.");

                if (settings.ScanOnStartup)
                {
                    ScheduleStartupScan(folder);
                }
            }

            return true;
        }

        public void Dispose()
        {
            if (disposed)
            {
                return;
            }

            disposed = true;
            cancellationTokenSource.Cancel();

            foreach (var watcher in watchers)
            {
                watcher.Dispose();
            }

            try
            {
                processingTask?.Wait(TimeSpan.FromSeconds(3));
            }
            catch
            {
                // Shutdown should stay silent.
            }

            cancellationTokenSource.Dispose();
        }

        private void ScheduleStartupScan(TrustedFolderSettings folder)
        {
            var searchOption = folder.Recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
            foreach (var file in Directory.EnumerateFiles(folder.ExpandedPath, "*.*", searchOption))
            {
                SchedulePath(file, folder, "startup-scan");
            }
        }

        private void SchedulePath(string? path, TrustedFolderSettings folder, string trigger)
        {
            if (string.IsNullOrWhiteSpace(path) || Directory.Exists(path))
            {
                return;
            }

            var candidatePath = Path.GetFullPath(path!);
            var extension = Path.GetExtension(candidatePath);
            if (string.IsNullOrWhiteSpace(extension))
            {
                return;
            }

            if (!settings.IsExtensionAllowed(extension))
            {
                if (ShouldLogIgnore(trigger))
                {
                    logger.Log("info", "decision", candidatePath, folder.Name, extension, false, "ignored-extension", "Extension is not on the allowlist.");
                }

                return;
            }

            if (string.Equals(extension, ".zip", StringComparison.OrdinalIgnoreCase) && !settings.UnblockZipOnArrival)
            {
                if (ShouldLogIgnore(trigger))
                {
                    logger.Log("info", "decision", candidatePath, folder.Name, extension, false, "ignored-zip", "ZIP auto-unblock is disabled; extracted allowed files will still be handled later.");
                }

                return;
            }

            var now = DateTime.UtcNow;
            pendingFiles.AddOrUpdate(
                candidatePath,
                key => PendingFileCandidate.Create(candidatePath, folder.Name, extension, trigger, now, now.Add(settings.SettleDelay)),
                (key, existing) => existing.Reschedule(trigger, now.Add(settings.SettleDelay)));
        }

        private async Task ProcessPendingLoopAsync()
        {
            while (!cancellationTokenSource.Token.IsCancellationRequested)
            {
                var now = DateTime.UtcNow;
                foreach (var entry in pendingFiles.ToArray())
                {
                    if (entry.Value.DueAtUtc > now)
                    {
                        continue;
                    }

                    if (!pendingFiles.TryRemove(entry.Key, out var candidate))
                    {
                        continue;
                    }

                    ProcessCandidate(candidate);
                }

                try
                {
                    await Task.Delay(250, cancellationTokenSource.Token).ConfigureAwait(false);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }
        }

        private void ProcessCandidate(PendingFileCandidate candidate)
        {
            if (!File.Exists(candidate.Path))
            {
                logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "ignored-missing", "The file no longer exists when processing started.");
                return;
            }

            if (!TryEnsureFileIsStable(candidate, out var deferReason))
            {
                RescheduleOrGiveUp(candidate, deferReason);
                return;
            }

            try
            {
                if (settings.DryRun)
                {
                    var hasZone = ZoneIdentifierHelper.HasZoneIdentifier(candidate.Path);
                    if (hasZone)
                    {
                        logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, true, "dry-run-match", $"Trigger={candidate.Trigger}.");
                    }
                    else
                    {
                        logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "ignored-no-zone", "No Zone.Identifier stream was found.");
                    }

                    return;
                }

                var removeResult = ZoneIdentifierHelper.TryRemove(candidate.Path);
                switch (removeResult.Status)
                {
                    case ZoneRemovalStatus.Removed:
                        logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, true, "unblocked", $"Trigger={candidate.Trigger}.");
                        return;
                    case ZoneRemovalStatus.NotPresent:
                        if (ShouldRetryMissingZone(candidate))
                        {
                            if (candidate.RetryCount == 0)
                            {
                                logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "zone-pending", "Zone.Identifier was not present yet; rechecking before concluding that the file is local or already unblocked.");
                            }

                            pendingFiles[candidate.Path] = candidate.Retry(DateTime.UtcNow.Add(settings.RetryDelay));
                            return;
                        }

                        logger.Log("info", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "ignored-no-zone", "No Zone.Identifier stream was found.");
                        return;
                    case ZoneRemovalStatus.RetryableError:
                        RescheduleOrGiveUp(candidate, removeResult.Details);
                        return;
                    default:
                        logger.Log("error", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "error", removeResult.Details);
                        return;
                }
            }
            catch (Exception ex)
            {
                logger.Log("error", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "exception", ex.Message);
            }
        }

        private bool TryEnsureFileIsStable(PendingFileCandidate candidate, out string details)
        {
            details = "The file is still being written.";

            var writeAge = DateTime.UtcNow - File.GetLastWriteTimeUtc(candidate.Path);
            if (writeAge < settings.SettleDelay)
            {
                details = $"Last write was {writeAge.TotalMilliseconds:N0}ms ago.";
                return false;
            }

            try
            {
                using (new FileStream(candidate.Path, FileMode.Open, FileAccess.ReadWrite, FileShare.None))
                {
                    return true;
                }
            }
            catch (IOException ex)
            {
                details = ex.Message;
                return false;
            }
            catch (UnauthorizedAccessException ex)
            {
                details = ex.Message;
                return false;
            }
        }

        private void RescheduleOrGiveUp(PendingFileCandidate candidate, string details)
        {
            var now = DateTime.UtcNow;
            if ((now - candidate.FirstSeenUtc) >= settings.MaxWait)
            {
                logger.Log("warn", "decision", candidate.Path, candidate.FolderName, candidate.Extension, false, "timeout", details);
                return;
            }

            pendingFiles[candidate.Path] = candidate.Retry(now.Add(settings.RetryDelay));
        }

        private bool ShouldRetryMissingZone(PendingFileCandidate candidate)
        {
            if (string.Equals(candidate.Trigger, "startup-scan", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            if ((DateTime.UtcNow - candidate.FirstSeenUtc) >= settings.MaxWait)
            {
                return false;
            }

            try
            {
                var creationAge = DateTime.UtcNow - File.GetCreationTimeUtc(candidate.Path);
                if (creationAge > settings.MaxWait)
                {
                    return false;
                }
            }
            catch
            {
                // If creation time cannot be inspected, keep the conservative retry behavior.
            }

            return candidate.RetryCount < 64;
        }

        private static bool ShouldLogIgnore(string trigger)
        {
            return !string.Equals(trigger, "changed", StringComparison.OrdinalIgnoreCase)
                && !string.Equals(trigger, "startup-scan", StringComparison.OrdinalIgnoreCase);
        }
    }

    internal sealed class PendingFileCandidate
    {
        private PendingFileCandidate(
            string path,
            string folderName,
            string extension,
            string trigger,
            DateTime firstSeenUtc,
            DateTime dueAtUtc,
            int retryCount)
        {
            Path = path;
            FolderName = folderName;
            Extension = extension;
            Trigger = trigger;
            FirstSeenUtc = firstSeenUtc;
            DueAtUtc = dueAtUtc;
            RetryCount = retryCount;
        }

        public string Path { get; }

        public string FolderName { get; }

        public string Extension { get; }

        public string Trigger { get; }

        public DateTime FirstSeenUtc { get; }

        public DateTime DueAtUtc { get; }

        public int RetryCount { get; }

        public static PendingFileCandidate Create(
            string path,
            string folderName,
            string extension,
            string trigger,
            DateTime firstSeenUtc,
            DateTime dueAtUtc)
        {
            return new PendingFileCandidate(path, folderName, extension, trigger, firstSeenUtc, dueAtUtc, 0);
        }

        public PendingFileCandidate Reschedule(string trigger, DateTime dueAtUtc)
        {
            return new PendingFileCandidate(Path, FolderName, Extension, trigger, FirstSeenUtc, dueAtUtc, RetryCount);
        }

        public PendingFileCandidate Retry(DateTime dueAtUtc)
        {
            return new PendingFileCandidate(Path, FolderName, Extension, Trigger, FirstSeenUtc, dueAtUtc, RetryCount + 1);
        }
    }

    internal enum ZoneRemovalStatus
    {
        Removed,
        NotPresent,
        RetryableError,
        Failed
    }

    internal sealed class ZoneRemovalResult
    {
        public ZoneRemovalResult(ZoneRemovalStatus status, string details)
        {
            Status = status;
            Details = details;
        }

        public ZoneRemovalStatus Status { get; }

        public string Details { get; }
    }

    internal static class ZoneIdentifierHelper
    {
        private const int ErrorFileNotFound = 2;
        private const int ErrorPathNotFound = 3;
        private const int ErrorAccessDenied = 5;
        private const int ErrorSharingViolation = 32;
        private const int ErrorLockViolation = 33;
        private const uint GenericRead = 0x80000000;
        private const uint FileShareRead = 0x00000001;
        private const uint FileShareWrite = 0x00000002;
        private const uint FileShareDelete = 0x00000004;
        private const uint OpenExisting = 3;

        public static bool HasZoneIdentifier(string path)
        {
            var adsPath = GetAdsPath(path);

            try
            {
                using (var handle = CreateFile(
                    adsPath,
                    GenericRead,
                    FileShareRead | FileShareWrite | FileShareDelete,
                    IntPtr.Zero,
                    OpenExisting,
                    0,
                    IntPtr.Zero))
                {
                    if (!handle.IsInvalid)
                    {
                        return true;
                    }
                }

                var error = Marshal.GetLastWin32Error();
                return error == ErrorAccessDenied
                    || error == ErrorSharingViolation
                    || error == ErrorLockViolation;
            }
            catch
            {
                return false;
            }
        }

        public static ZoneRemovalResult TryRemove(string path)
        {
            var adsPath = GetAdsPath(path);

            try
            {
                if (DeleteFile(adsPath))
                {
                    return new ZoneRemovalResult(ZoneRemovalStatus.Removed, "Zone.Identifier removed.");
                }

                var error = Marshal.GetLastWin32Error();
                switch (error)
                {
                    case ErrorFileNotFound:
                    case ErrorPathNotFound:
                        return new ZoneRemovalResult(ZoneRemovalStatus.NotPresent, "No Zone.Identifier stream was found.");
                    case ErrorAccessDenied:
                    case ErrorSharingViolation:
                    case ErrorLockViolation:
                        return new ZoneRemovalResult(ZoneRemovalStatus.RetryableError, $"Win32 error {error} while deleting Zone.Identifier.");
                    default:
                        return new ZoneRemovalResult(ZoneRemovalStatus.Failed, $"Win32 error {error} while deleting Zone.Identifier.");
                }
            }
            catch (Exception ex)
            {
                return new ZoneRemovalResult(ZoneRemovalStatus.Failed, ex.Message);
            }
        }

        private static string GetAdsPath(string path)
        {
            return path + ":Zone.Identifier";
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateFile(
            string fileName,
            uint desiredAccess,
            uint shareMode,
            IntPtr securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool DeleteFile(string fileName);
    }
}
