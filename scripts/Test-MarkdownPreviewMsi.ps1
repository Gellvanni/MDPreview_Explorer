param(
    [ValidateSet('Guide', 'Install', 'Upgrade', 'Uninstall', 'Reinstall')]
    [string]$Mode = 'Guide',

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$MsiPath,

    [string]$PreviousMsiPath,

    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'MarkdownPreview.Common.ps1')

function Resolve-MsiPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$CandidatePath,
        [string]$ConfigurationName
    )

    if (-not [string]::IsNullOrWhiteSpace($CandidatePath)) {
        return (Resolve-Path $CandidatePath).Path
    }

    $defaultPath = Get-MarkdownPreviewMsiPath -ProjectRoot $ProjectRoot -Configuration $ConfigurationName
    if (!(Test-Path $defaultPath)) {
        throw "MSI was not found: $defaultPath. Build it first with .\\scripts\\Build-MarkdownPreviewMsi.ps1."
    }

    return $defaultPath
}

function New-MsiLogPath {
    param(
        [Parameter(Mandatory = $true)][string]$LogRoot,
        [Parameter(Mandatory = $true)][string]$Name
    )

    [System.IO.Directory]::CreateDirectory($LogRoot) | Out-Null
    return Join-Path $LogRoot ("{0:yyyyMMdd-HHmmss}-{1}.log" -f [DateTime]::Now, $Name)
}

function Invoke-MsiExec {
    param(
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Write-MarkdownPreviewInfo "$Label -> msiexec.exe $Arguments"
    $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $Arguments -Wait -PassThru
    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
        throw "$Label failed with exit code $($process.ExitCode)."
    }

    if ($process.ExitCode -eq 3010) {
        Write-MarkdownPreviewWarning "$Label requested a reboot (exit code 3010)."
    } else {
        Write-MarkdownPreviewSuccess "$Label completed successfully."
    }
}

function Show-MsiGuide {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$CurrentMsiPath,
        [string]$OldMsiPath,
        [Parameter(Mandatory = $true)][string]$LogRoot
    )

    Write-MarkdownPreviewSection 'Markdown Preview MSI Validation Guide'
    Write-MarkdownPreviewInfo "MSI path: $CurrentMsiPath"
    Write-MarkdownPreviewInfo "Validation logs: $LogRoot"
    Write-MarkdownPreviewInfo 'Build command:'
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\Build-MarkdownPreviewMsi.ps1" -ForegroundColor Gray
    Write-MarkdownPreviewInfo 'Clean install command:'
    Write-Host "  msiexec /i `"$CurrentMsiPath`" /l*v `"$([IO.Path]::Combine($LogRoot, 'install.log'))`"" -ForegroundColor Gray

    if (-not [string]::IsNullOrWhiteSpace($OldMsiPath)) {
        Write-MarkdownPreviewInfo 'Upgrade command sequence:'
        Write-Host "  msiexec /i `"$OldMsiPath`" /l*v `"$([IO.Path]::Combine($LogRoot, 'upgrade-old.log'))`"" -ForegroundColor Gray
        Write-Host "  msiexec /i `"$CurrentMsiPath`" /l*v `"$([IO.Path]::Combine($LogRoot, 'upgrade-new.log'))`"" -ForegroundColor Gray
    } else {
        Write-MarkdownPreviewInfo 'Upgrade flow: build a newer MSI by bumping installer\InstallerVersion.props, then install the new MSI over the old one.'
    }

    Write-MarkdownPreviewInfo 'Uninstall command:'
    Write-Host "  msiexec /x `"$CurrentMsiPath`" /l*v `"$([IO.Path]::Combine($LogRoot, 'uninstall.log'))`"" -ForegroundColor Gray
    Write-MarkdownPreviewInfo 'Reinstall flow: uninstall, then install again using the same MSI.'
    Write-MarkdownPreviewInfo 'After install, validate the preview with:'
    Write-Host "  $(Get-MarkdownPreviewPrimaryValidationFile -ProjectRoot $ProjectRoot)" -ForegroundColor Gray
    Write-MarkdownPreviewInfo 'After install, validate the auto-unblocker by dropping a blocked .md or .txt into Downloads and checking:'
    Write-Host "  $(Get-MarkdownPreviewAutoUnblockerLogPath)" -ForegroundColor Gray
}

