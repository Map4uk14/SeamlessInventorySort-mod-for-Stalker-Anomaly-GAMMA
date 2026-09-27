[CmdletBinding()]
param(
    [string]$Python = 'python',
    [switch]$Upstream
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'validate.ps1') -Python $Python -Upstream:$Upstream

# Explicit allowlist: include every module, but never Git, tests, caches, or old ZIPs.
$files = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'gamedata') -File -Recurse)
$files += Get-Item -LiteralPath (Join-Path $projectRoot 'README.txt')
$files += Get-Item -LiteralPath (Join-Path $projectRoot 'LICENSE')
$packageDir = Join-Path $projectRoot 'packages'
[void](New-Item -ItemType Directory -Path $packageDir -Force)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$destination = Join-Path $packageDir "501-Seamless-Inventory-Sort-modular-$stamp.zip"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
# CreateNew prevents overwriting an existing test build, even on a timestamp collision.
$stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew)
try {
    $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relative)
        }
    } finally { $zip.Dispose() }
} finally { $stream.Dispose() }

$check = [IO.Compression.ZipFile]::OpenRead($destination)
try {
    $names = @($check.Entries | ForEach-Object { $_.FullName })
    if ($names.Count -ne $files.Count) { throw 'Archive file count mismatch.' }
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        if ($relative -notin $names) { throw "Archive is missing $relative" }
        $entryStream = $check.GetEntry($relative).Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $archiveHash = ([BitConverter]::ToString($sha.ComputeHash($entryStream))).Replace('-', '')
        } finally { $entryStream.Dispose(); $sha.Dispose() }
        if ($archiveHash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
            throw "Archive content mismatch: $relative"
        }
    }
} finally { $check.Dispose() }
Write-Host "MO2 archive verified ($($files.Count) files, gamedata at root): $destination"
Get-FileHash -LiteralPath $destination -Algorithm SHA256
