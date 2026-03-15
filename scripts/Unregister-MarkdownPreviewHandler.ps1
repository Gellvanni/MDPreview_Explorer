param(
    [ValidateSet('Release', 'Debug')]
    [string]$Configuration = 'Release',
    [ValidateSet('x64', 'x86')]
    [string]$Platform = 'x64'
)

$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Este script precisa ser executado em um PowerShell elevado (Executar como Administrador).'
    }
}

$handlerClsid = '{B3F3E9C1-4A4E-48A2-8F54-BC4C10E5E8A1}'
$handlerProgId = 'MdExplorerPreview.MarkdownPreviewHandler'
$previewKey = '{8895b1c6-b41f-4c1c-a562-0d564250836f}'

Assert-Administrator

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..')
$dllPath = Join-Path $projectRoot "src\MdExplorerPreview\bin\$Platform\$Configuration\MdExplorerPreview.dll"

if ($Platform -eq 'x64') {
    $regasm = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe'
    $registryView = [Microsoft.Win32.RegistryView]::Registry64
} else {
    $regasm = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\RegAsm.exe'
    $registryView = [Microsoft.Win32.RegistryView]::Registry32
}

$extensions = @('.md', '.markdown', '.mdown', '.mkdn', '.mdwn', '.mdtxt', '.mdtext')

function Get-BaseKey {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive
    )

    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $registryView)
}

function Remove-SubKeyTreeIfExists {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $baseKey = Get-BaseKey -Hive $Hive
    try {
        $baseKey.DeleteSubKeyTree($Path, $false)
    } catch {
        Write-Warning "Falha ao remover chave ${Hive}\\${Path}: $($_.Exception.Message)"
    } finally {
        $baseKey.Dispose()
    }
}

function Remove-RegistryValueIfExists {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name
    )

    $baseKey = Get-BaseKey -Hive $Hive
    $key = $baseKey.OpenSubKey($Path, $true)
    if ($null -eq $key) {
        return
    }

    try {
        $key.DeleteValue($Name, $false)
    } finally {
        $key.Dispose()
    }
}

function Get-DefaultRegistryValue {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $baseKey = Get-BaseKey -Hive $Hive
    $key = $baseKey.OpenSubKey($Path)
    if ($null -eq $key) {
        return $null
    }

    try {
        return $key.GetValue('')
    } finally {
        $key.Dispose()
    }
}

function Remove-PreviewAssociation {
    param([string]$RegistryPath)
    $shellExPath = "$RegistryPath\ShellEx\$previewKey"
    $baseKey = Get-BaseKey -Hive ClassesRoot
    $key = $baseKey.OpenSubKey($shellExPath)
    if ($null -ne $key) {
        $key.Dispose()
        try {
            $baseKey.DeleteSubKeyTree($shellExPath, $false)
        } catch {
            Write-Warning "Falha ao remover associacao em HKCR\\${shellExPath}: $($_.Exception.Message)"
        }
    }
    $baseKey.Dispose()
}

foreach ($ext in $extensions) {
    Remove-PreviewAssociation -RegistryPath "SystemFileAssociations\$ext"

    try {
        $progId = Get-DefaultRegistryValue -Hive ClassesRoot -Path $ext
        if (![string]::IsNullOrWhiteSpace($progId)) {
            Remove-PreviewAssociation -RegistryPath $progId
        }
    } catch {
        Write-Warning "Falha ao remover associacao via ProgID de ${ext}: $($_.Exception.Message)"
    }
}

Remove-RegistryValueIfExists -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $handlerClsid
Remove-RegistryValueIfExists -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe'

if ((Test-Path $dllPath) -and (Test-Path $regasm)) {
    Write-Host "Desregistrando assembly COM com RegAsm..." -ForegroundColor Cyan
    & $regasm $dllPath /u | Out-Host
}

Remove-SubKeyTreeIfExists -Hive ClassesRoot -Path "CLSID\$handlerClsid"
Remove-SubKeyTreeIfExists -Hive ClassesRoot -Path $handlerProgId

Write-Host "Concluido. Reinicie o Explorer se necessario." -ForegroundColor Green
