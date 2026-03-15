param(
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..')
$templateRoot = Join-Path $projectRoot 'content\mind-os-template'
$destinationRoot = [System.IO.Path]::GetFullPath($Destination)

if (!(Test-Path $templateRoot)) {
    throw "Template root not found: $templateRoot"
}

if ((Test-Path $destinationRoot) -and !$Force) {
    $existingEntries = Get-ChildItem -LiteralPath $destinationRoot -Force -ErrorAction SilentlyContinue
    if ($existingEntries.Count -gt 0) {
        throw "Destination already exists and is not empty: $destinationRoot. Use -Force if you want to merge."
    }
}

[System.IO.Directory]::CreateDirectory($destinationRoot) | Out-Null

Get-ChildItem -LiteralPath $templateRoot -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart('\')
    $targetDirectory = Join-Path $destinationRoot $relativePath
    [System.IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
}

$copiedFiles = 0

Get-ChildItem -LiteralPath $templateRoot -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart('\')
    $targetFile = Join-Path $destinationRoot $relativePath
    $targetParent = Split-Path -Parent $targetFile

    if (!(Test-Path $targetParent)) {
        [System.IO.Directory]::CreateDirectory($targetParent) | Out-Null
    }

    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    [System.IO.File]::WriteAllBytes($targetFile, $bytes)
    $copiedFiles++
}

Write-Host ""
Write-Host "Mind OS workspace created." -ForegroundColor Cyan
Write-Host "Destination: $destinationRoot"
Write-Host "Files copied: $copiedFiles" -ForegroundColor Green
