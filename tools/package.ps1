param([string]$GodotPath)
. (Join-Path $PSScriptRoot 'common.ps1')
$engine = Resolve-ProjectGodot $GodotPath
Set-ProjectUserData
$releaseDir = Join-Path $ProjectRoot 'builds/windows'
New-Item -ItemType Directory -Force $releaseDir | Out-Null
Invoke-CheckedGodot $engine @('--headless','--path',$ProjectRoot,'--export-pack','Windows Demo','builds/windows/EndlessSurvival.pck') 'm5-pack.log' -TimeoutSeconds 120
$engineDirectory = Split-Path -Parent $engine
Copy-Item -LiteralPath (Join-Path $engineDirectory 'Godot_v4.7.2-stable_win64.exe') -Destination (Join-Path $releaseDir 'EndlessSurvival.exe') -Force
Copy-Item -LiteralPath $engine -Destination (Join-Path $releaseDir 'EndlessSurvival_console.exe') -Force
@'
@echo off
setlocal
cd /d "%~dp0"
set "APPDATA=%~dp0userdata"
start "" "%~dp0EndlessSurvival.exe" --main-pack "%~dp0EndlessSurvival.pck" %*
'@ | Set-Content -LiteralPath (Join-Path $releaseDir 'Play.cmd') -Encoding ascii
@'
ENDLESS SURVIVAL RPG - THREE HEROES PIXEL V3 FIX03 REVIEW

Extract the entire folder. Double-click Play.cmd (or EndlessSurvival.exe).
No Godot installation or PowerShell7 is needed. Offline, keyboard/mouse.

WASD move. Basic attacks are automatic. Choose Auto or Manual in the menu.
J/K/L/I unlock at levels3/6/9/11. Manual aims along the last movement/facing direction. Esc pauses;
pause menu supports mode/key remapping and fullscreen/window switching.
Choose one of3 cards every level. Bosses at10/20/30/...; defeat them to
change map, keep upgrades, restore15% HP and gain2s spawn protection.
Retry resets the run while preserving control settings. Reroll1 per10 levels,
max3 stored. Original procedural pixel characters/tiles/VFX and synthetic sounds
are prototype demo art. CHARACTER includes a real-executor Art Preview.
Astra, Vex and Boros use the original 2D pixel v3 pipeline and shared VFX.
Enemy damage receivers follow the torso, separate from navigation colliders.
Concept-fidelity review is PENDING owner approval.

This package uses the official portable Godot4.7.2 runtime plus an exported PCK.
The runtime is the full official executable because stripped export templates
were unavailable locally. No source project or external installation is required.
Unsigned local build: it is not a signed public release.

Source license remains reserved pending owner's decision. Engine/third-party
licenses are included here. Godot: https://godotengine.org/license/

Optional automated packaged acceptance:
EndlessSurvival_console.exe --headless --main-pack EndlessSurvival.pck -- --smoke-release
'@ | Set-Content -LiteralPath (Join-Path $releaseDir 'README.txt') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $ProjectRoot 'docs/licenses/GODOT_LICENSE.txt'),(Join-Path $ProjectRoot 'docs/licenses/GODOT_THIRD_PARTY.json'),(Join-Path $ProjectRoot 'LICENSE_PROJECT.txt') -Destination $releaseDir -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot 'ASSET_LICENSES.md'),(Join-Path $ProjectRoot 'docs/art_asset_ledger.csv') -Destination $releaseDir -Force
$licenseDir = Join-Path $releaseDir 'licenses'
New-Item -ItemType Directory -Force $licenseDir | Out-Null
Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'licenses') -File |
    Where-Object { $_.Extension -in @('.txt','.md','.csv') } |
    Copy-Item -Destination $licenseDir -Force
Invoke-CheckedGodot (Join-Path $releaseDir 'EndlessSurvival_console.exe') @('--headless','--main-pack',(Join-Path $releaseDir 'EndlessSurvival.pck'),'--','--smoke-release','--pack-check') 'm5-release-smoke.log' -TimeoutSeconds 120 -WorkingDirectory $releaseDir
$smoke = Get-Content -LiteralPath (Join-Path $ProjectRoot 'docs/evidence/m5-release-smoke.log') -Raw
if (-not $smoke.Contains('RELEASE_SMOKE_OK profiles=3 boss_victories=3')) { throw 'Packaged acceptance marker missing' }
$releaseZip = Join-Path $ProjectRoot 'builds/EndlessSurvival-Windows.zip'
& (Join-Path $PSScriptRoot 'release_archive.ps1') -ReleaseDir $releaseDir -ArchivePath $releaseZip
Write-Output "WINDOWS_PACKAGE=$releaseZip"

