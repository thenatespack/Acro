// Generated from test_fill.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 8d4eedef1ba6b8f0
// glsl-fnv1a64: 897f9be272f7da8d

diagnostic(off, derivative_uniformity);

struct type_4 {
    member: u32,
    member_1: u32,
    member_2: u32,
    member_3: u32,
}

struct type_10 {
    member: array<u32>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_4;
@group(2) @binding(24) 
var<storage, read_write> global_2: type_10;

fn function_() {
    var phi_67_: u32;

    switch bitcast<i32>(0u) {
        default: {
            let _e13 = global[0u];
            let _e15 = global_1.member;
            if (_e13 >= _e15) {
                break;
            }
            let _e18 = global_1.member_3;
            if (_e18 == 0u) {
                phi_67_ = _e13;
            } else {
                let _e22 = global_2.member[_e13];
                phi_67_ = _e22;
            }
            let _e24 = phi_67_;
            let _e26 = global_1.member_1;
            let _e29 = global_1.member_2;
            global_2.member[_e13] = ((_e24 * _e26) + _e29);
            break;
        }
    }
    return;
}

@compute @workgroup_size(64, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
