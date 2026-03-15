param(
    [ValidateSet('Auto', 'Always', 'Never')]
    [string]$BuildMode = 'Auto',
    [string]$Destination,
    [switch]$OpenFolder
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

function Get-RenderingValidationFiles {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $mindOsRoot = Get-MarkdownPreviewMindOsTemplateRoot -ProjectRoot $ProjectRoot
    $validationRoot = Get-MarkdownPreviewValidationRoot -ProjectRoot $ProjectRoot

    return @(
        (Join-Path $mindOsRoot '00-constituicao\manifesto-operacional.md')
        (Join-Path $mindOsRoot '01-modos\auditoria.md')
        (Join-Path $mindOsRoot '02-projetos\template-projeto\prancheta-mestra.md')
        (Join-Path $validationRoot '03-table.md')
        (Join-Path $validationRoot '04-code-block.md')
        (Join-Path $validationRoot '05-local-image.md')
        Join-Path $validationRoot '08-syntax-guide.md'
    )
}

function Convert-ToRenderArtifactPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $projectRootPath = [System.IO.Path]::GetFullPath($ProjectRoot)
    $sourceFullPath = [System.IO.Path]::GetFullPath($SourcePath)
    $relativePath = $sourceFullPath.Substring($projectRootPath.Length).TrimStart('\')
    $relativeHtml = [System.IO.Path]::ChangeExtension($relativePath, '.html')
    return Join-Path $DestinationRoot $relativeHtml
}

try {
    Write-MarkdownPreviewSection 'Markdown Preview Rendering Validation'

    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    $destinationRoot = if ([string]::IsNullOrWhiteSpace($Destination)) {
        Join-Path $projectRoot 'artifacts\render-validation'
    } else {
        [System.IO.Path]::GetFullPath($Destination)
    }

    $files = Get-RenderingValidationFiles -ProjectRoot $projectRoot
    foreach ($file in $files) {
        if (-not (Test-Path $file)) {
            throw "Rendering validation source file not found: $file"
        }
    }

    $dllPath = Resolve-MarkdownPreviewDll -ProjectRoot $projectRoot -BuildMode $BuildMode
    Write-MarkdownPreviewSuccess "Using DLL: $dllPath"

    $assemblyDirectory = Split-Path -Parent $dllPath
    Get-ChildItem -LiteralPath $assemblyDirectory -Filter '*.dll' | ForEach-Object {
        [void][System.Reflection.Assembly]::LoadFrom($_.FullName)
    }

    $artifactCount = 0
    $appliedTheme = $null

    foreach ($file in $files) {
        $document = [MdExplorerPreview.MarkdownPreviewDocumentBuilder]::BuildDocument($file)
        if ([string]::IsNullOrWhiteSpace($document.Html)) {
            throw "HTML generation returned empty output for '$file'."
        }

        if ($null -eq $appliedTheme) {
            $appliedTheme = $document.ThemeDisplayName
        }

        $artifactPath = Convert-ToRenderArtifactPath -ProjectRoot $projectRoot -DestinationRoot $destinationRoot -SourcePath $file
        $artifactDirectory = Split-Path -Parent $artifactPath
        [System.IO.Directory]::CreateDirectory($artifactDirectory) | Out-Null
        [System.IO.File]::WriteAllText($artifactPath, $document.Html, [System.Text.Encoding]::UTF8)
        $artifactCount++
        Write-MarkdownPreviewSuccess "Generated -> $file"
    }

    Write-MarkdownPreviewSection 'Rendering validation complete'
    Write-MarkdownPreviewSuccess "Artifacts generated: $artifactCount"
    if ($null -ne $appliedTheme) {
        Write-MarkdownPreviewInfo "Windows theme detected by renderer: $appliedTheme"
    }
    Write-MarkdownPreviewInfo "Destination: $destinationRoot"

    if ($OpenFolder) {
        Invoke-Item $destinationRoot
    }

    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Rendering validation failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Next step: review the error above, then rerun this script.'
    $host.SetShouldExit(1)
    return
}
