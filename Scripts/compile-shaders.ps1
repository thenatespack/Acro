# Regenerates every shader under Sources\ and Tests\ from its GLSL (*.vert, *.frag, *.comp), the single source:
# glslc compiles it to SPIR-V (name.vert.spv, for Vulkan), then Scripts\spirv-to-msl.c
# (SPIRV-Cross C API) turns the SPIR-V into MSL (name.vert.metal, for Metal). Same as
# compile-shaders.sh; all outputs are committed, so building the package needs neither tool.
# Requires the Vulkan SDK ($env:VULKAN_SDK: glslc, SPIRV-Cross headers and
# spirv-cross-c-shared) and clang (ships with Swift for Windows).
# Untested so far, like the rest of the Windows setup.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$sdk = $env:VULKAN_SDK
$glslc = if ($sdk) { Join-Path $sdk 'Bin\glslc.exe' } else { 'glslc' }
$shaders = Get-ChildItem Sources, Tests -Recurse -Include *.vert, *.frag, *.comp | Sort-Object FullName
# Vendored shader libraries (the FidelityFX SDK) include their headers relative to their root.
$includes = Get-ChildItem Sources, Tests -Recurse -Directory -Filter FidelityFX | ForEach-Object { "-I$($_.FullName)" }
foreach ($src in $shaders) {
    Write-Host "glslc $($src.FullName) -> $($src.FullName).spv"
    & $glslc --target-env=vulkan1.1 -O @includes $src.FullName -o "$($src.FullName).spv"
    if ($LASTEXITCODE -ne 0) { throw "glslc failed for $($src.Name)" }
}

if (-not $sdk) { throw 'Set VULKAN_SDK: the SPIR-V -> MSL step needs the SDK''s SPIRV-Cross' }
New-Item -ItemType Directory -Force .build | Out-Null
$tool = '.build\spirv-to-msl.exe'
& clang -x c -O2 Scripts\spirv-to-msl.c "-I$(Join-Path $sdk 'Include\spirv_cross')" "-L$(Join-Path $sdk 'Lib')" `
    -lspirv-cross-c-shared -o $tool
if ($LASTEXITCODE -ne 0) { throw 'building spirv-to-msl failed' }
$env:PATH = "$(Join-Path $sdk 'Bin');$env:PATH"  # spirv-cross-c-shared.dll
foreach ($src in $shaders) {
    Write-Host "spirv-to-msl $($src.FullName).spv -> $($src.FullName).metal"
    & $tool "$($src.FullName).spv" "$($src.FullName).metal" $src.FullName
    if ($LASTEXITCODE -ne 0) { throw "spirv-to-msl failed for $($src.Name)" }
    $color0 = "$($src.FullName).color0.metal"
    if ($src.Extension -eq '.frag' -and (Select-String -Path "$($src.FullName).metal" -Pattern '\[\[color\([1-9]\)\]\]' -Quiet)) {
        Write-Host "spirv-to-msl $($src.FullName).spv -> $color0"
        & $tool "$($src.FullName).spv" $color0 $src.FullName 1
        if ($LASTEXITCODE -ne 0) { throw "spirv-to-msl failed for $($src.Name) (color 0 only)" }
    } elseif (Test-Path $color0) {
        Remove-Item $color0
    }
}
