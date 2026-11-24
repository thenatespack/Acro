// Generated from test_dispatch_args.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 751970fb6307d525
// glsl-fnv1a64: aa81c7b4a657b21c

diagnostic(off, derivative_uniformity);

struct type_2 {
    member: array<u32>,
}

struct type_5 {
    member: u32,
}

@group(2) @binding(25) 
var<storage, read_write> global: type_2;
@group(3) @binding(0) 
var<uniform> global_1: type_5;

fn function_() {
    let _e10 = global_1.member;
    global.member[0i] = ((_e10 + 63u) / 64u);
    global.member[1i] = 1u;
    global.member[2i] = 1u;
    return;
}

@compute @workgroup_size(1, 1, 1) 
fn main() {
    function_();
}
