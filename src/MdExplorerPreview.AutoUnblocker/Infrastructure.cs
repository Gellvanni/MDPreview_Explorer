using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace MdExplorerPreview.AutoUnblocker
{
    internal static class CommandLineOptions
    {
        public static string ResolveSettingsPath(string[] args)
        {
            for (var index = 0; index < args.Length; index++)
            {
                if (!string.Equals(args[index], "--settings", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if ((index + 1) >= args.Length)
                {
                    throw new InvalidOperationException("The --settings switch requires a file path.");
                }

                return Path.GetFullPath(args[index + 1]);
            }

            return SettingsPaths.GetDefaultSettingsPath();
        }
    }

    internal sealed class SingleInstanceGuard : IDisposable
    {
        private readonly Mutex mutex;

        private SingleInstanceGuard(Mutex mutex)
        {
            this.mutex = mutex;
        }

        public static SingleInstanceGuard? TryAcquire(string settingsPath)
        {
            var mutexName = @"Local\MdExplorerPreview.AutoUnblocker." + GetStableHash(settingsPath);
            var mutex = new Mutex(initiallyOwned: true, name: mutexName, createdNew: out var createdNew);
            if (!createdNew)
            {
                mutex.Dispose();
                return null;
            }

            return new SingleInstanceGuard(mutex);
        }

        public void Dispose()
        {
            mutex.ReleaseMutex();
            mutex.Dispose();
        }

        private static string GetStableHash(string value)
        {
            using (var sha256 = SHA256.Create())
            {
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(value.ToLowerInvariant()));
                return BitConverter.ToString(bytes).Replace("-", string.Empty).Substring(0, 16);
            }
        }
    }

    internal sealed class AutoUnblockerLogger : IDisposable
    {
        private readonly object syncRoot = new object();
        private readonly bool enabled;
        private readonly string logPath;

        private AutoUnblockerLogger(bool enabled, string logPath)
        {
            this.enabled = enabled;
            this.logPath = logPath;
        }

        public static AutoUnblockerLogger Create(AutoUnblockerSettings settings)
        {
            return new AutoUnblockerLogger(settings.LogEnabled, settings.ExpandedLogPath);
        }

        public void Log(
            string level,
            string category,
            string? path,
            string? folderName,
            string? extension,
            bool hadZone,
            string action,
            string details)
        {
            if (!enabled)
            {
                return;
            }

            try
            {
                var directory = Path.GetDirectoryName(logPath);
                if (!string.IsNullOrWhiteSpace(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                var line = string.Format(
                    "[{0:yyyy-MM-dd HH:mm:ss.fff}] level={1} category={2} action={3} hadZone={4} extension=\"{5}\" folder=\"{6}\" path=\"{7}\" details=\"{8}\"{9}",
                    DateTime.Now,
                    level,
                    category,
                    action,
                    hadZone ? "true" : "false",
                    extension ?? string.Empty,
                    folderName ?? string.Empty,
                    path ?? string.Empty,
                    details.Replace("\"", "'"),
                    Environment.NewLine);

                lock (syncRoot)
                {
                    File.AppendAllText(logPath, line, Encoding.UTF8);
                }
            }
            catch
            {
                // Logging must never break the watcher.
            }
        }

        public void Dispose()
        {
        }
    }
}
