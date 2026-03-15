param(
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..')
$sourceRoot = Join-Path $projectRoot 'content\validation-suite'
$destinationRoot = [System.IO.Path]::GetFullPath($Destination)

if (!(Test-Path $sourceRoot)) {
    throw "Validation suite not found: $sourceRoot"
}

if ((Test-Path $destinationRoot) -and !$Force) {
    $existingEntries = Get-ChildItem -LiteralPath $destinationRoot -Force -ErrorAction SilentlyContinue
    if ($existingEntries.Count -gt 0) {
        throw "Destination already exists and is not empty: $destinationRoot. Use -Force if you want to overwrite."
    }
}

[System.IO.Directory]::CreateDirectory($destinationRoot) | Out-Null

Get-ChildItem -LiteralPath $sourceRoot -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
    [System.IO.Directory]::CreateDirectory((Join-Path $destinationRoot $relativePath)) | Out-Null
}

Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $targetFile = Join-Path $destinationRoot $relativePath
    [System.IO.File]::WriteAllBytes($targetFile, [System.IO.File]::ReadAllBytes($_.FullName))
}

$blockedFile = Join-Path $destinationRoot '06-zone-identifier.md'
$unblockedFile = Join-Path $destinationRoot '07-unblocked.md'
$localCopyDirectory = Join-Path $destinationRoot 'local-copy'
$localCopyFile = Join-Path $localCopyDirectory '01-simple-local-copy.md'

[System.IO.Directory]::CreateDirectory($localCopyDirectory) | Out-Null
[System.IO.File]::WriteAllBytes($localCopyFile, [System.IO.File]::ReadAllBytes((Join-Path $destinationRoot '01-simple.md')))

Set-Content -LiteralPath $blockedFile -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3"
Remove-Item -LiteralPath $unblockedFile -Stream Zone.Identifier -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $localCopyFile -Stream Zone.Identifier -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Validation workspace prepared." -ForegroundColor Cyan
Write-Host "Destination: $destinationRoot"
Write-Host "Blocked file: $blockedFile"
Write-Host "Unblocked file: $unblockedFile"
Write-Host "Local copy file: $localCopyFile" -ForegroundColor Green
