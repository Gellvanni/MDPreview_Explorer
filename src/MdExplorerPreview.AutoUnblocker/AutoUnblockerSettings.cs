using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace MdExplorerPreview.AutoUnblocker
{
    public sealed class AutoUnblockerSettings
    {
        [JsonProperty("autoUnblockEnabled")]
        public bool AutoUnblockEnabled { get; set; } = true;

        [JsonProperty("dryRun")]
        public bool DryRun { get; set; }

        [JsonProperty("logEnabled")]
        public bool LogEnabled { get; set; } = true;

        [JsonProperty("logPath")]
        public string LogPath { get; set; } = SettingsPaths.GetDefaultLogPath();

        [JsonProperty("scanOnStartup")]
        public bool ScanOnStartup { get; set; } = true;

        [JsonProperty("unblockZipOnArrival")]
        public bool UnblockZipOnArrival { get; set; }

        [JsonProperty("settleDelayMs")]
        public int SettleDelayMilliseconds { get; set; } = 700;

        [JsonProperty("retryDelayMs")]
        public int RetryDelayMilliseconds { get; set; } = 700;

        [JsonProperty("maxWaitMs")]
        public int MaxWaitMilliseconds { get; set; } = 20000;

        [JsonProperty("allowedExtensions")]
        public List<string> AllowedExtensions { get; set; } = CreateDefaultAllowedExtensions();

        [JsonProperty("watchFolders")]
        public List<TrustedFolderSettings> WatchFolders { get; set; } = CreateDefaultWatchFolders();

        public TimeSpan SettleDelay => TimeSpan.FromMilliseconds(Math.Max(SettleDelayMilliseconds, 150));

        public TimeSpan RetryDelay => TimeSpan.FromMilliseconds(Math.Max(RetryDelayMilliseconds, 250));

        public TimeSpan MaxWait => TimeSpan.FromMilliseconds(Math.Max(MaxWaitMilliseconds, 1000));

        public string ExpandedLogPath => SettingsPaths.ExpandPath(LogPath);

        public IReadOnlyCollection<string> AllowedExtensionsNormalized =>
            (AllowedExtensions ?? CreateDefaultAllowedExtensions())
            .Select(NormalizeExtension)
            .Where(extension => !string.IsNullOrWhiteSpace(extension))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        public IReadOnlyList<TrustedFolderSettings> EnabledWatchFolders =>
            (WatchFolders ?? CreateDefaultWatchFolders())
            .Where(folder => folder.Enabled && !string.IsNullOrWhiteSpace(folder.Path))
            .ToArray();

        public bool IsExtensionAllowed(string extension)
        {
            var normalizedExtension = NormalizeExtension(extension);
            return AllowedExtensionsNormalized.Contains(normalizedExtension, StringComparer.OrdinalIgnoreCase);
        }

        public void Normalize()
        {
            LogPath = string.IsNullOrWhiteSpace(LogPath) ? SettingsPaths.GetDefaultLogPath() : LogPath;
            SettleDelayMilliseconds = Math.Max(SettleDelayMilliseconds, 150);
            RetryDelayMilliseconds = Math.Max(RetryDelayMilliseconds, 250);
            MaxWaitMilliseconds = Math.Max(MaxWaitMilliseconds, 1000);
            AllowedExtensions = AllowedExtensionsNormalized.ToList();
            WatchFolders = (WatchFolders ?? CreateDefaultWatchFolders())
                .Where(folder => folder != null)
                .Select(folder =>
                {
                    folder.Normalize();
                    return folder;
                })
                .ToList();
        }

        public static AutoUnblockerSettings CreateDefault()
        {
            return new AutoUnblockerSettings();
        }

        private static List<string> CreateDefaultAllowedExtensions()
        {
            return new List<string>
            {
                ".md",
                ".markdown",
                ".mdown",
                ".mkdn",
                ".mdwn",
                ".txt",
                ".log",
                ".json",
                ".yaml",
                ".yml",
                ".ini",
                ".csv",
                ".xml",
                ".svg",
                ".png",
                ".jpg",
                ".jpeg",
                ".zip"
            };
        }

        private static List<TrustedFolderSettings> CreateDefaultWatchFolders()
        {
            return new List<TrustedFolderSettings>
            {
                new TrustedFolderSettings
                {
                    Name = "Downloads",
                    Path = @"%USERPROFILE%\Downloads",
                    Enabled = true,
                    Recursive = true
                },
                new TrustedFolderSettings
                {
                    Name = "CustomTrustedFolder",
                    Path = @"%USERPROFILE%\Documents\TrustedMarkdown",
                    Enabled = false,
                    Recursive = true
                }
            };
        }

        private static string NormalizeExtension(string? extension)
        {
            if (string.IsNullOrWhiteSpace(extension))
            {
                return string.Empty;
            }

            var trimmed = extension!.Trim();
            if (!trimmed.StartsWith(".", StringComparison.Ordinal))
            {
                trimmed = "." + trimmed;
            }

            return trimmed.ToLowerInvariant();
        }
    }

    public sealed class TrustedFolderSettings
    {
        [JsonProperty("name")]
        public string Name { get; set; } = "TrustedFolder";

        [JsonProperty("path")]
        public string Path { get; set; } = string.Empty;

        [JsonProperty("enabled")]
        public bool Enabled { get; set; }

        [JsonProperty("recursive")]
        public bool Recursive { get; set; } = true;

        [JsonIgnore]
        public string ExpandedPath => SettingsPaths.ExpandPath(Path);

        public void Normalize()
        {
            Name = string.IsNullOrWhiteSpace(Name) ? "TrustedFolder" : Name.Trim();
            Path = string.IsNullOrWhiteSpace(Path) ? string.Empty : Path.Trim();
        }
    }

    internal static class AutoUnblockerSettingsStore
    {
        public static AutoUnblockerSettings LoadOrCreate(string settingsPath)
        {
            var fullSettingsPath = Path.GetFullPath(settingsPath);
            var settingsDirectory = Path.GetDirectoryName(fullSettingsPath);
            if (!string.IsNullOrWhiteSpace(settingsDirectory))
            {
                Directory.CreateDirectory(settingsDirectory);
            }

            if (!File.Exists(fullSettingsPath))
            {
                var defaultSettings = AutoUnblockerSettings.CreateDefault();
                defaultSettings.Normalize();
                Save(fullSettingsPath, defaultSettings);
                return defaultSettings;
            }

            var json = File.ReadAllText(fullSettingsPath);
            var settings = Parse(json);
            settings.Normalize();
            return settings;
        }

        public static void Save(string settingsPath, AutoUnblockerSettings settings)
        {
            settings.Normalize();
            var json = JsonConvert.SerializeObject(settings, Formatting.Indented);
            File.WriteAllText(settingsPath, json);
        }

        private static AutoUnblockerSettings Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return AutoUnblockerSettings.CreateDefault();
            }

            var root = JsonConvert.DeserializeObject<JObject>(json);
            if (root == null)
            {
                return AutoUnblockerSettings.CreateDefault();
            }

            var settings = AutoUnblockerSettings.CreateDefault();
            settings.AutoUnblockEnabled = root.Value<bool?>("autoUnblockEnabled") ?? settings.AutoUnblockEnabled;
            settings.DryRun = root.Value<bool?>("dryRun") ?? settings.DryRun;
            settings.LogEnabled = root.Value<bool?>("logEnabled") ?? settings.LogEnabled;
            settings.LogPath = root.Value<string>("logPath") ?? settings.LogPath;
            settings.ScanOnStartup = root.Value<bool?>("scanOnStartup") ?? settings.ScanOnStartup;
            settings.UnblockZipOnArrival = root.Value<bool?>("unblockZipOnArrival") ?? settings.UnblockZipOnArrival;
            settings.SettleDelayMilliseconds = root.Value<int?>("settleDelayMs") ?? settings.SettleDelayMilliseconds;
            settings.RetryDelayMilliseconds = root.Value<int?>("retryDelayMs") ?? settings.RetryDelayMilliseconds;
            settings.MaxWaitMilliseconds = root.Value<int?>("maxWaitMs") ?? settings.MaxWaitMilliseconds;

            var allowedExtensionsToken = root["allowedExtensions"] as JArray;
            if (allowedExtensionsToken != null)
            {
                settings.AllowedExtensions = allowedExtensionsToken
                    .Values<string>()
                    .Where(extension => !string.IsNullOrWhiteSpace(extension))
                    .Select(extension => extension!)
                    .ToList();
            }

            var watchFoldersToken = root["watchFolders"] as JArray;
            if (watchFoldersToken != null)
            {
                settings.WatchFolders = watchFoldersToken
                    .OfType<JObject>()
                    .Select(ParseTrustedFolder)
                    .ToList();
            }

            return settings;
        }

        private static TrustedFolderSettings ParseTrustedFolder(JObject token)
        {
            return new TrustedFolderSettings
            {
                Name = token.Value<string>("name") ?? "TrustedFolder",
                Path = token.Value<string>("path") ?? string.Empty,
                Enabled = token.Value<bool?>("enabled") ?? false,
                Recursive = token.Value<bool?>("recursive") ?? true
            };
        }
    }

    internal static class SettingsPaths
    {
        public static string GetDefaultSettingsPath()
        {
            return Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "MdExplorerPreview",
                "settings.json");
        }

        public static string GetDefaultLogPath()
        {
            return Path.Combine(
                GetPreferredLogRoot(),
                "MdExplorerPreview",
                "auto-unblocker.log");
        }

        public static string ExpandPath(string rawPath)
        {
            return Path.GetFullPath(Environment.ExpandEnvironmentVariables(rawPath));
        }

        private static string GetPreferredLogRoot()
        {
            var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (!string.IsNullOrWhiteSpace(userProfile))
            {
                return Path.Combine(userProfile, "AppData", "LocalLow");
            }

            return Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        }
    }
}