try {
    $projectRoot = Get-MarkdownPreviewProjectRoot -ScriptPath $MyInvocation.MyCommand.Path
    $resolvedMsiPath = Resolve-MsiPath -ProjectRoot $projectRoot -CandidatePath $MsiPath -ConfigurationName $Configuration
    $resolvedPreviousMsiPath = $null
    if (-not [string]::IsNullOrWhiteSpace($PreviousMsiPath)) {
        $resolvedPreviousMsiPath = (Resolve-Path $PreviousMsiPath).Path
    }

    $validationRoot = Join-Path $projectRoot 'artifacts\msi-validation'

    if ($Mode -eq 'Guide' -or -not $Execute) {
        Show-MsiGuide -ProjectRoot $projectRoot -CurrentMsiPath $resolvedMsiPath -OldMsiPath $resolvedPreviousMsiPath -LogRoot $validationRoot
        if (-not $Execute) {
            Write-MarkdownPreviewInfo 'Add -Execute to let this script run msiexec for the selected mode.'
        }

        return
    }

    Assert-MarkdownPreviewAdministrator

    switch ($Mode) {
        'Install' {
            $installLog = New-MsiLogPath -LogRoot $validationRoot -Name 'install'
            Invoke-MsiExec -Arguments "/i `"$resolvedMsiPath`" /l*v `"$installLog`"" -Label 'MSI install'
            $validation = Test-MarkdownPreviewMsiInstalled -ProjectRoot $projectRoot
            Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-install MSI validation'
            Write-MarkdownPreviewInfo "Sample preview file: $($validation.SampleFile)"
            Write-MarkdownPreviewInfo "Settings path: $($validation.SettingsPath)"
            Write-MarkdownPreviewInfo "Auto-unblocker log: $($validation.LogPath)"
        }
        'Upgrade' {
            if ([string]::IsNullOrWhiteSpace($resolvedPreviousMsiPath)) {
                throw 'Upgrade mode requires -PreviousMsiPath pointing to the older MSI.'
            }

            $oldInstallLog = New-MsiLogPath -LogRoot $validationRoot -Name 'upgrade-old'
            $newInstallLog = New-MsiLogPath -LogRoot $validationRoot -Name 'upgrade-new'
            Invoke-MsiExec -Arguments "/i `"$resolvedPreviousMsiPath`" /l*v `"$oldInstallLog`"" -Label 'MSI upgrade baseline install'
            Invoke-MsiExec -Arguments "/i `"$resolvedMsiPath`" /l*v `"$newInstallLog`"" -Label 'MSI major upgrade install'
            $validation = Test-MarkdownPreviewMsiInstalled -ProjectRoot $projectRoot
            Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-upgrade MSI validation'
            Write-MarkdownPreviewInfo "Settings path preserved or recreated on first launch: $($validation.SettingsPath)"
            Write-MarkdownPreviewInfo "Auto-unblocker log: $($validation.LogPath)"
        }
        'Uninstall' {
            $uninstallLog = New-MsiLogPath -LogRoot $validationRoot -Name 'uninstall'
            Invoke-MsiExec -Arguments "/x `"$resolvedMsiPath`" /l*v `"$uninstallLog`"" -Label 'MSI uninstall'
            $validation = Test-MarkdownPreviewMsiUninstalled
            Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-uninstall MSI validation'
            Write-MarkdownPreviewInfo "Per-user settings are preserved by design at: $($validation.SettingsPath)"
            Write-MarkdownPreviewInfo "Per-user log is preserved by design at: $($validation.LogPath)"
        }
        'Reinstall' {
            $reinstallUninstallLog = New-MsiLogPath -LogRoot $validationRoot -Name 'reinstall-uninstall'
            $reinstallInstallLog = New-MsiLogPath -LogRoot $validationRoot -Name 'reinstall-install'

            if ((Test-MarkdownPreviewMsiInstalled -ProjectRoot $projectRoot).IsValid) {
                Invoke-MsiExec -Arguments "/x `"$resolvedMsiPath`" /l*v `"$reinstallUninstallLog`"" -Label 'MSI reinstall uninstall step'
            } else {
                Write-MarkdownPreviewInfo 'No active MSI install was detected. Skipping the uninstall step.'
            }

            Invoke-MsiExec -Arguments "/i `"$resolvedMsiPath`" /l*v `"$reinstallInstallLog`"" -Label 'MSI reinstall install step'
            $validation = Test-MarkdownPreviewMsiInstalled -ProjectRoot $projectRoot
            Show-MarkdownPreviewValidation -Validation $validation -Title 'Post-reinstall MSI validation'
            Write-MarkdownPreviewInfo "Sample preview file: $($validation.SampleFile)"
        }
    }
} catch {
    Write-MarkdownPreviewSection 'MSI validation failed'
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-MarkdownPreviewInfo 'Review the error above and inspect the MSI validation logs under artifacts\msi-validation.'
    $host.SetShouldExit(1)
    return
}
