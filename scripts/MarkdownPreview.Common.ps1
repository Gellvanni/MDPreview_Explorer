Set-StrictMode -Version Latest

$Script:MarkdownPreviewConfiguration = 'Release'
$Script:MarkdownPreviewPlatform = 'x64'
$Script:MarkdownPreviewHandlerClsid = '{B3F3E9C1-4A4E-48A2-8F54-BC4C10E5E8A1}'
$Script:MarkdownPreviewProgId = 'MdExplorerPreview.MarkdownPreviewHandler'
$Script:MarkdownPreviewShellExKey = '{8895b1c6-b41f-4c1c-a562-0d564250836f}'
$Script:MarkdownPreviewHostAppId = '{6D2B5079-2F0B-48DD-AB7F-97CEC514D30B}'
$Script:MarkdownPreviewExtensions = @('.md', '.markdown', '.mdown', '.mkdn', '.mdwn', '.mdtxt', '.mdtext')

function Write-MarkdownPreviewSection {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Write-MarkdownPreviewInfo {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-MarkdownPreviewSuccess {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Write-MarkdownPreviewWarning {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Test-MarkdownPreviewAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-MarkdownPreviewAdministrator {
    if (-not (Test-MarkdownPreviewAdministrator)) {
        throw 'This script must run in an elevated PowerShell session.'
    }
}

function Get-MarkdownPreviewProjectRoot {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    $scriptsRoot = Split-Path -Parent $ScriptPath
    return (Resolve-Path (Join-Path $scriptsRoot '..')).Path
}

function Get-MarkdownPreviewProjectFile {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot 'src\MdExplorerPreview\MdExplorerPreview.csproj'
}

function Get-MarkdownPreviewInstallerProjectFile {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot 'installer\MdExplorerPreview.Setup.wixproj'
}

function Get-MarkdownPreviewMsiPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$Configuration = $Script:MarkdownPreviewConfiguration
    )

    return Join-Path $ProjectRoot "installer\bin\x64\$Configuration\MdExplorerPreview.Setup.msi"
}

function Get-MarkdownPreviewMsiInstallDirectory {
    return Join-Path ${env:ProgramFiles} 'MdExplorerPreview'
}

function Get-MarkdownPreviewMsiAutoUnblockerExePath {
    return Join-Path (Get-MarkdownPreviewMsiInstallDirectory) 'MdExplorerPreview.AutoUnblocker.exe'
}

function Get-MarkdownPreviewMsiRunValueName {
    return 'MdExplorerPreview Auto-Unblocker'
}

function Get-MarkdownPreviewContentRoot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot 'content'
}

function Get-MarkdownPreviewValidationRoot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path (Get-MarkdownPreviewContentRoot -ProjectRoot $ProjectRoot) 'validation-suite'
}

function Get-MarkdownPreviewMindOsTemplateRoot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path (Get-MarkdownPreviewContentRoot -ProjectRoot $ProjectRoot) 'mind-os-template'
}

function Get-MarkdownPreviewPrimaryValidationFile {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path (Get-MarkdownPreviewValidationRoot -ProjectRoot $ProjectRoot) 'preview-fixture.md'
}

function Get-MarkdownPreviewAutoUnblockerProjectFile {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot 'src\MdExplorerPreview.AutoUnblocker\MdExplorerPreview.AutoUnblocker.csproj'
}

function Get-MarkdownPreviewAutoUnblockerBuildOutputDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    return Join-Path $ProjectRoot "src\MdExplorerPreview.AutoUnblocker\bin\$Platform\$Configuration"
}

function Get-MarkdownPreviewAutoUnblockerBuildExePath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    return Join-Path (Get-MarkdownPreviewAutoUnblockerBuildOutputDirectory -ProjectRoot $ProjectRoot -Configuration $Configuration -Platform $Platform) 'MdExplorerPreview.AutoUnblocker.exe'
}

function Get-MarkdownPreviewAutoUnblockerDeployDirectory {
    return Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'MdExplorerPreview\AutoUnblocker'
}

function Get-MarkdownPreviewAutoUnblockerDeployedExePath {
    return Join-Path (Get-MarkdownPreviewAutoUnblockerDeployDirectory) 'MdExplorerPreview.AutoUnblocker.exe'
}

