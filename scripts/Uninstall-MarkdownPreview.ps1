param(
    [ValidateSet('Auto', 'Always', 'Never')]
    [string]$BuildMode = 'Auto',
    [switch]$SkipPackageUnblock,
    [switch]$SkipExplorerRestart,
    [switch]$SkipValidation,
    [switch]$SkipAutoUnblocker,
    [switch]$RemoveAutoUnblockerData
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    Write-MarkdownPreviewSection 'Markdown Preview Uninstall'
    Assert-MarkdownPreviewAdministrator

    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    Write-MarkdownPreviewInfo "Project root: $projectRoot"

    if (-not $SkipPackageUnblock) {
        Write-MarkdownPreviewInfo 'Removing Zone.Identifier from the package when present.'
        $unblockResult = Unblock-MarkdownPreviewPackage -ProjectRoot $projectRoot
        Write-MarkdownPreviewSuccess "Package scan complete. Files inspected: $($unblockResult.FilesInspected). Files unblocked: $($unblockResult.FilesUnblocked)."
    } else {
        Write-MarkdownPreviewWarning 'Package unblock skipped by caller.'
    }

    try {
        $dllPath = Resolve-MarkdownPreviewDll -ProjectRoot $projectRoot -BuildMode $BuildMode
        Write-MarkdownPreviewSuccess "Using DLL: $dllPath"
    } catch {
        Write-MarkdownPreviewWarning "DLL resolution skipped. Continuing with registry cleanup only. Reason: $($_.Exception.Message)"
    }

    Write-MarkdownPreviewInfo 'Removing the preview handler registration.'
    & (Join-Path $PSScriptRoot 'Unregister-MarkdownPreviewHandler.ps1') -Configuration Release -Platform x64

    if (-not $SkipAutoUnblocker) {
        Write-MarkdownPreviewInfo 'Removing the trusted-folder auto-unblocker.'
        Uninstall-MarkdownPreviewAutoUnblocker -RemoveData:$RemoveAutoUnblockerData
    } else {
        Write-MarkdownPreviewWarning 'Auto-unblocker removal skipped by caller.'
    }

    if (-not $SkipExplorerRestart) {
        Restart-MarkdownPreviewExplorer
    } else {
        Write-MarkdownPreviewWarning 'Explorer restart skipped by caller.'
    }

    if (-not $SkipValidation) {
        $validation = Test-MarkdownPreviewUninstalled -ProjectRoot $projectRoot
        Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-uninstall validation'
        if (-not $validation.IsValid) {
            throw 'Post-uninstall validation failed. Review the warnings above before considering the removal complete.'
        }

        if (-not $SkipAutoUnblocker) {
            $autoUnblockerValidation = Test-MarkdownPreviewAutoUnblockerUninstalled
            Show-MarkdownPreviewValidation -Validation $autoUnblockerValidation -Title 'Auto-unblocker removal validation'
            if (-not $autoUnblockerValidation.IsValid) {
                throw 'Auto-unblocker removal validation failed. Review the warnings above before considering the removal complete.'
            }
        }
    } else {
        Write-MarkdownPreviewWarning 'Post-uninstall validation skipped by caller.'
    }

    Write-MarkdownPreviewSection 'Uninstall complete'
    Write-MarkdownPreviewSuccess 'Markdown Preview was removed from the Explorer Preview Pane configuration.'
    Write-MarkdownPreviewInfo 'If preview still appears in a stale Explorer window, sign out and sign back in to clear shell caches.'
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Uninstall failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script from an elevated PowerShell session.'
    $host.SetShouldExit(1)
    return
}
