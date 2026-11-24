// Generated from test_image.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: fd508b86021ef62f
// glsl-fnv1a64: cbdd1b91842cdcb1

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: vec2<i32>,
    member_1: u32,
}

struct type_19 {
    member: array<u32>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_7;
@group(2) @binding(32) 
var global_2: texture_storage_2d<rgba16float,read_write>;
@group(2) @binding(9) 
var global_3: texture_2d<f32>;
@group(2) @binding(17) 
var global_4: sampler;
@group(2) @binding(24) 
var<storage, read_write> global_5: type_19;

fn function_() {
    var phi_40_: bool;

    switch bitcast<i32>(0u) {
        default: {
            let _e16 = global;
            let _e18 = bitcast<vec2<i32>>(_e16.xy);
            let _e22 = global_1.member[0u];
            let _e23 = (_e18.x >= _e22);
            phi_40_ = _e23;
            if !(_e23) {
                let _e28 = global_1.member[1u];
                phi_40_ = (_e18.y >= _e28);
            }
            let _e31 = phi_40_;
            if _e31 {
                break;
            }
            let _e33 = global_1.member_1;
            if (_e33 == 0u) {
                textureStore(global_2, _e18, vec4<f32>((f32(_e18.x) * 0.015625f), (f32(_e18.y) * 0.015625f), 0.25f, 1f));
            } else {
                let _e41 = textureLoad(global_3, _e18, 0i);
                global_5.member[((_e18.y * _e22) + _e18.x)] = pack4x8unorm(_e41);
            }
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
