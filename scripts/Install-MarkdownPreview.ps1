param(
    [ValidateSet('Auto', 'Always', 'Never')]
    [string]$BuildMode = 'Auto',
    [switch]$SkipPackageUnblock,
    [switch]$SkipExplorerRestart,
    [switch]$SkipValidation,
    [switch]$SkipAutoUnblocker
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    Write-MarkdownPreviewSection 'Markdown Preview Install'
    Assert-MarkdownPreviewAdministrator

    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    $sampleFile = Get-MarkdownPreviewPrimaryValidationFile -ProjectRoot $projectRoot
    Write-MarkdownPreviewInfo "Project root: $projectRoot"

    if (-not $SkipPackageUnblock) {
        Write-MarkdownPreviewInfo 'Removing Zone.Identifier from the package when present.'
        $unblockResult = Unblock-MarkdownPreviewPackage -ProjectRoot $projectRoot
        Write-MarkdownPreviewSuccess "Package scan complete. Files inspected: $($unblockResult.FilesInspected). Files unblocked: $($unblockResult.FilesUnblocked)."
    } else {
        Write-MarkdownPreviewWarning 'Package unblock skipped by caller.'
    }

    $dllPath = Resolve-MarkdownPreviewDll -ProjectRoot $projectRoot -BuildMode $BuildMode
    Write-MarkdownPreviewSuccess "Using DLL: $dllPath"

    Write-MarkdownPreviewInfo 'Registering the preview handler.'
    & (Join-Path $PSScriptRoot 'Register-MarkdownPreviewHandler.ps1') -Configuration Release -Platform x64

    if (-not $SkipAutoUnblocker) {
        Write-MarkdownPreviewInfo 'Installing the trusted-folder auto-unblocker.'
        $autoUnblocker = Install-MarkdownPreviewAutoUnblocker -ProjectRoot $projectRoot -BuildMode $BuildMode
        Write-MarkdownPreviewSuccess "Auto-unblocker executable: $($autoUnblocker.ExecutablePath)"
        Write-MarkdownPreviewSuccess "Auto-unblocker settings: $($autoUnblocker.SettingsPath)"
        Write-MarkdownPreviewSuccess "Auto-unblocker startup shortcut: $($autoUnblocker.ShortcutPath)"
    } else {
        Write-MarkdownPreviewWarning 'Auto-unblocker installation skipped by caller.'
    }

    if (-not $SkipExplorerRestart) {
        Restart-MarkdownPreviewExplorer
    } else {
        Write-MarkdownPreviewWarning 'Explorer restart skipped by caller.'
    }

    if (-not $SkipValidation) {
        $validation = Test-MarkdownPreviewInstalled -ProjectRoot $projectRoot
        Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-install validation'
        if (-not $validation.IsValid) {
            throw 'Post-install validation failed. Review the warnings above before using the handler.'
        }

        if (-not $SkipAutoUnblocker) {
            $autoUnblockerValidation = Test-MarkdownPreviewAutoUnblockerInstalled
            Show-MarkdownPreviewValidation -Validation $autoUnblockerValidation -Title 'Auto-unblocker validation'
            if (-not $autoUnblockerValidation.IsValid) {
                throw 'Auto-unblocker validation failed. Review the warnings above before using trusted-folder auto-unblock.'
            }
        }
    } else {
        Write-MarkdownPreviewWarning 'Post-install validation skipped by caller.'
    }

    Write-MarkdownPreviewSection 'Install complete'
    Write-MarkdownPreviewSuccess 'Markdown Preview is installed for Release x64.'
    Write-MarkdownPreviewInfo "Open Explorer and select: $sampleFile"
    Write-MarkdownPreviewInfo 'If the file came from the internet, Windows may still show a security warning until the file or zip is unblocked.'
    if (-not $SkipAutoUnblocker) {
        Write-MarkdownPreviewInfo "Auto-unblocker settings file: $(Get-MarkdownPreviewAutoUnblockerSettingsPath)"
        Write-MarkdownPreviewInfo "Auto-unblocker log file: $(Get-MarkdownPreviewAutoUnblockerLogPath)"
    }
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Install failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script from an elevated PowerShell session.'
    $host.SetShouldExit(1)
    return
}
