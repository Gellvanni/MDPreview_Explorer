param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

try {
    Write-MarkdownPreviewSection 'Markdown Preview MSI Build'

    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    $installerProject = Join-Path $projectRoot 'installer\MdExplorerPreview.Setup.wixproj'
    if (!(Test-Path $installerProject)) {
        throw "Installer project not found: $installerProject"
    }

    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -eq $dotnet) {
        throw 'dotnet CLI was not found. Install the .NET SDK first.'
    }

    Write-MarkdownPreviewInfo "Building MSI from: $installerProject"
    & $dotnet.Source build $installerProject -c $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "MSI build failed with exit code $LASTEXITCODE."
    }

    $msiPath = Join-Path $projectRoot "installer\bin\x64\$Configuration\MdExplorerPreview.Setup.msi"
    if (!(Test-Path $msiPath)) {
        throw "MSI output was not found after build: $msiPath"
    }

    Write-MarkdownPreviewSuccess "MSI generated: $msiPath"
    Write-MarkdownPreviewInfo 'Use the MSI for clean install, upgrade and uninstall validation on Windows.'
    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'MSI build failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script.'
    $host.SetShouldExit(1)
    return
}
