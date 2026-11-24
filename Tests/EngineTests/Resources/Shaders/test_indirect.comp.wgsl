// Generated from test_indirect.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 54281fc0d25ce886
// glsl-fnv1a64: c9fc2abcc54a40d5

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: f32,
    member_1: f32,
}

struct type_12 {
    member: array<vec4<f32>>,
}

struct type_17 {
    member: array<u32>,
}

@group(3) @binding(0) 
var<uniform> global: type_5;
@group(2) @binding(24) 
var<storage, read_write> global_1: type_12;
@group(2) @binding(25) 
var<storage, read_write> global_2: type_17;

fn function_() {
    var local: array<vec2<f32>, 6>;
    var phi_85_: i32;

    let _e17 = global.member;
    let _e18 = vec2<f32>(_e17, -1f);
    let _e20 = global.member_1;
    let _e22 = vec2<f32>(_e20, 1f);
    local = array<vec2<f32>, 6>(_e18, vec2<f32>(_e20, -1f), _e22, _e18, _e22, vec2<f32>(_e17, 1f));
    phi_85_ = 0i;
    loop {
        let _e26 = phi_85_;
        if (_e26 < 6i) {
            continue;
        } else {
            break;
        }
        continuing {
            let _e29 = local[_e26];
            global_1.member[_e26] = vec4<f32>(_e29.x, _e29.y, 0.5f, 1f);
            phi_85_ = (_e26 + 1i);
        }
    }
    global_2.member[0i] = 6u;
    global_2.member[1i] = 1u;
    global_2.member[2i] = 0u;
    global_2.member[3i] = 0u;
    return;
}

@compute @workgroup_size(1, 1, 1) 
fn main() {
    function_();
}
