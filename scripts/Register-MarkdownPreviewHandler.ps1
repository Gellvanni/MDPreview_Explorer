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
$previewKey = '{8895b1c6-b41f-4c1c-a562-0d564250836f}'
$previewHostAppId64 = '{6D2B5079-2F0B-48DD-AB7F-97CEC514D30B}'
$previewHostAppId32on64 = '{534A1E02-D58F-44F0-B58B-36CBED287C7C}'

Assert-Administrator

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..')
$dllPath = Join-Path $projectRoot "src\MdExplorerPreview\bin\$Platform\$Configuration\MdExplorerPreview.dll"

if (!(Test-Path $dllPath)) {
    throw "DLL nao encontrada em: $dllPath. Compile o projeto primeiro em $Configuration | $Platform."
}

if ($Platform -eq 'x64') {
    $regasm = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe'
    $appId = $previewHostAppId64
    $registryView = [Microsoft.Win32.RegistryView]::Registry64
} else {
    $regasm = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\RegAsm.exe'
    $appId = $previewHostAppId32on64
    $registryView = [Microsoft.Win32.RegistryView]::Registry32
}

if (!(Test-Path $regasm)) {
    throw "RegAsm nao encontrado em: $regasm"
}

function Get-BaseKey {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive
    )

    return [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $registryView)
}

function Ensure-SubKey {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $baseKey = Get-BaseKey -Hive $Hive
    return $baseKey.CreateSubKey($Path)
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind = [Microsoft.Win32.RegistryValueKind]::String
    )

    $key = Ensure-SubKey -Hive $Hive -Path $Path
    try {
        $key.SetValue($Name, $Value, $Kind)
    } finally {
        $key.Dispose()
    }
}

function Set-DefaultRegistryValue {
    param(
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Value
    )

    $key = Ensure-SubKey -Hive $Hive -Path $Path
    try {
        $key.SetValue('', $Value, [Microsoft.Win32.RegistryValueKind]::String)
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

Write-Host "Registrando assembly COM com RegAsm..." -ForegroundColor Cyan
& $regasm $dllPath /codebase | Out-Host

Write-Host "Configurando AppID do Preview Host..." -ForegroundColor Cyan
$clsidPath = "CLSID\$handlerClsid"
$registeredClsid = Get-DefaultRegistryValue -Hive ClassesRoot -Path $clsidPath
if ($null -eq $registeredClsid) {
    throw "O CLSID do handler nao apareceu no registro apos RegAsm: HKCR\\$clsidPath"
}
Set-RegistryValue -Hive ClassesRoot -Path $clsidPath -Name 'AppID' -Value $appId

Write-Host "Adicionando handler a lista global de Preview Handlers..." -ForegroundColor Cyan
Set-RegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers' -Name $handlerClsid -Value 'Markdown Explorer Preview'

Write-Host "Configurando emulacao moderna do controle WebBrowser para prevhost.exe..." -ForegroundColor Cyan
Set-RegistryValue -Hive LocalMachine -Path 'SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION' -Name 'prevhost.exe' -Value 11001 -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)

$extensions = @('.md', '.markdown', '.mdown', '.mkdn', '.mdwn', '.mdtxt', '.mdtext')

function Register-PreviewAssociation {
    param(
        [Parameter(Mandatory=$true)][string]$RegistryPath,
        [Parameter(Mandatory=$true)][string]$DisplayLabel
    )

    $shellExPath = "$RegistryPath\ShellEx\$previewKey"
    Set-DefaultRegistryValue -Hive ClassesRoot -Path $shellExPath -Value $handlerClsid
    Write-Host "  OK $DisplayLabel" -ForegroundColor DarkGray
}

Write-Host "Associando extensoes Markdown ao preview handler sem trocar o app padrao..." -ForegroundColor Cyan
foreach ($ext in $extensions) {
    $sysAssoc = "SystemFileAssociations\$ext"
    Register-PreviewAssociation -RegistryPath $sysAssoc -DisplayLabel "SystemFileAssociations $ext"

    try {
        $progId = Get-DefaultRegistryValue -Hive ClassesRoot -Path $ext
        if (![string]::IsNullOrWhiteSpace($progId)) {
            Register-PreviewAssociation -RegistryPath $progId -DisplayLabel "ProgID $progId"
        }
    } catch {
        Write-Warning "Nao foi possivel registrar via ProgID para ${ext}: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Concluido. Agora reinicie o Explorer ou faca logoff/logon se o preview nao aparecer de imediato." -ForegroundColor Green
