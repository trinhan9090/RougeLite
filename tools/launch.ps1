param([string]$GodotPath, [switch]$Editor)
. (Join-Path $PSScriptRoot 'common.ps1')
$engine = Resolve-ProjectGodot $GodotPath
Set-ProjectUserData
$launchArgs = @('--path', $ProjectRoot)
if ($Editor) { $launchArgs += '--editor' }
& $engine @launchArgs
exit $LASTEXITCODE
