param(
    [ValidateSet('Auto', 'Always', 'Never')]
    [string]$BuildMode = 'Auto',
    [string]$Destination,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

function New-LabSettings {
    param(
        [Parameter(Mandatory = $true)][string]$SettingsPath,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$MonitoredPath,
        [Parameter(Mandatory = $true)][string]$CustomTrustedPath,
        [Parameter(Mandatory = $true)][bool]$UnblockZipOnArrival
    )

    $settings = [ordered]@{
        autoUnblockEnabled = $true
        dryRun = $false
        logEnabled = $true
        logPath = $LogPath
        scanOnStartup = $true
        unblockZipOnArrival = $UnblockZipOnArrival
        settleDelayMs = 350
        retryDelayMs = 350
        maxWaitMs = 20000
        allowedExtensions = @('.md', '.markdown', '.mdown', '.mkdn', '.mdwn', '.txt', '.log', '.json', '.yaml', '.yml', '.ini', '.csv', '.xml', '.svg', '.png', '.jpg', '.jpeg', '.zip')
        watchFolders = @(
            @{
                name = 'DownloadsLab'
                path = $MonitoredPath
                enabled = $true
                recursive = $true
            },
            @{
                name = 'CustomTrustedFolder'
                path = $CustomTrustedPath
                enabled = $true
                recursive = $true
            }
        )
    }

    $json = $settings | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $SettingsPath -Value $json -Encoding UTF8
}

function Start-LabWatcher {
    param(
        [Parameter(Mandatory = $true)][string]$ExePath,
        [Parameter(Mandatory = $true)][string]$SettingsPath
    )

    $process = Start-Process -FilePath $ExePath -ArgumentList '--settings', $SettingsPath -PassThru
    Start-Sleep -Milliseconds 1200
    return $process
}

function Stop-LabWatcher {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process)

    if (!$Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

function Set-ZoneIdentifier {
    param([Parameter(Mandatory = $true)][string]$Path)

    Set-Content -LiteralPath $Path -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3"
}

function Test-HasZoneIdentifier {
    param([Parameter(Mandatory = $true)][string]$Path)

    return ($null -ne (Get-Item -LiteralPath $Path -Stream Zone.Identifier -ErrorAction SilentlyContinue))
}

function Wait-ForZoneState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$ShouldExist,
        [int]$TimeoutMs = 25000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMs)
    while ([DateTime]::UtcNow -lt $deadline) {
        $exists = Test-HasZoneIdentifier -Path $Path
        if ($exists -eq $ShouldExist) {
            return $true
        }

        Start-Sleep -Milliseconds 200
    }

    return $false
}

function Assert-ZoneState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$ShouldExist,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Wait-ForZoneState -Path $Path -ShouldExist $ShouldExist)) {
        throw "$Message Path: $Path"
    }
}

function Assert-LogContains {
    param(
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ((Test-Path $LogPath) -and ((Get-Content -LiteralPath $LogPath -Raw) -match [regex]::Escape($Pattern))) {
            return
        }

        Start-Sleep -Milliseconds 200
    }

    throw $Message
}

function New-BlockedSourceFile {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $Directory $FileName
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
    Set-ZoneIdentifier -Path $path
    return $path
}

function New-BlockedFileInPlace {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Set-ZoneIdentifier -Path $Path
    (Get-Item -LiteralPath $Path).LastWriteTime = [DateTime]::Now
    return $Path
}