function Get-MarkdownPreviewAutoUnblockerSettingsPath {
    return Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'MdExplorerPreview\settings.json'
}

function Get-MarkdownPreviewAutoUnblockerDefaultSettingsTemplatePath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path $ProjectRoot 'config\auto-unblocker.settings.json'
}

function Get-MarkdownPreviewAutoUnblockerLogPath {
    $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        return Join-Path $userProfile 'AppData\LocalLow\MdExplorerPreview\auto-unblocker.log'
    }

    return Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'MdExplorerPreview\auto-unblocker.log'
}

function Get-MarkdownPreviewAutoUnblockerStartupShortcutPath {
    return Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)) 'MdExplorerPreview Auto-Unblocker.lnk'
}

function Get-MarkdownPreviewDllPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    return Join-Path $ProjectRoot "src\MdExplorerPreview\bin\$Platform\$Configuration\MdExplorerPreview.dll"
}

function Invoke-MarkdownPreviewBuild {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    $projectFile = Get-MarkdownPreviewProjectFile -ProjectRoot $ProjectRoot
    if (!(Test-Path $projectFile)) {
        throw "Project file not found: $projectFile"
    }

    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -eq $dotnet) {
        throw 'dotnet CLI was not found. Install the .NET SDK or ship a prebuilt Release x64 DLL.'
    }

    Write-MarkdownPreviewInfo "Building Release x64 DLL from source."
    & $dotnet.Source build $projectFile -c $Configuration "-p:Platform=$Platform"
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed with exit code $LASTEXITCODE."
    }
}

function Resolve-MarkdownPreviewDll {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [ValidateSet('Auto', 'Always', 'Never')][string]$BuildMode = 'Auto',
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    $dllPath = Get-MarkdownPreviewDllPath -ProjectRoot $ProjectRoot -Configuration $Configuration -Platform $Platform
    $projectFile = Get-MarkdownPreviewProjectFile -ProjectRoot $ProjectRoot
    $canBuild = (Test-Path $projectFile) -and ($null -ne (Get-Command dotnet -ErrorAction SilentlyContinue))

    if ($BuildMode -eq 'Always') {
        Invoke-MarkdownPreviewBuild -ProjectRoot $ProjectRoot -Configuration $Configuration -Platform $Platform
    }

    if (!(Test-Path $dllPath)) {
        if ($BuildMode -eq 'Never') {
            throw "Expected existing DLL was not found: $dllPath"
        }

        if ($canBuild) {
            Invoke-MarkdownPreviewBuild -ProjectRoot $ProjectRoot -Configuration $Configuration -Platform $Platform
        }
    }

    if (!(Test-Path $dllPath)) {
        throw "Release x64 DLL was not found after resolution: $dllPath"
    }

    return $dllPath
}

function Resolve-MarkdownPreviewAutoUnblockerExe {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [ValidateSet('Auto', 'Always', 'Never')][string]$BuildMode = 'Auto',
        [string]$Configuration = $Script:MarkdownPreviewConfiguration,
        [string]$Platform = $Script:MarkdownPreviewPlatform
    )

    $exePath = Get-MarkdownPreviewAutoUnblockerBuildExePath -ProjectRoot $ProjectRoot -Configuration $Configuration -Platform $Platform
    $projectFile = Get-MarkdownPreviewAutoUnblockerProjectFile -ProjectRoot $ProjectRoot
    $canBuild = (Test-Path $projectFile) -and ($null -ne (Get-Command dotnet -ErrorAction SilentlyContinue))

    if ($BuildMode -eq 'Always') {
        $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
        if ($null -eq $dotnet) {
            throw 'dotnet CLI was not found. Install the .NET SDK or ship a prebuilt auto-unblocker executable.'
        }

        Write-MarkdownPreviewInfo 'Building auto-unblocker executable from source.'
        & $dotnet.Source build $projectFile -c $Configuration "-p:Platform=$Platform"
        if ($LASTEXITCODE -ne 0) {
            throw "Auto-unblocker build failed with exit code $LASTEXITCODE."
        }
    }

    if (!(Test-Path $exePath)) {
        if ($BuildMode -eq 'Never') {
            throw "Expected existing auto-unblocker executable was not found: $exePath"
        }

        if ($canBuild) {
            $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
            Write-MarkdownPreviewInfo 'Building auto-unblocker executable from source.'
            & $dotnet.Source build $projectFile -c $Configuration "-p:Platform=$Platform"
            if ($LASTEXITCODE -ne 0) {
                throw "Auto-unblocker build failed with exit code $LASTEXITCODE."
            }
        }
    }

    if (!(Test-Path $exePath)) {
        throw "Auto-unblocker executable was not found after resolution: $exePath"
    }

    return $exePath
}

