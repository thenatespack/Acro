# Builds the release binaries and packages them for distribution on Windows (macOS and Linux:
# Scripts/package-release.sh). The Release workflow runs this; it also works locally.
#
#   Scripts\package-release.ps1 [-OutDir Build\release]
#
# Needs VULKAN_SDK, GLFW_DIR and ZLIB_DIR set as for any Windows build (see README). Writes
# <OutDir>\Acro-<version>-windows-x64.zip containing Editor.exe, its import library Editor.lib
# (game modules link against it), the engine's resource folder, and the Swift runtime DLLs and
# zlib1.dll it needs next to it. vulkan-1.dll comes with the GPU driver; GLFW is linked statically.
param([string]$OutDir = "Build\release")
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

$VersionFile = Get-Content Sources\EngineCore\Core\EngineVersion.swift -Raw
if ($VersionFile -notmatch 'static let current = "(\d+\.\d+\.\d+)"') { throw "No engine version in EngineVersion.swift" }
$Version = $Matches[1]
$Name = "Acro-$Version-windows-x64"
$Stage = Join-Path $OutDir $Name
$Products = @('Editor')

foreach ($product in $Products) {
    swift build -c release --product $product
    if ($LASTEXITCODE -ne 0) { throw "swift build failed for $product" }
}
$Bin = (swift build -c release --show-bin-path).Trim()

if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
New-Item -ItemType Directory -Path $Stage | Out-Null
foreach ($product in $Products) {
    Copy-Item (Join-Path $Bin "$product.exe") $Stage
    # Game modules link against the editor's import library (GameModuleBuilder.hostImportLibrary).
    $importLibrary = Join-Path $Bin "$product.lib"
    if (-not (Test-Path $importLibrary)) { throw "$product.lib is missing: Engine must be a .dynamic product on Windows (Package.swift)" }
    Copy-Item $importLibrary $Stage
}
Get-ChildItem $Bin -Directory -Filter 'Acro_*.resources' | Where-Object Name -ne 'Acro_Demo.resources' | ForEach-Object { Copy-Item $_.FullName $Stage -Recurse }
Copy-Item README.md, LICENSE, CHANGELOG.md $Stage

# The Swift runtime: every DLL in the folder that holds swiftCore.dll (on PATH after installing Swift).
$swiftCore = Get-Command swiftCore.dll -ErrorAction SilentlyContinue
if (-not $swiftCore) { throw "swiftCore.dll is not on PATH; can't bundle the Swift runtime" }
Get-ChildItem (Split-Path $swiftCore.Source) -Filter *.dll | ForEach-Object { Copy-Item $_.FullName $Stage }

if ($env:ZLIB_DIR) {
    Get-ChildItem (Join-Path $env:ZLIB_DIR 'bin') -Filter 'z*.dll' | ForEach-Object { Copy-Item $_.FullName $Stage }
}

$Zip = Join-Path $OutDir "$Name.zip"
if (Test-Path $Zip) { Remove-Item $Zip }
Compress-Archive -Path $Stage -DestinationPath $Zip
Write-Output $Zip
