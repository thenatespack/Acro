# Compiles every GLSL shader (*.vert, *.frag) under Sources\ to SPIR-V next to it.
# Requires glslc (ships with the Vulkan SDK; $env:VULKAN_SDK\Bin).
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$glslc = if ($env:VULKAN_SDK) { Join-Path $env:VULKAN_SDK 'Bin\glslc.exe' } else { 'glslc' }
Get-ChildItem Sources -Recurse -Include *.vert, *.frag | ForEach-Object {
    Write-Host "glslc $($_.FullName) -> $($_.FullName).spv"
    & $glslc --target-env=vulkan1.1 -O $_.FullName -o "$($_.FullName).spv"
    if ($LASTEXITCODE -ne 0) { throw "glslc failed for $($_.Name)" }
}
