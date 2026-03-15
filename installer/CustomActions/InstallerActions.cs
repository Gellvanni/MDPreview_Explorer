using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using WixToolset.Dtf.WindowsInstaller;

namespace MdExplorerPreview.Setup.CustomActions
{
    public static class InstallerActions
    {
        private const string HandlerClsid = "{B3F3E9C1-4A4E-48A2-8F54-BC4C10E5E8A1}";
        private const string HandlerProgId = "MdExplorerPreview.MarkdownPreviewHandler";
        private const string PreviewHandlerKey = "{8895b1c6-b41f-4c1c-a562-0d564250836f}";
        private const string PreviewHostAppId64 = "{6D2B5079-2F0B-48DD-AB7F-97CEC514D30B}";
        private static readonly string[] MarkdownExtensions =
        {
            ".md",
            ".markdown",
            ".mdown",
            ".mkdn",
            ".mdwn",
            ".mdtxt",
            ".mdtext"
        };

        [CustomAction]
        public static ActionResult StopRunningProcesses(Session session)
        {
            return Execute(session, "StopRunningProcesses", () =>
            {
                StopProcessByName("MdExplorerPreview.AutoUnblocker", session, failIfCannotStop: true);
                StopProcessByName("prevhost", session, failIfCannotStop: false);
            });
        }

