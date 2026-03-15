using System;
using System.Runtime.InteropServices;
using SharpShell.Attributes;
using SharpShell.SharpPreviewHandler;

namespace MdExplorerPreview
{
    [ComVisible(true)]
    [Guid("B3F3E9C1-4A4E-48A2-8F54-BC4C10E5E8A1")]
    [SharpShell.Attributes.DisplayName("Markdown Explorer Preview")]
    [PreviewHandler(DisableLowILProcessIsolation = false)]
    public class MarkdownPreviewHandler : SharpPreviewHandler
    {
        public const string HandlerClsid = "{B3F3E9C1-4A4E-48A2-8F54-BC4C10E5E8A1}";

        protected override PreviewHandlerControl DoPreview()
        {
            // SharpShell resolves the selected file path for us. We keep the control read-only.
            return new MarkdownPreviewControl(SelectedFilePath);
        }
    }
}
