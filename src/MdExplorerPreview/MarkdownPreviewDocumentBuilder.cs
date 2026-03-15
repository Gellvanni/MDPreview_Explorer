using Markdig;
using System;
using System.IO;
using System.Reflection;
using System.Text;

namespace MdExplorerPreview
{
    public sealed class MarkdownPreviewDocument
    {
        public MarkdownPreviewDocument(string html, string sourcePath, PreviewTheme theme)
        {
            Html = html;
            SourcePath = sourcePath;
            ThemeId = theme.Id;
            ThemeDisplayName = theme.DisplayName;
        }

        public string Html { get; }

        public string SourcePath { get; }

        public string ThemeId { get; }

        public string ThemeDisplayName { get; }
    }

    public static class MarkdownPreviewDocumentBuilder
    {
        private const long MaxPreviewBytes = 2 * 1024 * 1024;
        private const string BaseCssResourceName = "MdExplorerPreview.Resources.preview-base.css";

        public static MarkdownPreviewDocument BuildLoadingDocument(string? filePath)
        {
            var theme = PreviewThemeSettings.LoadTheme();
            var sourcePath = filePath ?? string.Empty;
            var fileName = string.IsNullOrWhiteSpace(filePath) ? "arquivo selecionado" : Path.GetFileName(filePath);
            var baseDirectory = string.IsNullOrWhiteSpace(filePath) ? null : Path.GetDirectoryName(filePath);
            var body = $@"
<div class='preview-loading'>
  <div class='preview-loading-kicker'>Markdown Preview</div>
  <h1>Carregando visualizacao</h1>
  <p class='muted'>Preparando o documento <code>{Encode(fileName)}</code> em modo somente leitura.</p>
  <p class='muted'>Tema ativo: {Encode(theme.DisplayName)}</p>
</div>";

            return new MarkdownPreviewDocument(
                WrapHtml(body, baseDirectory, theme),
                sourcePath,
                theme);
        }

        public static MarkdownPreviewDocument BuildDocument(string? filePath)
        {
            var theme = PreviewThemeSettings.LoadTheme();
            var sourcePath = filePath ?? string.Empty;

            if (string.IsNullOrWhiteSpace(filePath))
            {
                return new MarkdownPreviewDocument(
                    WrapHtml("<p class='muted'>Nenhum arquivo selecionado para pre-visualizacao.</p>", null, theme),
                    sourcePath,
                    theme);
            }

            if (!File.Exists(filePath))
            {
                return new MarkdownPreviewDocument(
                    WrapHtml($"<p class='error'>Arquivo nao encontrado: <code>{Encode(filePath)}</code></p>", null, theme),
                    sourcePath,
                    theme);
            }

            try
            {
                var resolvedFilePath = filePath!;
                var fileInfo = new FileInfo(resolvedFilePath);
                if (fileInfo.Length > MaxPreviewBytes)
                {
                    var message = $@"
<h1>Arquivo grande demais para preview renderizado</h1>
<p class='muted'>O arquivo tem {fileInfo.Length:N0} bytes. O limite seguro configurado para o Preview Pane e {MaxPreviewBytes:N0} bytes.</p>
<h2>Inicio do arquivo</h2>
<pre>{Encode(ReadFileText(resolvedFilePath, 64 * 1024))}</pre>";

                    return new MarkdownPreviewDocument(
                        WrapHtml(message, Path.GetDirectoryName(resolvedFilePath), theme),
                        resolvedFilePath,
                        theme);
                }

                var markdown = ReadFileText(resolvedFilePath);
                var pipeline = new MarkdownPipelineBuilder()
                    .UseAdvancedExtensions()
                    .DisableHtml()
                    .Build();

                var htmlBody = Markdown.ToHtml(markdown, pipeline);
                return new MarkdownPreviewDocument(
                    WrapHtml(htmlBody, Path.GetDirectoryName(resolvedFilePath), theme),
                    resolvedFilePath,
                    theme);
            }
            catch (Exception ex)
            {
                var fallbackSourcePath = sourcePath;
                var fallback = $@"
<h1>Falha ao renderizar Markdown</h1>
<p class='error'>{Encode(ex.Message)}</p>
<h2>Texto bruto</h2>
<pre>{Encode(SafeReadRaw(fallbackSourcePath))}</pre>";

                return new MarkdownPreviewDocument(
                    WrapHtml(fallback, Path.GetDirectoryName(fallbackSourcePath), theme),
                    fallbackSourcePath,
                    theme);
            }
        }

        private static string ReadFileText(string path, int? maxCharacters = null)
        {
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true))
            {
                if (!maxCharacters.HasValue)
                {
                    return reader.ReadToEnd();
                }

                var buffer = new char[maxCharacters.Value];
                var read = reader.ReadBlock(buffer, 0, buffer.Length);
                return new string(buffer, 0, read);
            }
        }

        private static string SafeReadRaw(string path)
        {
            try
            {
                return ReadFileText(path);
            }
            catch
            {
                return "Nao foi possivel ler o conteudo bruto do arquivo.";
            }
        }

        private static string WrapHtml(string bodyHtml, string? baseDirectory, PreviewTheme theme)
        {
            var baseCss = LoadEmbeddedText(BaseCssResourceName);
            var themeCss = LoadEmbeddedText(theme.CssResourceName);
            var baseTag = string.Empty;

            if (!string.IsNullOrWhiteSpace(baseDirectory))
            {
                var uri = new Uri(baseDirectory + Path.DirectorySeparatorChar);
                baseTag = $"<base href=\"{uri.AbsoluteUri}\" />";
            }

            return $@"<!DOCTYPE html>
<html>
<head>
<meta http-equiv='X-UA-Compatible' content='IE=edge' />
<meta charset='utf-8' />
<meta name='color-scheme' content='{theme.ColorScheme}' />
{baseTag}
<style>{baseCss}</style>
<style>{themeCss}</style>
</head>
<body class='preview-host {theme.BodyClass}'>
<div class='markdown-body'>
{bodyHtml}
</div>
</body>
</html>";
        }

        private static string LoadEmbeddedText(string resourceName)
        {
            var assembly = Assembly.GetExecutingAssembly();
            using (var stream = assembly.GetManifestResourceStream(resourceName))
            {
                if (stream == null)
                {
                    return "html,body{margin:0;padding:0;background:#11161c;color:#d9e0e8;font-family:Segoe UI,sans-serif;}body{padding:24px;}pre{white-space:pre-wrap;background:#19202a;padding:12px;border-radius:8px;}";
                }

                using (var reader = new StreamReader(stream))
                {
                    return reader.ReadToEnd();
                }
            }
        }

        private static string Encode(string? value)
        {
            return System.Net.WebUtility.HtmlEncode(value ?? string.Empty);
        }
    }
}
