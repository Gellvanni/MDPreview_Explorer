param(
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    Write-MarkdownPreviewSection 'Markdown Preview Auto-Unblocker Start'
    Start-MarkdownPreviewAutoUnblockerProcess -Restart:$Restart
    Write-MarkdownPreviewSuccess 'Auto-unblocker is running.'
    Write-MarkdownPreviewInfo "Settings file: $(Get-MarkdownPreviewAutoUnblockerSettingsPath)"
    Write-MarkdownPreviewInfo "Log file: $(Get-MarkdownPreviewAutoUnblockerLogPath)"
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Auto-unblocker start failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script.'
    $host.SetShouldExit(1)
    return
}
