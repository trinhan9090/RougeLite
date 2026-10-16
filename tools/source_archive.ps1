param()
$ErrorActionPreference='Stop'
$projectDir=Split-Path -Parent $PSScriptRoot
$archivePath=Join-Path $projectDir 'builds/EndlessSurvival-Source.zip'
New-Item -ItemType Directory -Force (Split-Path -Parent $archivePath) | Out-Null
$files=@()
foreach($folder in @('scripts','scenes','content','tests','docs','assets','screenshots','tools/art_pipeline')) {
    $folderPath=Join-Path $projectDir $folder
    if(Test-Path -LiteralPath $folderPath) { $files+=Get-ChildItem -LiteralPath $folderPath -Recurse -File }
}
$files+=Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in @('.ps1','.gd','.uid') }
foreach($file in @('project.godot','export_presets.cfg','README.md','Launch.cmd','AGENTS.md','ASSET_LICENSES.md','LICENSE_PROJECT.txt','.gitignore')) {
    $files+=Get-Item -LiteralPath (Join-Path $projectDir $file)
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream=[System.IO.File]::Create($archivePath)
$zip=[System.IO.Compression.ZipArchive]::new($stream,[System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach($file in $files | Where-Object { $_.Name -ne 'source_archive.log' -and $_.Extension -ne '.pyc' }) {
        $relative=[System.IO.Path]::GetRelativePath($projectDir,$file.FullName).Replace('\','/')
        $null=[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$relative,[System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $zip.Dispose(); $stream.Dispose() }
Get-Item -LiteralPath $archivePath | Select-Object FullName,Length
