$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    $settingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
    if (!(Test-Path $settingsPath)) {
        throw "Auto-unblocker settings file not found: $settingsPath"
    }

    Start-Process notepad.exe $settingsPath | Out-Null
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Open settings failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: install the auto-unblocker first or restore the settings file.'
    $host.SetShouldExit(1)
    return
}
