// Generated from test_depth_read.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 35f7e5e8274a9be9
// glsl-fnv1a64: 874aa7d4e42f6396

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: u32,
    member_1: u32,
}

struct type_11 {
    member: array<f32>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_5;
@group(2) @binding(24) 
var<storage, read_write> global_2: type_11;
@group(2) @binding(9) 
var global_3: texture_2d<f32>;
@group(2) @binding(17) 
var global_4: sampler;

fn function_() {
    var phi_39_: bool;

    switch bitcast<i32>(0u) {
        default: {
            let _e12 = global;
            let _e16 = global_1.member;
            let _e17 = (_e12.x >= _e16);
            phi_39_ = _e17;
            if !(_e17) {
                let _e21 = global_1.member_1;
                phi_39_ = (_e12.y >= _e21);
            }
            let _e24 = phi_39_;
            if _e24 {
                break;
            }
            let _e29 = textureLoad(global_3, bitcast<vec2<i32>>(_e12.xy), 0i);
            global_2.member[((_e12.y * _e16) + _e12.x)] = _e29.x;
            break;
        }
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
