param(
    [string]$Path = '.',
    [switch]$Recurse
)

$ErrorActionPreference = 'Stop'

$resolvedPath = Resolve-Path -LiteralPath $Path
$contentExtensions = @(
    '.md', '.markdown', '.mdown', '.mkdn', '.mdwn', '.mdtxt', '.mdtext',
    '.svg', '.png', '.jpg', '.jpeg', '.gif', '.webp'
)

$files = Get-ChildItem -LiteralPath $resolvedPath -File -Recurse:$Recurse |
    Where-Object { $contentExtensions -contains $_.Extension.ToLowerInvariant() }

$processed = 0
$unblocked = 0

foreach ($file in $files) {
    $processed++

    $hasZoneIdentifier = Get-Item -LiteralPath $file.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
    if ($null -eq $hasZoneIdentifier) {
        continue
    }

    Remove-Item -LiteralPath $file.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
    $unblocked++
    Write-Host "Unblocked $($file.FullName)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Scan complete." -ForegroundColor Cyan
Write-Host "Files inspected: $processed"
Write-Host "Files unblocked: $unblocked" -ForegroundColor Green