try {
    Write-MarkdownPreviewSection 'Markdown Preview Auto-Unblocker Validation'

    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    $destinationRoot = if ([string]::IsNullOrWhiteSpace($Destination)) {
        Join-Path ([System.IO.Path]::GetTempPath()) 'MdExplorerPreview\auto-unblocker-validation'
    } else {
        [System.IO.Path]::GetFullPath($Destination)
    }

    if (Test-Path $destinationRoot) {
        Remove-Item -LiteralPath $destinationRoot -Recurse -Force
    }

    $monitoredRoot = Join-Path $destinationRoot 'trusted-downloads'
    $customTrustedRoot = Join-Path $destinationRoot 'trusted-custom'
    $monitoredSubRoot = Join-Path $monitoredRoot 'nested'
    $unmonitoredRoot = Join-Path $destinationRoot 'outside'
    $sourceRoot = Join-Path $destinationRoot 'source'
    $zipOptInRoot = Join-Path $destinationRoot 'zip-opt-in'

    $null = New-Item -ItemType Directory -Path $monitoredRoot, $customTrustedRoot, $monitoredSubRoot, $unmonitoredRoot, $sourceRoot, $zipOptInRoot -Force

    $settingsPath = Join-Path $destinationRoot 'settings.json'
    $logPath = Join-Path $destinationRoot 'auto-unblocker.log'
    New-LabSettings -SettingsPath $settingsPath -LogPath $logPath -MonitoredPath $monitoredRoot -CustomTrustedPath $customTrustedRoot -UnblockZipOnArrival:$false

    $startupTxt = Join-Path $monitoredRoot '00-startup-existing.txt'
    New-BlockedFileInPlace -Path $startupTxt -Content 'startup text file' | Out-Null

    $exePath = Resolve-MarkdownPreviewAutoUnblockerExe -ProjectRoot $projectRoot -BuildMode $BuildMode
    Write-MarkdownPreviewSuccess "Using auto-unblocker executable: $exePath"

    $watcher = Start-LabWatcher -ExePath $exePath -SettingsPath $settingsPath

    try {
        Assert-ZoneState -Path $startupTxt -ShouldExist:$false -Message 'Blocked text file already present at startup should be auto-unblocked during the initial scan.'

        $localMd = Join-Path $monitoredRoot '01-local.md'
        Set-Content -LiteralPath $localMd -Value '# local' -Encoding UTF8
        Assert-ZoneState -Path $localMd -ShouldExist:$false -Message 'Locally created markdown should stay without Zone.Identifier.'

        $downloadedMd = Join-Path $monitoredRoot '02-downloaded.md'
        New-BlockedFileInPlace -Path $downloadedMd -Content '# downloaded' | Out-Null
        Assert-ZoneState -Path $downloadedMd -ShouldExist:$false -Message 'Downloaded markdown should be auto-unblocked in a trusted folder.'

        $downloadedTxt = Join-Path $monitoredRoot '03-downloaded.txt'
        New-BlockedFileInPlace -Path $downloadedTxt -Content 'downloaded text file' | Out-Null
        Assert-ZoneState -Path $downloadedTxt -ShouldExist:$false -Message 'Downloaded text file should be auto-unblocked in a trusted folder.'

        $extractedMd = Join-Path $monitoredSubRoot '04-extracted.md'
        New-BlockedFileInPlace -Path $extractedMd -Content '# extracted' | Out-Null
        Assert-ZoneState -Path $extractedMd -ShouldExist:$false -Message 'Extracted markdown in a recursive subfolder should be auto-unblocked.'

        $logTarget = Join-Path $monitoredRoot '05-downloaded.log'
        New-BlockedFileInPlace -Path $logTarget -Content 'downloaded log file' | Out-Null
        Assert-ZoneState -Path $logTarget -ShouldExist:$false -Message 'Downloaded log file should be auto-unblocked in a trusted folder.'

        $jsonTarget = Join-Path $monitoredRoot '06-downloaded.json'
        New-BlockedFileInPlace -Path $jsonTarget -Content '{\"status\":\"ok\"}' | Out-Null
        Assert-ZoneState -Path $jsonTarget -ShouldExist:$false -Message 'Downloaded json file should be auto-unblocked in a trusted folder.'

        $svgTarget = Join-Path $customTrustedRoot '07-image.svg'
        New-BlockedFileInPlace -Path $svgTarget -Content '<svg xmlns="http://www.w3.org/2000/svg"></svg>' | Out-Null
        Assert-ZoneState -Path $svgTarget -ShouldExist:$false -Message 'Downloaded SVG should be auto-unblocked in a trusted folder.'

        $zipContentDirectory = Join-Path $sourceRoot 'zip-content'
        $null = New-Item -ItemType Directory -Path $zipContentDirectory -Force
        Set-Content -LiteralPath (Join-Path $zipContentDirectory 'inside.md') -Value '# zipped' -Encoding UTF8
        $zipTarget = Join-Path $monitoredRoot '08-archive.zip'
        Compress-Archive -Path (Join-Path $zipContentDirectory '*') -DestinationPath $zipTarget -Force
        Set-ZoneIdentifier -Path $zipTarget
        (Get-Item -LiteralPath $zipTarget).LastWriteTime = [DateTime]::Now
        Assert-ZoneState -Path $zipTarget -ShouldExist:$true -Message 'ZIP should remain blocked when zip auto-unblock is disabled.'

        $exeSource = New-BlockedSourceFile -Directory $sourceRoot -FileName '09-danger.exe' -Content 'fake exe'
        $exeTarget = Join-Path $monitoredRoot '09-danger.exe'
        Move-Item -LiteralPath $exeSource -Destination $exeTarget
        Assert-ZoneState -Path $exeTarget -ShouldExist:$true -Message 'Executable files must not be auto-unblocked.'

        $ps1Source = New-BlockedSourceFile -Directory $sourceRoot -FileName '10-script.ps1' -Content 'Write-Host hi'
        $ps1Target = Join-Path $monitoredRoot '10-script.ps1'
        Move-Item -LiteralPath $ps1Source -Destination $ps1Target
        Assert-ZoneState -Path $ps1Target -ShouldExist:$true -Message 'PowerShell scripts must not be auto-unblocked.'

        $outsideTarget = Join-Path $unmonitoredRoot '11-outside.md'
        New-BlockedFileInPlace -Path $outsideTarget -Content '# outside' | Out-Null
        Assert-ZoneState -Path $outsideTarget -ShouldExist:$true -Message 'Files outside trusted folders must remain blocked.'

        $rapidSource = New-BlockedSourceFile -Directory $sourceRoot -FileName '12-rapid.md' -Content '# rapid'
        $rapidTarget = Join-Path $monitoredRoot '12-rapid.md'
        Copy-Item -LiteralPath $rapidSource -Destination $rapidTarget
        Assert-ZoneState -Path $rapidTarget -ShouldExist:$false -Message 'Rapidly copied markdown should be auto-unblocked quickly.'

        Assert-LogContains -LogPath $logPath -Pattern 'action=unblocked' -Message 'Expected an unblocked action in the log.'
        Assert-LogContains -LogPath $logPath -Pattern 'action=ignored-extension' -Message 'Expected an ignored-extension action in the log.'
        Assert-LogContains -LogPath $logPath -Pattern 'action=ignored-zip' -Message 'Expected an ignored-zip action in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '00-startup-existing.txt' -Message 'Expected the startup text file to appear in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '02-downloaded.md' -Message 'Expected the downloaded markdown file to appear in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '03-downloaded.txt' -Message 'Expected the downloaded text file to appear in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '05-downloaded.log' -Message 'Expected the downloaded log file to appear in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '06-downloaded.json' -Message 'Expected the downloaded json file to appear in the log.'
        Assert-LogContains -LogPath $logPath -Pattern '09-danger.exe' -Message 'Expected the ignored executable file to appear in the log.'
    } finally {
        Stop-LabWatcher -Process $watcher
    }

    $zipOptInSettingsPath = Join-Path $destinationRoot 'settings-zip-opt-in.json'
    $zipOptInLogPath = Join-Path $destinationRoot 'auto-unblocker-zip-opt-in.log'
    New-LabSettings -SettingsPath $zipOptInSettingsPath -LogPath $zipOptInLogPath -MonitoredPath $zipOptInRoot -CustomTrustedPath $customTrustedRoot -UnblockZipOnArrival:$true
    $zipOptInWatcher = Start-LabWatcher -ExePath $exePath -SettingsPath $zipOptInSettingsPath

    try {
        $zipOptInContentDirectory = Join-Path $sourceRoot 'zip-opt-in-content'
        $null = New-Item -ItemType Directory -Path $zipOptInContentDirectory -Force
        Set-Content -LiteralPath (Join-Path $zipOptInContentDirectory 'inside.md') -Value '# zipped opt-in' -Encoding UTF8
        $zipOptInTarget = Join-Path $zipOptInRoot '10-archive-opt-in.zip'
        Compress-Archive -Path (Join-Path $zipOptInContentDirectory '*') -DestinationPath $zipOptInTarget -Force
        Set-ZoneIdentifier -Path $zipOptInTarget
        (Get-Item -LiteralPath $zipOptInTarget).LastWriteTime = [DateTime]::Now
        Assert-ZoneState -Path $zipOptInTarget -ShouldExist:$false -Message 'ZIP should be auto-unblocked when zip auto-unblock is enabled.'
        Assert-LogContains -LogPath $zipOptInLogPath -Pattern '10-archive-opt-in.zip' -Message 'Expected the opt-in ZIP file to appear in the zip log.'
    } finally {
        Stop-LabWatcher -Process $zipOptInWatcher
    }

    Write-MarkdownPreviewSection 'Auto-unblocker validation complete'
    Write-MarkdownPreviewSuccess 'Trusted-folder watcher scenarios passed.'
    Write-MarkdownPreviewInfo "Artifacts and logs: $destinationRoot"

    Write-MarkdownPreviewInfo 'Artifacts were kept on disk for manual inspection.'

    $host.SetShouldExit(0)
} catch {
    Write-MarkdownPreviewSection 'Auto-unblocker validation failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Review the lab artifacts and logs above, then rerun this script.'
    $host.SetShouldExit(1)
    return
}