function Unblock-MarkdownPreviewPackage {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $files = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File
    $unblocked = 0

    foreach ($file in $files) {
        $stream = Get-Item -LiteralPath $file.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
        if ($null -eq $stream) {
            continue
        }

        Remove-Item -LiteralPath $file.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
        $unblocked++
    }

    return [pscustomobject]@{
        FilesInspected = $files.Count
        FilesUnblocked = $unblocked
    }
}

function Initialize-MarkdownPreviewAutoUnblockerSettings {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$Force
    )

    $settingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
    $templatePath = Get-MarkdownPreviewAutoUnblockerDefaultSettingsTemplatePath -ProjectRoot $ProjectRoot
    if (!(Test-Path $templatePath)) {
        throw "Auto-unblocker settings template not found: $templatePath"
    }

    $settingsDirectory = Split-Path -Parent $settingsPath
    [System.IO.Directory]::CreateDirectory($settingsDirectory) | Out-Null

    if ($Force -or !(Test-Path $settingsPath)) {
        Copy-Item -LiteralPath $templatePath -Destination $settingsPath -Force
    } else {
        Merge-MarkdownPreviewAutoUnblockerSettingsDefaults -SettingsPath $settingsPath -TemplatePath $templatePath
    }

    return $settingsPath
}

function Merge-MarkdownPreviewAutoUnblockerSettingsDefaults {
    param(
        [Parameter(Mandatory = $true)][string]$SettingsPath,
        [Parameter(Mandatory = $true)][string]$TemplatePath
    )

    $settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
    $template = Get-Content -LiteralPath $TemplatePath -Raw | ConvertFrom-Json

    foreach ($propertyName in @(
        'autoUnblockEnabled',
        'dryRun',
        'logEnabled',
        'logPath',
        'scanOnStartup',
        'unblockZipOnArrival',
        'settleDelayMs',
        'retryDelayMs',
        'maxWaitMs',
        'watchFolders'
    )) {
        if ($null -eq $settings.PSObject.Properties[$propertyName]) {
            $settings | Add-Member -NotePropertyName $propertyName -NotePropertyValue $template.$propertyName
        }
    }

    $mergedExtensions = New-Object System.Collections.Generic.List[string]
    $seenExtensions = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($extension in @($settings.allowedExtensions)) {
        if ([string]::IsNullOrWhiteSpace($extension)) {
            continue
        }

        if ($seenExtensions.Add($extension)) {
            $mergedExtensions.Add($extension)
        }
    }

    foreach ($extension in @($template.allowedExtensions)) {
        if ([string]::IsNullOrWhiteSpace($extension)) {
            continue
        }

        if ($seenExtensions.Add($extension)) {
            $mergedExtensions.Add($extension)
        }
    }

    if ($null -eq $settings.PSObject.Properties['allowedExtensions']) {
        $settings | Add-Member -NotePropertyName 'allowedExtensions' -NotePropertyValue @($mergedExtensions)
    } else {
        $settings.allowedExtensions = @($mergedExtensions)
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SettingsPath -Encoding UTF8
}

function Copy-MarkdownPreviewAutoUnblockerDeployment {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [ValidateSet('Auto', 'Always', 'Never')][string]$BuildMode = 'Auto'
    )

    $sourceExe = Resolve-MarkdownPreviewAutoUnblockerExe -ProjectRoot $ProjectRoot -BuildMode $BuildMode
    $sourceDirectory = Split-Path -Parent $sourceExe
    $destinationDirectory = Get-MarkdownPreviewAutoUnblockerDeployDirectory

    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null

    Get-ChildItem -LiteralPath $sourceDirectory -File | Where-Object { $_.Extension -ne '.pdb' } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destinationDirectory $_.Name) -Force
    }

    return Get-MarkdownPreviewAutoUnblockerDeployedExePath
}

