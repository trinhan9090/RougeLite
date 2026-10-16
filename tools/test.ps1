param([string]$GodotPath, [switch]$Graphical, [ValidatePattern('^[a-z0-9-]+$')][string]$EvidencePrefix = 'm5')
. (Join-Path $PSScriptRoot 'common.ps1')
$engine = Resolve-ProjectGodot $GodotPath
Set-ProjectUserData
Invoke-CheckedGodot $engine @('--version') 'godot-version.log'
Invoke-CheckedGodot $engine @('--headless', '--path', $ProjectRoot, '--editor', '--quit') "$EvidencePrefix-final-import.log"
# Explicitly parse every script, including files not referenced by the main scene.
$scripts = @(Get-ChildItem (Join-Path $ProjectRoot 'scripts'), (Join-Path $ProjectRoot 'tests') -Filter '*.gd' -Recurse -File)
foreach ($script in $scripts) {
    $relative = [System.IO.Path]::GetRelativePath($ProjectRoot, $script.FullName).Replace('\', '/')
    Invoke-CheckedGodot $engine @('--headless', '--path', $ProjectRoot, '--check-only', '--script', "res://$relative") ('parse-' + $script.BaseName + '.log')
}
Invoke-CheckedGodot $engine @('--headless', '--path', $ProjectRoot, '--script', 'res://tests/run_all.gd') "$EvidencePrefix-all-tests.log" -TimeoutSeconds 240
Invoke-CheckedGodot $engine @('--headless', '--path', $ProjectRoot, '--quit-after', '3') "$EvidencePrefix-final-boot.log"
Invoke-CheckedGodot $engine @('--headless', '--path', $ProjectRoot, '--script', 'res://tests/run_all.gd', '--', '--deliberate-failure') "$EvidencePrefix-expected-failure.log" 1
$negativeEvidence = Get-Content -LiteralPath (Join-Path $ProjectRoot "docs/evidence/$EvidencePrefix-expected-failure.log") -Raw
if (-not $negativeEvidence.Contains('FAIL intentional assertion: expected 2, got 1') -or -not $negativeEvidence.Contains('RESULT suites=1 failures=1')) {
    throw 'Expected failure did not come from the deliberate assertion fixture.'
}
if ($Graphical) {
    Invoke-CheckedGodot $engine @('--path', $ProjectRoot, '--script', 'res://tests/scenes/test_boot.gd', '--', '--capture-frame') "$EvidencePrefix-menu-graphical.log"
    Invoke-CheckedGodot $engine @('--path', $ProjectRoot, '--script', 'res://tests/scenes/test_combat_run.gd', '--', '--capture-combat') "$EvidencePrefix-combat-graphical.log"
    Invoke-CheckedGodot $engine @('--path', $ProjectRoot, '--script', 'res://tests/scenes/test_m2_run.gd', '--', '--capture-m2') "$EvidencePrefix-active-graphical.log"
}
Write-Output 'PROJECT CHECKS PASSED; deliberate failing test correctly returned 1.'
