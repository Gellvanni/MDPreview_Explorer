$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    Write-MarkdownPreviewSection 'Markdown Preview Auto-Unblocker Stop'
    Stop-MarkdownPreviewAutoUnblockerProcess
    Write-MarkdownPreviewSuccess 'Auto-unblocker process stopped.'
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Auto-unblocker stop failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script.'
    $host.SetShouldExit(1)
    return
}
