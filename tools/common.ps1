Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Resolve-ProjectGodot([string]$Requested) {
    if ($Requested) { return (Resolve-Path -LiteralPath $Requested).Path }
    $bundled = Join-Path $ProjectRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $bundled) { return $bundled }
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    throw 'Godot not found. Supply -GodotPath <Godot 4 executable>.'
}

function Set-ProjectUserData {
    # Process-local only; avoids requiring write access to the Windows profile.
    $env:APPDATA = Join-Path $ProjectRoot '.local-data'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
}

function Invoke-CheckedGodot([string]$Godot, [string[]]$Arguments, [string]$LogName, [int]$ExpectedCode = 0, [int]$TimeoutSeconds = 45, [string]$WorkingDirectory = $ProjectRoot) {
    $evidence = Join-Path $ProjectRoot 'docs/evidence'
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $Godot
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        ($stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()) | Set-Content -LiteralPath (Join-Path $evidence $LogName) -Encoding utf8
        throw "Godot timed out: $LogName"
    }
    $result = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
    $code = $process.ExitCode
    $process.Dispose()
    $result | Set-Content -LiteralPath (Join-Path $evidence $LogName) -Encoding utf8
    Write-Output $result.Trim()
    Write-Output "EXIT_CODE=$code EXPECTED=$ExpectedCode"
    if ($code -ne $ExpectedCode) { throw "Unexpected Godot exit $code ($LogName)" }
    if ($ExpectedCode -eq 0 -and $result -match '(?m)(SCRIPT ERROR:|ERROR:|WARNING:|^FAIL )') {
        throw "Godot diagnostics failed quality gate ($LogName)"
    }
}
