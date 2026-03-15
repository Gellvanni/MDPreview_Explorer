using Markdig;
using SharpShell.SharpPreviewHandler;
using System;
using System.IO;
using System.Windows.Forms;
using System.Diagnostics;

namespace MdExplorerPreview
{
    public partial class MarkdownPreviewControl : PreviewHandlerControl
    {
        private static readonly string LogDirectory = Path.Combine(GetWritableAppDataRoot(), "MdExplorerPreview");
        private static readonly string LogPath = Path.Combine(LogDirectory, "preview.log");

        private readonly string? filePath;
        private bool initialDocumentLoaded;
        private bool renderStarted;

        public MarkdownPreviewControl(string? filePath)
        {
            this.filePath = filePath;
            InitializeComponent();

            HandleCreated += OnHandleCreated;
            webBrowser.Navigating += WebBrowserOnNavigating;
            webBrowser.DocumentCompleted += WebBrowserOnDocumentCompleted;

            Log($"Control created. FilePath='{filePath ?? "<null>"}'");
        }

        private void OnHandleCreated(object? sender, EventArgs e)
        {
            if (renderStarted)
            {
                return;
            }

            renderStarted = true;
            LoadInitialDocumentShell();
            BeginInvoke((Action)Render);
        }

        private void Render()
        {
            var sourcePath = filePath ?? string.Empty;

            if (!File.Exists(sourcePath))
            {
                Log($"Render fallback: file not found '{sourcePath}'.");
                webBrowser.DocumentText = MarkdownPreviewDocumentBuilder.BuildDocument(sourcePath).Html;
                return;
            }

            try
            {
                Log($"Render started for '{sourcePath}'.");
                var document = MarkdownPreviewDocumentBuilder.BuildDocument(sourcePath);
                Log($"Render HTML generated. Theme='{document.ThemeId}'. Length={document.Html.Length} chars.");
                webBrowser.DocumentText = document.Html;
            }
            catch (Exception ex)
            {
                Log($"Render exception: {ex}");
                throw;
            }
        }

        private void WebBrowserOnDocumentCompleted(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            var bodyLength = webBrowser.Document?.Body?.InnerHtml?.Length ?? 0;
            Log($"DocumentCompleted. Url='{e.Url}'. BodyLength={bodyLength}.");
        }

        private void WebBrowserOnNavigating(object sender, WebBrowserNavigatingEventArgs e)
        {
            Log($"Navigating. Url='{e.Url}'. InitialLoaded={initialDocumentLoaded}.");

            // Let the very first internal document load happen. After that, cancel navigation
            // so the preview pane doesn't become a browser for external links.
            if (!initialDocumentLoaded && (e.Url == null || e.Url.AbsoluteUri == "about:blank" || e.Url.Scheme == "file"))
            {
                initialDocumentLoaded = true;
                return;
            }

            // Keep the preview read-only and non-navigational.
            if (e.Url != null && e.Url.Scheme != "about")
            {
                e.Cancel = true;
            }
        }

        private void LoadInitialDocumentShell()
        {
            try
            {
                webBrowser.DocumentText = MarkdownPreviewDocumentBuilder.BuildLoadingDocument(filePath).Html;
            }
            catch (Exception ex)
            {
                Log($"Loading shell exception: {ex}");
            }
        }

        private static void Log(string message)
        {
            try
            {
                Directory.CreateDirectory(LogDirectory);
                File.AppendAllText(
                    LogPath,
                    $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}] pid={Process.GetCurrentProcess().Id} {message}{Environment.NewLine}");
            }
            catch
            {
                // Logging must never interfere with preview rendering.
            }
        }

        private static string GetWritableAppDataRoot()
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
