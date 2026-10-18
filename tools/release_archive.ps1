param([Parameter(Mandatory)][string]$ReleaseDir,[Parameter(Mandatory)][string]$ArchivePath)
$ErrorActionPreference='Stop'
# Construct the package from explicit release files. Import-cache and user-data
# files are excluded without deleting anything from the staging folder.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$releaseRoot=(Resolve-Path -LiteralPath $ReleaseDir).Path
$files=@(Get-ChildItem -LiteralPath $releaseRoot -File | Where-Object { $_.Extension -in @('.exe','.pck','.cmd','.txt','.md','.csv','.json') })
$files+=Get-ChildItem -LiteralPath (Join-Path $releaseRoot 'licenses') -File | Where-Object { $_.Extension -in @('.txt','.md','.csv') }
$stream=[IO.File]::Create($ArchivePath)
$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach($file in $files) {
        $relative=[IO.Path]::GetRelativePath($releaseRoot,$file.FullName).Replace('\','/')
        $null=[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,'windows/'+$relative,[IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $zip.Dispose(); $stream.Dispose() }