        [CustomAction]
        public static ActionResult RemoveLegacyCurrentUserArtifacts(Session session)
        {
            return Execute(session, "RemoveLegacyCurrentUserArtifacts", () =>
            {
                var startupShortcutPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Startup),
                    "MdExplorerPreview Auto-Unblocker.lnk");
                TryDeleteFile(startupShortcutPath, session, "legacy-startup-shortcut");

                var legacyAutoUnblockerDirectory = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "MdExplorerPreview",
                    "AutoUnblocker");
                TryDeleteDirectory(legacyAutoUnblockerDirectory, session, "legacy-auto-unblocker-directory");
            });
        }

        [CustomAction]
        public static ActionResult RegisterPreviewHandler(Session session)
        {
            return Execute(session, "RegisterPreviewHandler", () =>
            {
                var installFolder = session.CustomActionData["InstallFolder"];
                var handlerPath = Path.Combine(installFolder, "MdExplorerPreview.dll");
                if (!File.Exists(handlerPath))
                {
                    throw new FileNotFoundException("Handler DLL not found.", handlerPath);
                }

                var regAsmPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                    "Microsoft.NET",
                    "Framework64",
                    "v4.0.30319",
                    "RegAsm.exe");

                if (!File.Exists(regAsmPath))
                {
                    throw new FileNotFoundException("RegAsm was not found.", regAsmPath);
                }

                RunProcess(
                    session,
                    regAsmPath,
                    $"\"{handlerPath}\" /codebase",
                    "RegAsm register");

                using (var classesRoot = RegistryKey.OpenBaseKey(RegistryHive.ClassesRoot, RegistryView.Registry64))
                using (var localMachine = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64))
                {
                    SetRegistryValue(classesRoot, $@"CLSID\{HandlerClsid}", "AppID", PreviewHostAppId64, RegistryValueKind.String);
                    SetRegistryValue(localMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers", HandlerClsid, "Markdown Explorer Preview", RegistryValueKind.String);
                    SetRegistryValue(localMachine, @"SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION", "prevhost.exe", 11001, RegistryValueKind.DWord);

                    foreach (var extension in MarkdownExtensions)
                    {
                        SetDefaultRegistryValue(classesRoot, $@"SystemFileAssociations\{extension}\ShellEx\{PreviewHandlerKey}", HandlerClsid);

                        var progId = classesRoot.OpenSubKey(extension)?.GetValue(string.Empty) as string;
                        if (!string.IsNullOrWhiteSpace(progId))
                        {
                            SetDefaultRegistryValue(classesRoot, $@"{progId}\ShellEx\{PreviewHandlerKey}", HandlerClsid);
                        }
                    }
                }
            });
        }

        [CustomAction]
        public static ActionResult UnregisterPreviewHandler(Session session)
        {
            return Execute(session, "UnregisterPreviewHandler", () =>
            {
                var installFolder = session.CustomActionData["InstallFolder"];
                var handlerPath = Path.Combine(installFolder, "MdExplorerPreview.dll");
                var regAsmPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                    "Microsoft.NET",
                    "Framework64",
                    "v4.0.30319",
                    "RegAsm.exe");

                using (var classesRoot = RegistryKey.OpenBaseKey(RegistryHive.ClassesRoot, RegistryView.Registry64))
                using (var localMachine = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64))
                {
                    foreach (var extension in MarkdownExtensions)
                    {
                        RemoveShellExtensionIfOwned(classesRoot, $@"SystemFileAssociations\{extension}\ShellEx\{PreviewHandlerKey}");

                        var progId = classesRoot.OpenSubKey(extension)?.GetValue(string.Empty) as string;
                        if (!string.IsNullOrWhiteSpace(progId))
                        {
                            RemoveShellExtensionIfOwned(classesRoot, $@"{progId}\ShellEx\{PreviewHandlerKey}");
                        }
                    }

                    RemoveRegistryValue(localMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers", HandlerClsid);
                    RemoveRegistryValue(localMachine, @"SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION", "prevhost.exe");
                }

                if (File.Exists(regAsmPath) && File.Exists(handlerPath))
                {
                    RunProcess(
                        session,
                        regAsmPath,
                        $"\"{handlerPath}\" /u",
                        "RegAsm unregister");
                }

                using (var classesRoot = RegistryKey.OpenBaseKey(RegistryHive.ClassesRoot, RegistryView.Registry64))
                {
                    DeleteSubKeyTree(classesRoot, $@"CLSID\{HandlerClsid}");
                    DeleteSubKeyTree(classesRoot, HandlerProgId);
                }
            });
        }

        [CustomAction]
        public static ActionResult LaunchAutoUnblocker(Session session)
        {
            return Execute(session, "LaunchAutoUnblocker", () =>
            {
                var installFolder = session["INSTALLFOLDER"];
                if (string.IsNullOrWhiteSpace(installFolder))
                {
                    throw new InvalidOperationException("INSTALLFOLDER was not available.");
                }

                var exePath = Path.Combine(installFolder, "MdExplorerPreview.AutoUnblocker.exe");
                if (!File.Exists(exePath))
                {
                    throw new FileNotFoundException("Auto-unblocker executable was not found.", exePath);
                }

                using (Process.Start(new ProcessStartInfo
                {
                    FileName = exePath,
                    WorkingDirectory = installFolder,
                    UseShellExecute = false
                }))
                {
                }
            });
        }

        private static ActionResult Execute(Session session, string actionName, Action action)
        {
            session.Log($"[MdExplorerPreview.Setup] Starting {actionName}.");

            try
            {
                action();
                session.Log($"[MdExplorerPreview.Setup] {actionName} completed successfully.");
                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"[MdExplorerPreview.Setup] {actionName} failed: {ex}");
                return ActionResult.Failure;
            }
        }

        private static void StopProcessByName(string processName, Session session, bool failIfCannotStop)
        {
            var processes = Process.GetProcessesByName(processName);
            if (processes.Length == 0)
            {
                session.Log($"[MdExplorerPreview.Setup] No running process found for {processName}.");
                return;
            }

            foreach (var process in processes)
            {
                try
                {
                    session.Log($"[MdExplorerPreview.Setup] Stopping {process.ProcessName} ({process.Id}).");
                    process.Kill();
                    process.WaitForExit(8000);
                }
                catch (Exception ex)
                {
                    if (failIfCannotStop)
                    {
                        throw;
                    }

                    session.Log($"[MdExplorerPreview.Setup] Unable to stop optional process {process.ProcessName} ({process.Id}): {ex.Message}");
                }
                finally
                {
                    process.Dispose();
                }
            }

            var survivors = Process.GetProcessesByName(processName);
            try
            {
                if (survivors.Any())
                {
                    if (failIfCannotStop)
                    {
                        throw new InvalidOperationException($"Process {processName} is still running after the stop request.");
                    }

                    session.Log($"[MdExplorerPreview.Setup] Optional process {processName} is still running after the stop request.");
                }
            }
            finally
            {
                foreach (var survivor in survivors)
                {
                    survivor.Dispose();
                }
            }
        }

        private static void TryDeleteFile(string path, Session session, string label)
        {
            try
            {
                if (!File.Exists(path))
                {
                    session.Log($"[MdExplorerPreview.Setup] No {label} found at {path}.");
                    return;
                }

                File.Delete(path);
                session.Log($"[MdExplorerPreview.Setup] Removed {label}: {path}");
            }
            catch (Exception ex)
            {
                session.Log($"[MdExplorerPreview.Setup] Failed to remove {label}: {path}. {ex.Message}");
            }
        }

        private static void TryDeleteDirectory(string path, Session session, string label)
        {
            try
            {
                if (!Directory.Exists(path))
                {
                    session.Log($"[MdExplorerPreview.Setup] No {label} found at {path}.");
                    return;
                }

                Directory.Delete(path, recursive: true);
                session.Log($"[MdExplorerPreview.Setup] Removed {label}: {path}");
            }
            catch (Exception ex)
            {
                session.Log($"[MdExplorerPreview.Setup] Failed to remove {label}: {path}. {ex.Message}");
            }
        }

        private static void RunProcess(Session session, string fileName, string arguments, string label)
        {
            session.Log($"[MdExplorerPreview.Setup] {label}: {fileName} {arguments}");

            using (var process = new Process())
            {
                process.StartInfo = new ProcessStartInfo
                {
                    FileName = fileName,
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                process.Start();
                var standardOutput = process.StandardOutput.ReadToEnd();
                var standardError = process.StandardError.ReadToEnd();
                process.WaitForExit();

                if (!string.IsNullOrWhiteSpace(standardOutput))
                {
                    session.Log($"[MdExplorerPreview.Setup] {label} stdout: {standardOutput}");
                }

                if (!string.IsNullOrWhiteSpace(standardError))
                {
                    session.Log($"[MdExplorerPreview.Setup] {label} stderr: {standardError}");
                }

                if (process.ExitCode != 0)
                {
                    throw new InvalidOperationException($"{label} failed with exit code {process.ExitCode}.");
                }
            }
        }

        private static void SetRegistryValue(RegistryKey root, string path, string name, object value, RegistryValueKind kind)
        {
            using (var key = root.CreateSubKey(path))
            {
                key?.SetValue(name, value, kind);
            }
        }

        private static void SetDefaultRegistryValue(RegistryKey root, string path, string value)
        {
            using (var key = root.CreateSubKey(path))
            {
                key?.SetValue(string.Empty, value, RegistryValueKind.String);
            }
        }

        private static void RemoveRegistryValue(RegistryKey root, string path, string name)
        {
            using (var key = root.OpenSubKey(path, writable: true))
            {
                key?.DeleteValue(name, false);
            }
        }

        private static void RemoveShellExtensionIfOwned(RegistryKey root, string path)
        {
            using (var key = root.OpenSubKey(path))
            {
                if (key == null)
                {
                    return;
                }

                var currentValue = key.GetValue(string.Empty) as string;
                if (!string.Equals(currentValue, HandlerClsid, StringComparison.OrdinalIgnoreCase))
                {
                    return;
                }
            }

            DeleteSubKeyTree(root, path);
        }

        private static void DeleteSubKeyTree(RegistryKey root, string path)
        {
            try
            {
                root.DeleteSubKeyTree(path, false);
            }
            catch (ArgumentException)
            {
            }
            catch (IOException)
            {
            }
        }
    }
}
