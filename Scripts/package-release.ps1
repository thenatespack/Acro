# Builds the release binaries and packages them for distribution on Windows (macOS and Linux:
# Scripts/package-release.sh). The Release workflow runs this; it also works locally.
#
#   Scripts\package-release.ps1 [-OutDir Build\release] [-Msi]
#
# Needs VULKAN_SDK, GLFW_DIR and ZLIB_DIR set as for any Windows build (see README). Writes
# <OutDir>\Acro-<version>-windows-x64.zip containing Editor.exe, its import library Editor.lib
# (game modules link against it), the engine's resource folder, and the Swift runtime DLLs and
# zlib1.dll it needs next to it. vulkan-1.dll comes with the GPU driver; GLFW is linked statically.
# -Msi also writes <OutDir>\Acro-<version>-windows-x64.msi, an installer of the same files with
# Start Menu and desktop shortcuts (Windows\Installer\Acro.wxs; needs the WiX v5 `wix` tool:
# `dotnet tool install --global wix --version 5.0.2`).
param([string]$OutDir = "Build\release", [switch]$Msi)
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
# Resource bundles (shaders, fonts). SwiftPM names them Acro_<Target>.bundle on Windows and
# Acro_<Target>.resources on Linux; Bundle.module looks for them next to the exe and traps if
# EngineCore's (the engine's shaders and fonts) is missing, so the editor would exit at once.
Get-ChildItem $Bin -Directory | Where-Object { $_.Name -match '^Acro_(.+)\.(bundle|resources)$' -and $Matches[1] -ne 'Demo' } |
    ForEach-Object { Copy-Item $_.FullName $Stage -Recurse }
if (-not (Get-ChildItem $Stage -Directory | Where-Object Name -match '^Acro_EngineCore\.(bundle|resources)$')) {
    throw "The engine's resource bundle (Acro_EngineCore.bundle) is missing from $Bin"
}
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

if ($Msi) {
    $Installer = Join-Path $OutDir "$Name.msi"
    if (Test-Path $Installer) { Remove-Item $Installer }
    wix build (Join-Path $Root 'Windows\Installer\Acro.wxs') -arch x64 -d "Version=$Version" -d "StageDir=$Stage" -o $Installer
    if ($LASTEXITCODE -ne 0) { throw "wix build failed" }
    Write-Output $Installer
}
