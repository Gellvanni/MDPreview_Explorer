using System;
using Microsoft.Win32;

namespace MdExplorerPreview
{
    public sealed class PreviewTheme
    {
        public PreviewTheme(string id, string displayName, string bodyClass, string cssResourceName, string colorScheme)
        {
            Id = id;
            DisplayName = displayName;
            BodyClass = bodyClass;
            CssResourceName = cssResourceName;
            ColorScheme = colorScheme;
        }

        public string Id { get; }

        public string DisplayName { get; }

        public string BodyClass { get; }

        public string CssResourceName { get; }

        public string ColorScheme { get; }
    }

    public static class PreviewThemeCatalog
    {
        private static readonly PreviewTheme DarkTheme = new PreviewTheme(
            "windows-dark",
            "Windows Dark",
            "theme-windows-dark",
            "MdExplorerPreview.Resources.preview-theme-dark.css",
            "dark");

        private static readonly PreviewTheme LightTheme = new PreviewTheme(
            "windows-light",
            "Windows Light",
            "theme-windows-light",
            "MdExplorerPreview.Resources.preview-theme-light.css",
            "light");

        public static PreviewTheme ResolveForSystemTheme()
        {
            return IsWindowsLightThemeEnabled()
                ? LightTheme
                : DarkTheme;
        }

        private static bool IsWindowsLightThemeEnabled()
        {
            try
            {
                using (var personalizeKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"))
                {
                    var value = personalizeKey?.GetValue("AppsUseLightTheme");
                    if (value is int intValue)
                    {
                        return intValue != 0;
                    }

                    if (value is byte[] rawBytes && rawBytes.Length > 0)
                    {
                        return rawBytes[0] != 0;
                    }
                }
            }
            catch
            {
                // Theme detection must never break preview rendering.
            }

            return false;
        }
    }

    internal static class PreviewThemeSettings
    {
        public static PreviewTheme LoadTheme()
        {
            return PreviewThemeCatalog.ResolveForSystemTheme();
        }
    }
}
