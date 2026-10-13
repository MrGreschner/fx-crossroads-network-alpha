param([string]$GodotExe = "", [switch]$AlsoWeb)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path $PSScriptRoot -Parent
$cacheRoot = Join-Path $env:LOCALAPPDATA 'FXCrossroadsBuild'
New-Item -ItemType Directory -Force $cacheRoot | Out-Null
function Download($url, $path) {
  Write-Host "Downloading $(Split-Path $path -Leaf)..."
  Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
}
function Run-Godot([string[]]$arguments) {
  & $GodotExe @arguments
  if ($LASTEXITCODE -ne 0) { throw "Godot failed with exit code $LASTEXITCODE. See the output above." }
}
if (-not $GodotExe) {
  $engineZip = Join-Path $cacheRoot 'godot-4.5.1-windows.zip'
  $engineFolder = Join-Path $cacheRoot 'engine'
  $GodotExe = Join-Path $engineFolder 'Godot_v4.5.1-stable_win64.exe'
  if (-not (Test-Path $GodotExe)) {
    Download 'https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/Godot_v4.5.1-stable_win64.exe.zip' $engineZip
    Expand-Archive $engineZip $engineFolder -Force
  }
}
$GodotExe = (Resolve-Path $GodotExe).Path
$consoleExe = $GodotExe -replace '\.exe$', '_console.exe'
if (Test-Path $consoleExe) { $GodotExe = $consoleExe }
$version = & $GodotExe --version
if ($version -notmatch '^4\.5\.1\.stable') { throw "This build uses Godot 4.5.1. Found: $version" }
$templateRoot = Join-Path $env:APPDATA 'Godot/export_templates/4.5.1.stable'
if (-not (Test-Path (Join-Path $templateRoot 'windows_release_x86_64.exe'))) {
  $templatesZip = Join-Path $cacheRoot 'templates.zip'
  Download 'https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz' $templatesZip
  $unpacked = Join-Path $cacheRoot 'templates-unpacked'
  Expand-Archive $templatesZip $unpacked -Force
  New-Item -ItemType Directory -Force $templateRoot | Out-Null
  Copy-Item (Join-Path $unpacked 'templates/*') $templateRoot -Recurse -Force
}
# The official extension self-registers; preserve every library and licence in its ZIP.
$rtcZip = Join-Path $cacheRoot 'webrtc-1.2.2.zip'
Download 'https://github.com/godotengine/webrtc-native/releases/download/1.2.2-stable/godot-extension-webrtc_native.zip' $rtcZip
Expand-Archive $rtcZip $projectRoot -Force
$extensions = Get-ChildItem $projectRoot -Recurse -Filter '*.gdextension' | Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' }
if (-not $extensions) { throw 'The WebRTC extension was not extracted. Do not distribute a build without it.' }
$rtcDll = Get-ChildItem $projectRoot -Recurse -Filter '*.dll' | Where-Object { $_.Name -match 'webrtc' }
if (-not $rtcDll) { throw 'Native WebRTC DLL missing from the downloaded extension.' }
Run-Godot -arguments @('--headless','--path',$projectRoot,'--editor','--import','--quit')
Run-Godot -arguments @('--headless','--path',$projectRoot,'--script','res://tests/native_webrtc_probe.gd')
$exportRoot = Join-Path $projectRoot 'exports'
$windowsFolder = Join-Path $exportRoot 'FX_Crossroads_Windows_v156'
if (Test-Path $windowsFolder) { Remove-Item $windowsFolder -Recurse -Force }
New-Item -ItemType Directory -Force $windowsFolder | Out-Null
Run-Godot -arguments @('--headless','--path',$projectRoot,'--export-release','Windows Desktop',(Join-Path $windowsFolder 'FX_Crossroads.exe'))
if (-not (Test-Path (Join-Path $windowsFolder 'FX_Crossroads.exe')) -or -not (Test-Path (Join-Path $windowsFolder 'FX_Crossroads.pck'))) { throw 'Windows export incomplete.' }
if (-not (Get-ChildItem $windowsFolder -Recurse -Filter '*.dll')) { throw 'Export has no native WebRTC library; refusing to package it.' }
Copy-Item (Join-Path $projectRoot 'WINDOWS_PLAYER_README.txt') $windowsFolder -Force
Copy-Item $rtcZip (Join-Path $windowsFolder 'WebRTC_ThirdParty_Original.zip') -Force
$windowsZip = Join-Path $exportRoot 'FX_Crossroads_Windows_v156.zip'
Compress-Archive -Path $windowsFolder -DestinationPath $windowsZip -Force
if ($AlsoWeb) {
  $webFolder = Join-Path $exportRoot 'web-v156'
  if (Test-Path $webFolder) { Remove-Item $webFolder -Recurse -Force }
  New-Item -ItemType Directory -Force $webFolder | Out-Null
  Run-Godot -arguments @('--headless','--path',$projectRoot,'--export-release','Web',(Join-Path $webFolder 'index.html'))
  Compress-Archive -Path (Join-Path $webFolder '*') -DestinationPath (Join-Path $exportRoot 'FX_Crossroads_Web_v156.zip') -Force
}
Write-Host "Finished: $windowsZip" -ForegroundColor Green
Write-Host 'Test Windows-to-Windows and Windows-to-browser multiplayer before classroom rollout.'
