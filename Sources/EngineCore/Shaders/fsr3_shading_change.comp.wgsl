// Generated from fsr3_shading_change.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 7d660e3a16fb83a7
// glsl-fnv1a64: 895ddad126b5d2b3

diagnostic(off, derivative_uniformity);

struct type_10 {
    member: vec2<i32>,
    member_1: vec2<i32>,
    member_2: vec2<i32>,
    member_3: vec2<i32>,
    member_4: vec4<f32>,
    member_5: vec2<f32>,
    member_6: vec2<f32>,
    member_7: vec2<f32>,
    member_8: f32,
    member_9: f32,
    member_10: f32,
    member_11: f32,
    member_12: f32,
    member_13: f32,
    member_14: f32,
    member_15: f32,
    member_16: f32,
    member_17: f32,
    member_18: f32,
    member_19: vec2<u32>,
}

@group(3) @binding(0) 
var<uniform> global: type_10;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(10) 
var global_2: texture_2d<f32>;
@group(2) @binding(11) 
var global_3: texture_2d<f32>;
@group(2) @binding(17) 
var global_4: sampler;
@group(2) @binding(32) 
var global_5: texture_storage_2d<r8unorm,write>;
var<private> global_6: vec3<u32>;

fn function_() {
    var local: array<f32, 3>;
    var local_1: array<f32, 3>;
    var phi_652_: i32;
    var phi_656_: vec2<f32>;
    var phi_654_: f32;
    var phi_653_: i32;
    var phi_658_: f32;
    var local_2: f32;
    var local_3: f32;

    let _e22 = global_6;
    let _e23 = _e22.xy;
    let _e24 = bitcast<vec2<i32>>(_e23);
    let _e26 = global.member;
    let _e27 = vec2<f32>(_e26);
    let _e29 = vec2<i32>((_e27 * 0.5f));
    if all((_e23 < bitcast<vec2<u32>>(_e29))) {
        let _e35 = vec2<f32>(_e29);
        let _e38 = global.member_5;
        let _e41 = textureDimensions(global_1, 0i);
        let _e48 = (max(vec2<f32>(0.5f, 0.5f), min(((((vec2<f32>(_e24) + vec2<f32>(0.5f, 0.5f)) / _e35) + (_e38 / _e27)) * _e35), (_e35 - vec2<f32>(0.5f, 0.5f)))) / vec2<f32>(vec2<i32>(_e41)));
        phi_652_ = 0i;
        loop {
            let _e50 = phi_652_;
            if (_e50 < 3i) {
                let _e52 = bitcast<u32>(_e50);
                switch bitcast<i32>(0u) {
                    default: {
                        if (_e52 == 0u) {
                            let _e55 = textureSampleLevel(global_1, global_4, _e48, 0f);
                            phi_656_ = _e55.xy;
                            break;
                        }
                        if (_e52 == 1u) {
                            let _e58 = textureSampleLevel(global_2, global_4, _e48, 0f);
                            phi_656_ = _e58.xy;
                            break;
                        }
                        let _e60 = textureSampleLevel(global_3, global_4, _e48, 0f);
                        phi_656_ = _e60.xy;
                        break;
                    }
                }
                let _e63 = phi_656_;
                local_1[_e50] = abs((_e63.x * _e63.y));
                continue;
            } else {
                break;
            }
            continuing {
                phi_652_ = (_e50 + 1i);
            }
        }
        let _e70 = local_1;
        local = _e70;
        phi_654_ = 0f;
        phi_653_ = 0i;
        loop {
            let _e72 = phi_654_;
            let _e74 = phi_653_;
            local_2 = _e72;
            if (_e74 < 3i) {
                let _e77 = local[_e74];
                phi_658_ = _e72;
                if (_e77 > 0f) {
                    let _e79 = local[_e74];
                    phi_658_ = max(_e72, _e79);
                }
                let _e82 = phi_658_;
                local_3 = _e82;
                continue;
            } else {
                break;
            }
            continuing {
                let _e97 = local_3;
                phi_654_ = _e97;
                phi_653_ = (_e74 + 1i);
            }
        }
        let _e85 = local_2;
        let _e87 = textureDimensions(global_5);
        if all((_e23 < bitcast<vec2<u32>>(vec2<i32>(_e87)))) {
            textureStore(global_5, _e24, vec4<f32>(clamp(_e85, 0f, 1f), 0f, 0f, 0f));
        }
    }
    return;
}

@compute @workgroup_size(8, 8, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_6 = param;
    function_();
}