function Set-MarkdownPreviewAutoUnblockerStartupShortcut {
    $shortcutPath = Get-MarkdownPreviewAutoUnblockerStartupShortcutPath
    $targetPath = Get-MarkdownPreviewAutoUnblockerDeployedExePath

    if (!(Test-Path $targetPath)) {
        throw "Cannot create startup shortcut because the deployed auto-unblocker executable was not found: $targetPath"
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = Split-Path -Parent $targetPath
    $shortcut.IconLocation = "$targetPath,0"
    $shortcut.Description = 'MdExplorerPreview Auto-Unblocker'
    $shortcut.Save()

    return $shortcutPath
}

function Remove-MarkdownPreviewAutoUnblockerStartupShortcut {
    $shortcutPath = Get-MarkdownPreviewAutoUnblockerStartupShortcutPath
    if (Test-Path $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
}

function Stop-MarkdownPreviewAutoUnblockerProcess {
    $runningProcesses = @(Get-Process 'MdExplorerPreview.AutoUnblocker' -ErrorAction SilentlyContinue)
    if ($runningProcesses.Count -eq 0) {
        return
    }

    $runningProcesses | Stop-Process -Force -ErrorAction SilentlyContinue

    $deadline = [DateTime]::UtcNow.AddSeconds(8)
    do {
        Start-Sleep -Milliseconds 200
        $runningProcesses = @(Get-Process 'MdExplorerPreview.AutoUnblocker' -ErrorAction SilentlyContinue)
    } while ($runningProcesses.Count -gt 0 -and [DateTime]::UtcNow -lt $deadline)

    if ($runningProcesses.Count -gt 0) {
        throw 'Auto-unblocker process is still running after the stop request.'
    }
}

function Start-MarkdownPreviewAutoUnblockerProcess {
    param([switch]$Restart)

    $exePath = Get-MarkdownPreviewAutoUnblockerDeployedExePath
    if (!(Test-Path $exePath)) {
        throw "Auto-unblocker executable not found: $exePath"
    }

    if ($Restart) {
        Stop-MarkdownPreviewAutoUnblockerProcess
        Start-Sleep -Milliseconds 400
    } elseif ($null -ne (Get-Process 'MdExplorerPreview.AutoUnblocker' -ErrorAction SilentlyContinue)) {
        return
    }

    Start-Process -FilePath $exePath -WorkingDirectory (Split-Path -Parent $exePath) | Out-Null
    Start-Sleep -Milliseconds 700
}

function Install-MarkdownPreviewAutoUnblocker {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [ValidateSet('Auto', 'Always', 'Never')][string]$BuildMode = 'Auto'
    )

    Stop-MarkdownPreviewAutoUnblockerProcess
    $deployedExePath = Copy-MarkdownPreviewAutoUnblockerDeployment -ProjectRoot $ProjectRoot -BuildMode $BuildMode
    $settingsPath = Initialize-MarkdownPreviewAutoUnblockerSettings -ProjectRoot $ProjectRoot
    $shortcutPath = Set-MarkdownPreviewAutoUnblockerStartupShortcut
    Start-MarkdownPreviewAutoUnblockerProcess -Restart

    return [pscustomobject]@{
        ExecutablePath = $deployedExePath
        SettingsPath = $settingsPath
        ShortcutPath = $shortcutPath
        LogPath = Get-MarkdownPreviewAutoUnblockerLogPath
    }
}

function Uninstall-MarkdownPreviewAutoUnblocker {
    param([switch]$RemoveData)

    Stop-MarkdownPreviewAutoUnblockerProcess
    Remove-MarkdownPreviewAutoUnblockerStartupShortcut

    $deployDirectory = Get-MarkdownPreviewAutoUnblockerDeployDirectory
    if (Test-Path $deployDirectory) {
        Remove-Item -LiteralPath $deployDirectory -Force -Recurse -ErrorAction SilentlyContinue
    }

    if ($RemoveData) {
        $settingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
        if (Test-Path $settingsPath) {
            Remove-Item -LiteralPath $settingsPath -Force -ErrorAction SilentlyContinue
        }

        $logPath = Get-MarkdownPreviewAutoUnblockerLogPath
        if (Test-Path $logPath) {
            Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Restart-MarkdownPreviewExplorer {
    Write-MarkdownPreviewInfo 'Restarting Windows Explorer.'

    $runningPreviewHosts = Get-Process prevhost -ErrorAction SilentlyContinue
    if ($null -ne $runningPreviewHosts) {
        Write-MarkdownPreviewInfo 'Stopping stale preview host processes.'
        Stop-Process -Name prevhost -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $runningExplorer = Get-Process explorer -ErrorAction SilentlyContinue
    if ($null -ne $runningExplorer) {
        Stop-Process -Name explorer -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
    }

    Start-Process explorer.exe
    Start-Sleep -Seconds 2
    Write-MarkdownPreviewSuccess 'Explorer restarted.'
}

function Get-MarkdownPreviewRegistryValue {
    param(
        [Parameter(Mandatory = $true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Name = '',
        [Microsoft.Win32.RegistryView]$View = [Microsoft.Win32.RegistryView]::Registry64
    )

    $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $View)
    try {
        $key = $baseKey.OpenSubKey($Path)
        if ($null -eq $key) {
            return $null
        }

        try {
            return $key.GetValue($Name, $null)
        } finally {
            $key.Dispose()
        }
    } finally {
        $baseKey.Dispose()
    }
}

function Test-MarkdownPreviewInstalled {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $dllPath = Get-MarkdownPreviewDllPath -ProjectRoot $ProjectRoot
    $checks = @(
        [pscustomobject]@{
            Name = 'Release x64 DLL exists'
            Passed = (Test-Path $dllPath)
            Details = $dllPath
        },
        [pscustomobject]@{
            Name = 'CLSID is registered'
            Passed = ($null -ne (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "CLSID\$Script:MarkdownPreviewHandlerClsid"))
            Details = "HKCR\\CLSID\\$Script:MarkdownPreviewHandlerClsid"
        },
        [pscustomobject]@{
            Name = 'Preview host AppID is set'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "CLSID\$Script:MarkdownPreviewHandlerClsid" -Name 'AppID') -eq $Script:MarkdownPreviewHostAppId)
            Details = $Script:MarkdownPreviewHostAppId
        },
        [pscustomobject]@{
            Name = 'Global PreviewHandlers entry exists'
            Passed = ($null -ne (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $Script:MarkdownPreviewHandlerClsid))
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PreviewHandlers"
        },
        [pscustomobject]@{
            Name = '.md ShellEx association exists'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "SystemFileAssociations\.md\ShellEx\$Script:MarkdownPreviewShellExKey") -eq $Script:MarkdownPreviewHandlerClsid)
            Details = "HKCR\\SystemFileAssociations\\.md\\ShellEx\\$Script:MarkdownPreviewShellExKey"
        },
        [pscustomobject]@{
            Name = 'Browser emulation for prevhost.exe exists'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe') -eq 11001)
            Details = '11001'
        },
        [pscustomobject]@{
            Name = 'Explorer is running'
            Passed = ($null -ne (Get-Process explorer -ErrorAction SilentlyContinue))
            Details = 'explorer.exe'
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
        SampleFile = Get-MarkdownPreviewPrimaryValidationFile -ProjectRoot $ProjectRoot
    }
}

function Test-MarkdownPreviewAutoUnblockerInstalled {
    $checks = @(
        [pscustomobject]@{
            Name = 'Auto-unblocker executable deployed'
            Passed = (Test-Path (Get-MarkdownPreviewAutoUnblockerDeployedExePath))
            Details = (Get-MarkdownPreviewAutoUnblockerDeployedExePath)
        },
        [pscustomobject]@{
            Name = 'Auto-unblocker settings file exists'
            Passed = (Test-Path (Get-MarkdownPreviewAutoUnblockerSettingsPath))
            Details = (Get-MarkdownPreviewAutoUnblockerSettingsPath)
        },
        [pscustomobject]@{
            Name = 'Startup shortcut exists'
            Passed = (Test-Path (Get-MarkdownPreviewAutoUnblockerStartupShortcutPath))
            Details = (Get-MarkdownPreviewAutoUnblockerStartupShortcutPath)
        },
        [pscustomobject]@{
            Name = 'Auto-unblocker process is running'
            Passed = ($null -ne (Get-Process 'MdExplorerPreview.AutoUnblocker' -ErrorAction SilentlyContinue))
            Details = 'MdExplorerPreview.AutoUnblocker.exe'
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
        SettingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
        LogPath = Get-MarkdownPreviewAutoUnblockerLogPath
    }
}

function Test-MarkdownPreviewMsiInstalled {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $installDirectory = Get-MarkdownPreviewMsiInstallDirectory
    $handlerPath = Join-Path $installDirectory 'MdExplorerPreview.dll'
    $autoUnblockerPath = Get-MarkdownPreviewMsiAutoUnblockerExePath
    $runEntryName = Get-MarkdownPreviewMsiRunValueName
    $expectedRunValue = '"' + $autoUnblockerPath + '"'

    $checks = @(
        [pscustomobject]@{
            Name = 'MSI install folder exists'
            Passed = (Test-Path $installDirectory)
            Details = $installDirectory
        },
        [pscustomobject]@{
            Name = 'Installed handler assembly exists'
            Passed = (Test-Path $handlerPath)
            Details = $handlerPath
        },
        [pscustomobject]@{
            Name = 'Installed auto-unblocker executable exists'
            Passed = (Test-Path $autoUnblockerPath)
            Details = $autoUnblockerPath
        },
        [pscustomobject]@{
            Name = 'CLSID is registered'
            Passed = ($null -ne (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "CLSID\$Script:MarkdownPreviewHandlerClsid"))
            Details = "HKCR\\CLSID\\$Script:MarkdownPreviewHandlerClsid"
        },
        [pscustomobject]@{
            Name = 'Global PreviewHandlers entry exists'
            Passed = ($null -ne (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $Script:MarkdownPreviewHandlerClsid))
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PreviewHandlers"
        },
        [pscustomobject]@{
            Name = '.md ShellEx association exists'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "SystemFileAssociations\.md\ShellEx\$Script:MarkdownPreviewShellExKey") -eq $Script:MarkdownPreviewHandlerClsid)
            Details = "HKCR\\SystemFileAssociations\\.md\\ShellEx\\$Script:MarkdownPreviewShellExKey"
        },
        [pscustomobject]@{
            Name = 'Browser emulation for prevhost.exe exists'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe') -eq 11001)
            Details = '11001'
        },
        [pscustomobject]@{
            Name = 'HKLM Run entry exists for auto-unblocker'
            Passed = ((Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $runEntryName) -eq $expectedRunValue)
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run\\$runEntryName"
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
        SampleFile = Get-MarkdownPreviewPrimaryValidationFile -ProjectRoot $ProjectRoot
        SettingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
        LogPath = Get-MarkdownPreviewAutoUnblockerLogPath
    }
}

function Test-MarkdownPreviewUninstalled {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $checks = @(
        [pscustomobject]@{
            Name = 'CLSID entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "CLSID\$Script:MarkdownPreviewHandlerClsid"))
            Details = "HKCR\\CLSID\\$Script:MarkdownPreviewHandlerClsid"
        },
        [pscustomobject]@{
            Name = 'ProgID entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path $Script:MarkdownPreviewProgId))
            Details = "HKCR\\$Script:MarkdownPreviewProgId"
        },
        [pscustomobject]@{
            Name = 'Global PreviewHandlers entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $Script:MarkdownPreviewHandlerClsid))
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PreviewHandlers"
        },
        [pscustomobject]@{
            Name = '.md ShellEx association removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "SystemFileAssociations\.md\ShellEx\$Script:MarkdownPreviewShellExKey"))
            Details = "HKCR\\SystemFileAssociations\\.md\\ShellEx\\$Script:MarkdownPreviewShellExKey"
        },
        [pscustomobject]@{
            Name = 'Browser emulation entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe'))
            Details = 'prevhost.exe'
        },
        [pscustomobject]@{
            Name = 'Explorer is running'
            Passed = ($null -ne (Get-Process explorer -ErrorAction SilentlyContinue))
            Details = 'explorer.exe'
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
    }
}

function Test-MarkdownPreviewAutoUnblockerUninstalled {
    $checks = @(
        [pscustomobject]@{
            Name = 'Auto-unblocker executable removed'
            Passed = (!(Test-Path (Get-MarkdownPreviewAutoUnblockerDeployedExePath)))
            Details = (Get-MarkdownPreviewAutoUnblockerDeployedExePath)
        },
        [pscustomobject]@{
            Name = 'Startup shortcut removed'
            Passed = (!(Test-Path (Get-MarkdownPreviewAutoUnblockerStartupShortcutPath)))
            Details = (Get-MarkdownPreviewAutoUnblockerStartupShortcutPath)
        },
        [pscustomobject]@{
            Name = 'Auto-unblocker process stopped'
            Passed = ($null -eq (Get-Process 'MdExplorerPreview.AutoUnblocker' -ErrorAction SilentlyContinue))
            Details = 'MdExplorerPreview.AutoUnblocker.exe'
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
    }
}

function Test-MarkdownPreviewMsiUninstalled {
    $installDirectory = Get-MarkdownPreviewMsiInstallDirectory
    $handlerPath = Join-Path $installDirectory 'MdExplorerPreview.dll'
    $autoUnblockerPath = Get-MarkdownPreviewMsiAutoUnblockerExePath
    $runEntryName = Get-MarkdownPreviewMsiRunValueName

    $checks = @(
        [pscustomobject]@{
            Name = 'MSI install folder removed'
            Passed = (!(Test-Path $installDirectory))
            Details = $installDirectory
        },
        [pscustomobject]@{
            Name = 'Installed handler assembly removed'
            Passed = (!(Test-Path $handlerPath))
            Details = $handlerPath
        },
        [pscustomobject]@{
            Name = 'Installed auto-unblocker executable removed'
            Passed = (!(Test-Path $autoUnblockerPath))
            Details = $autoUnblockerPath
        },
        [pscustomobject]@{
            Name = 'CLSID entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "CLSID\$Script:MarkdownPreviewHandlerClsid"))
            Details = "HKCR\\CLSID\\$Script:MarkdownPreviewHandlerClsid"
        },
        [pscustomobject]@{
            Name = 'Global PreviewHandlers entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $Script:MarkdownPreviewHandlerClsid))
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PreviewHandlers"
        },
        [pscustomobject]@{
            Name = '.md ShellEx association removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive ClassesRoot -Path "SystemFileAssociations\.md\ShellEx\$Script:MarkdownPreviewShellExKey"))
            Details = "HKCR\\SystemFileAssociations\\.md\\ShellEx\\$Script:MarkdownPreviewShellExKey"
        },
        [pscustomobject]@{
            Name = 'Browser emulation entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe'))
            Details = 'prevhost.exe'
        },
        [pscustomobject]@{
            Name = 'HKLM Run entry removed'
            Passed = ($null -eq (Get-MarkdownPreviewRegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $runEntryName))
            Details = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run\\$runEntryName"
        }
    )

    return [pscustomobject]@{
        IsValid = ($checks.Passed -notcontains $false)
        Checks = $checks
        SettingsPath = Get-MarkdownPreviewAutoUnblockerSettingsPath
        LogPath = Get-MarkdownPreviewAutoUnblockerLogPath
    }
}

function Show-MarkdownPreviewValidation {
    param(
        [Parameter(Mandatory = $true)][psobject]$Validation,
        [Parameter(Mandatory = $true)][string]$Title
    )

    Write-MarkdownPreviewSection $Title

    foreach ($check in $Validation.Checks) {
        if ($check.Passed) {
            Write-MarkdownPreviewSuccess "$($check.Name) -> $($check.Details)"
        } else {
            Write-MarkdownPreviewWarning "$($check.Name) -> $($check.Details)"
        }
    }
}
