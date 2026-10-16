param([string]$PythonPath='C:/Users/Nguyen Tri Nhan/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe', [switch]$Capture, [switch]$Regression)
. (Join-Path $PSScriptRoot 'common.ps1')
$engine=Resolve-ProjectGodot ''
Set-ProjectUserData
Push-Location $ProjectRoot
try {
    foreach($script in @('generate.py','generate_environment.py','validate.py','test_pipeline.py')) {
        & $PythonPath (Join-Path $PSScriptRoot "art_pipeline/$script")
        if($LASTEXITCODE -ne 0) { throw "Art pipeline failed: $script" }
    }
    Invoke-CheckedGodot $engine @('--headless','--path',$ProjectRoot,'--editor','--quit') 'art-import.log' -TimeoutSeconds 120
    Invoke-CheckedGodot $engine @('--headless','--path',$ProjectRoot,'--script','res://tools/art_pipeline/import_frames.gd') 'art-frames-import.log'
    foreach($suite in @('test_art_frames','test_art_vfx','test_art_maps')) {
        Invoke-CheckedGodot $engine @('--headless','--path',$ProjectRoot,'--script',"res://tests/integration/$suite.gd") "$suite.log" -TimeoutSeconds 120
    }
    if($Capture) { Invoke-CheckedGodot $engine @('--path',$ProjectRoot,'--script','res://tools/art_pipeline/capture_preview.gd') 'art-capture.log' -TimeoutSeconds 120 }
    if($Regression) { & $engine --headless --path $ProjectRoot --script res://tests/run_all.gd; if($LASTEXITCODE -ne 0) { throw 'Regression failed' } }
} finally { Pop-Location }
