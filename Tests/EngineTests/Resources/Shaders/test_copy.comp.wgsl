// Generated from test_copy.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 34f8b0b89d3f75cb
// glsl-fnv1a64: 3d7264c8dd164a83

diagnostic(off, derivative_uniformity);

struct type_4 {
    member: vec2<u32>,
}

struct type_13 {
    member: array<vec4<f32>>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_4;
@group(2) @binding(24) 
var<storage, read_write> global_2: type_13;
@group(2) @binding(9) 
var global_3: texture_2d<f32>;

fn function_() {
    switch bitcast<i32>(0u) {
        default: {
            let _e10 = global;
            let _e11 = _e10.xy;
            let _e13 = global_1.member;
            if any((_e11 >= _e13)) {
                break;
            }
            let _e19 = global_1.member[0u];
            let _e24 = textureLoad(global_3, bitcast<vec2<i32>>(_e11), 0i);
            global_2.member[((_e10.y * _e19) + _e10.x)] = _e24;
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
