#requires -Version 5.1
<#
.SYNOPSIS
  Builds an independent IT-Werkstatt Windows PE TEST ISO with Microsoft's ADK.
.DESCRIPTION
  Default: preflight only. -Build: create a NEW local working directory and ISO.
  Never writes to USB drives, existing ISOs or existing WinPE work directories.
  Run from a 64-bit elevated PowerShell on Windows with ADK and WinPE Add-on.
#>
[CmdletBinding()]
param(
    [switch]$Build,
    [string]$OutputRoot = "$env:SystemDrive\IT-Werkstatt-Build"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-File([string] $Path, [string] $Message) {
    if (-not [System.IO.File]::Exists($Path)) { throw "$Message`n$Path" }
}

function Invoke-Native([string] $Command, [string[]] $CommandArgs) {
    # PowerShell 5.1 uebergibt komplexe native Argumente nicht immer eindeutig.
    # Deshalb die komplette Windows-Kommandozeile ausdruecklich quoten.
    # Beispiel: /PackagePath:"C:\Program Files (x86)\...\WinPE-WMI.cab"
    $quotedArgs = foreach ($arg in $CommandArgs) {
        if ($arg -match '[\r\n"]') {
            throw 'Anfuehrungszeichen oder Zeilenumbruch in DISM-Argument nicht unterstuetzt.'
        }
        if ($arg -match '^(/[^:]+:)(.*)$') {
            $prefix = $Matches[1]
            $value = $Matches[2]
            if ($value -match '\s') { $prefix + '"' + $value + '"' }
            else { $arg }
        } elseif ($arg -match '\s') {
            '"' + $arg + '"'
        } else {
            $arg
        }
    }
    $argumentLine = $quotedArgs -join ' '
    Write-Host ('> ' + $Command + ' ' + $argumentLine)

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Command
    $startInfo.Arguments = $argumentLine
    $startInfo.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $process.Dispose()
    if ($exitCode -ne 0) { throw "Fehlercode $exitCode bei: $Command" }
}

function Add-WinPEComponent([string] $ImagePath, [string] $CabPath) {
    # Der DISM-PowerShell-Befehl uebergibt Pfade als echte Stringparameter.
    # Damit entfaellt das fehleranfaellige Quoting von /PackagePath unter Program Files (x86).
    Assert-File $CabPath 'WinPE-CAB fehlt.'
    Write-Host ('> Add-WindowsPackage -Path "' + $ImagePath + '" -PackagePath "' + $CabPath + '" -NoRestart')
    Add-WindowsPackage -Path $ImagePath -PackagePath $CabPath -NoRestart -ErrorAction Stop | Out-Null
}

function Invoke-AdkBatch([string] $Action, [string] $EnvBatch, [string] $Tool, [string[]] $ToolArgs, [string] $RunDir) {
    # An intermediate CMD avoids PowerShell/cmd quoting issues in Program Files (x86).
    $batFile = Join-Path $RunDir ('adk-' + $Action + '.cmd')
    foreach ($text in @($EnvBatch, $Tool, $RunDir) + $ToolArgs) {
        if ($text -match '[\r\n"&|<>^%!]') { throw 'Unzulaessiges Zeichen in einem ADK-Pfad oder -Argument.' }
    }
    $line = 'call "' + $Tool + '"'
    foreach ($a in $ToolArgs) {
        if ($a -in @('amd64', '/ISO')) { $line += ' ' + $a }
        else { $line += ' "' + $a + '"' }
    }
    $cmdContent = "@echo off`r`ncall `"$EnvBatch`"`r`nif errorlevel 1 exit /b 1`r`n$line`r`nexit /b %errorlevel%`r`n"
    [System.IO.File]::WriteAllText($batFile, $cmdContent, [System.Text.Encoding]::ASCII)
    # ADK-Batchdateien wieder direkt per cmd.exe starten (wie im v0.2-Copype-Test).
    # Invoke-Native ist fuer DISM-Aufrufe vorgesehen und lehnt bereits quotierte
    # Argumente ab. /c braucht hier aber den in Anfuehrungszeichen gesetzten Pfad.
    Write-Host ('> cmd.exe /d /c "' + $batFile + '"')
    & "$env:SystemRoot\System32\cmd.exe" /d /c ('"' + $batFile + '"')
    if ($LASTEXITCODE -ne 0) { throw "Fehlercode $LASTEXITCODE beim ADK-Schritt: $Action" }
}

$mounted = $false
$mountDir = $null
$transcript = $false
try {
    if (-not [Environment]::Is64BitOperatingSystem -or -not [Environment]::Is64BitProcess) {
        throw '64-Bit-Windows mit 64-Bit-PowerShell erforderlich.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'PowerShell als Administrator starten.'
    }
    $prog86 = [Environment]::GetFolderPath('ProgramFilesX86')
    if ([string]::IsNullOrWhiteSpace($prog86)) { throw 'Program Files (x86) nicht gefunden.' }
    $adk = Join-Path $prog86 'Windows Kits\10\Assessment and Deployment Kit'
    $pe = Join-Path $adk 'Windows Preinstallation Environment'
    $ocDir = Join-Path $pe 'amd64\WinPE_OCs'
    $envBat = Join-Path $adk 'Deployment Tools\DandISetEnv.bat'
    $copype = Join-Path $pe 'copype.cmd'
    $makeMedia = Join-Path $pe 'MakeWinPEMedia.cmd'
    foreach ($f in @($envBat,$copype,$makeMedia)) { Assert-File $f 'ADK Deployment Tools bzw. WinPE Add-on fehlen.' }
    $ocNames = @('WinPE-WMI','WinPE-Scripting','WinPE-SecureStartup')
    foreach ($oc in $ocNames) {
        Assert-File (Join-Path $ocDir ($oc + '.cab')) 'Fehlendes WinPE-OC (amd64).'
        Assert-File (Join-Path $ocDir ('en-us\' + $oc + '_en-us.cab')) 'Fehlendes WinPE-Sprachpaket (en-us).'
    }
    # Bereits bei --check sicherstellen, dass der DISM-PowerShell-Weg verfuegbar ist.
    Import-Module Dism -ErrorAction Stop
    if (-not (Get-Command Add-WindowsPackage -CommandType Cmdlet -ErrorAction SilentlyContinue)) {
        throw 'Das DISM PowerShell-Cmdlet Add-WindowsPackage ist nicht verfuegbar.'
    }
    $startFiles = @('startnet.cmd','NOLS-Autostart.cmd','NOLS-Preflight.cmd')
    foreach ($name in $startFiles) { Assert-File (Join-Path $PSScriptRoot ('startup\'+$name)) 'Startdatei fehlt.' }

    # Safety: only the system drive. The external Samsung T9 is never a build target.
    $fullRoot = [System.IO.Path]::GetFullPath($OutputRoot).TrimEnd('\')
    $rootDrive = [System.IO.Path]::GetPathRoot($fullRoot).TrimEnd('\')
    $systemDrive = $env:SystemDrive.TrimEnd('\')
    if ($rootDrive -ine $systemDrive -or $fullRoot.Length -le $rootDrive.Length + 1) {
        throw 'OutputRoot muss ein Unterordner des lokalen Windows-Systemlaufwerks sein.'
    }
    if ($fullRoot -match '["&|<>^%!]') { throw 'Sonderzeichen im Zielpfad nicht unterstuetzt.' }
    if ($fullRoot.StartsWith($env:SystemRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Das WinPE-Buildziel darf nicht unter Windows liegen.'
    }
    $free = (Get-PSDrive -Name $systemDrive.Substring(0,1)).Free
    if ($free -lt 10GB) { throw 'Mindestens 10 GiB freier Speicher auf dem Windows-Laufwerk benoetigt.' }

    Write-Host 'IT-WERKSTATT WINPE BUILDER v0.2.4 - VORPRUEFUNG' -ForegroundColor Cyan
    Write-Host 'ADK gefunden, WinPE-Pakete und DISM-Cmdlet vorhanden, Startdateien vorhanden.'
    Write-Host 'Komponenten: WinPE-WMI, WinPE-Scripting, WinPE-SecureStartup'
    Write-Host ('Build-Ziel: ' + $fullRoot)
    Write-Host 'Kein USB-Zugriff, keine vorhandene ISO wird ueberschrieben.'
    if (-not $Build) {
        Write-Host 'NUR VORSCHAU. Zum Erstellen: BUILD-RECOVERY.cmd --build'
        exit 0
    }

    # Each build receives a fresh, never-reused work directory.
    [System.IO.Directory]::CreateDirectory($fullRoot) | Out-Null
    $runName = 'Run-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')
    $runDir = Join-Path $fullRoot $runName
    if ([System.IO.Directory]::Exists($runDir)) { throw 'Zielordner bereits vorhanden. Abbruch.' }
    [System.IO.Directory]::CreateDirectory($runDir) | Out-Null
    Start-Transcript -Path (Join-Path $runDir 'build.log') -ErrorAction Stop | Out-Null
    $transcript = $true
    $work = Join-Path $runDir 'WinPE-amd64'
    $mountDir = Join-Path $work 'mount'
    $bootWim = Join-Path $work 'media\sources\boot.wim'
    $outputIso = Join-Path $runDir 'IT-Werkstatt-Recovery-TEST.iso'

    Write-Host '[1/7] Frische Windows-PE-Arbeitsdateien via Copype'
    Invoke-AdkBatch 'copype' $envBat $copype @('amd64',$work) $runDir
    Assert-File $bootWim 'Copype lieferte keine boot.wim.'
    if (-not (Test-Path $mountDir -PathType Container)) { throw 'Copype Mount-Verzeichnis fehlt.' }

    Write-Host '[2/7] WinPE-Bootimage einbinden'
    Invoke-Native "$env:SystemRoot\System32\dism.exe" @('/Mount-Image',('/ImageFile:'+$bootWim),'/Index:1',('/MountDir:'+$mountDir))
    $mounted = $true

    Write-Host '[3/7] Optionale Komponenten und en-us-Sprachpakete in Reihenfolge integrieren'
    foreach ($oc in $ocNames) {
        Add-WinPEComponent $mountDir (Join-Path $ocDir ($oc+'.cab'))
        Add-WinPEComponent $mountDir (Join-Path $ocDir ('en-us\'+$oc+'_en-us.cab'))
    }

    Write-Host '[4/7] Deutsche Tastatur als Standard setzen'
    # WICHTIG: Beide DISM-Schalter als getrennte Strings uebergeben.
    # In PowerShell hat das Komma eine andere Operatorbindung als erwartet;
    # '/Image:' + $mountDir, '/Set-InputLocale:...' verschmilzt sonst zu EINEM
    # String und fuehrt zu DISM-Fehler 1639 (fehlender Wartungsbefehl).
    $intlImageArg = '/Image:' + $mountDir
    $intlLocaleArg = '/Set-InputLocale:0407:00000407'
    Invoke-Native "$env:SystemRoot\System32\dism.exe" @($intlImageArg, $intlLocaleArg)

    Write-Host '[5/7] Bewaehrte WinPE-Startskripte einfuegen'
    $internal = Join-Path $mountDir 'NOLS'
    [System.IO.Directory]::CreateDirectory($internal) | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'startup\startnet.cmd') -Destination (Join-Path $mountDir 'Windows\System32\startnet.cmd') -Force
    foreach ($f in @('NOLS-Autostart.cmd','NOLS-Preflight.cmd')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('startup\'+$f)) -Destination (Join-Path $internal $f) -Force
    }
    $liveStart = [System.IO.File]::ReadAllText((Join-Path $mountDir 'Windows\System32\startnet.cmd'))
    if (-not $liveStart.Contains('wpeinit') -or -not $liveStart.Contains('NOLS-Autostart.cmd')) { throw 'Startnet-Validierung fehlgeschlagen.' }
    Assert-File (Join-Path $mountDir 'Windows\System32\cscript.exe') 'WinPE-Scripting wurde nicht erfolgreich integriert.'

    Write-Host '[6/7] Image committen und Mount loesen'
    Invoke-Native "$env:SystemRoot\System32\dism.exe" @('/Unmount-Image',('/MountDir:'+$mountDir),'/Commit')
    $mounted = $false

    Write-Host '[7/7] Separate ISO erzeugen (kein /UFD, kein /F)'
    Invoke-AdkBatch 'makeiso' $envBat $makeMedia @('/ISO',$work,$outputIso) $runDir
    Assert-File $outputIso 'MakeWinPEMedia lieferte keine ISO.'
    if ((Get-Item -LiteralPath $outputIso).Length -lt 100MB) { throw 'ISO unerwartet klein - nicht verwenden.' }
    $hash = (Get-FileHash -LiteralPath $outputIso -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText($outputIso+'.sha256', "$hash  IT-Werkstatt-Recovery-TEST.iso`r`n", [System.Text.Encoding]::ASCII)
    Write-Host ('ISO erstellt: '+$outputIso) -ForegroundColor Green
    Write-Host ('SHA256: '+$hash)
    Write-Host 'Vor Einsatz: BIOS- und UEFI-Boot, QWERTZ, Toolkit-Suche, Hardwareinventur testen.'
    Write-Host 'NICHT in ein oeffentliches GitHub-Release hochladen (Microsoft-Lizenzklaerung).'
}
catch {
    Write-Host ('ABBRUCH: ' + $_.Exception.Message) -ForegroundColor Red
    if ($mounted -and $mountDir) {
        Write-Host 'Mount vorhanden: Versuche, nur die neue Arbeitskopie zu verwerfen.'
        & "$env:SystemRoot\System32\dism.exe" /Unmount-Image ('/MountDir:'+$mountDir) /Discard
        if ($LASTEXITCODE -ne 0) {
            Write-Host ('WARNUNG: Mount muss manuell geprueft werden: '+$mountDir) -ForegroundColor Yellow
        }
    }
    exit 1
}
finally {
    if ($transcript) { try { Stop-Transcript | Out-Null } catch {} }
}
