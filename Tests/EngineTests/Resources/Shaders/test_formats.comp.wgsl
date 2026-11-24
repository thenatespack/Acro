// Generated from test_formats.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 69710e5ebc8d30a6
// glsl-fnv1a64: 226ab1351aacc825

diagnostic(off, derivative_uniformity);

struct type_4 {
    member: vec2<u32>,
    member_1: u32,
}

struct type_24 {
    member: array<f32>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_4;
@group(2) @binding(32) 
var global_2: texture_storage_2d<r8unorm,read_write>;
@group(2) @binding(33) 
var global_3: texture_storage_2d<r16float,write>;
@group(2) @binding(34) 
var global_4: texture_storage_2d<rg16float,write>;
@group(2) @binding(35) 
var global_5: texture_storage_2d<r32float,write>;
@group(2) @binding(24) 
var<storage, read_write> global_6: type_24;
@group(2) @binding(9) 
var global_7: texture_2d<f32>;
@group(2) @binding(10) 
var global_8: texture_2d<f32>;
@group(2) @binding(11) 
var global_9: texture_2d<f32>;
@group(2) @binding(12) 
var global_10: texture_2d<f32>;

fn function_() {
    switch bitcast<i32>(0u) {
        default: {
            let _e29 = global;
            let _e30 = _e29.xy;
            let _e32 = global_1.member;
            if any((_e30 >= _e32)) {
                break;
            }
            let _e38 = global_1.member[0u];
            let _e41 = ((_e29.y * _e38) + _e29.x);
            let _e42 = f32(_e41);
            let _e44 = global_1.member_1;
            if (_e44 == 0u) {
                let _e46 = bitcast<vec2<i32>>(_e30);
                textureStore(global_2, _e46, vec4((_e42 * 0.003921569f)));
                textureStore(global_3, _e46, vec4((_e42 * 0.5f)));
                textureStore(global_4, _e46, vec4<f32>(-(_e42), (_e42 * 0.25f), 0f, 0f));
                textureStore(global_5, _e46, vec4(((_e42 * 1000f) + 0.125f)));
            } else {
                let _e57 = (_e41 * 6u);
                let _e58 = bitcast<vec2<i32>>(_e30);
                let _e59 = textureLoad(global_7, _e58, 0i);
                global_6.member[_e57] = _e59.x;
                let _e64 = textureLoad(global_8, _e58, 0i);
                global_6.member[(_e57 + 1u)] = _e64.x;
                let _e69 = textureLoad(global_9, _e58, 0i);
                global_6.member[(_e57 + 2u)] = _e69.x;
                let _e74 = textureLoad(global_9, _e58, 0i);
                global_6.member[(_e57 + 3u)] = _e74.y;
                let _e79 = textureLoad(global_10, _e58, 0i);
                global_6.member[(_e57 + 4u)] = _e79.x;
                let _e84 = textureLoad(global_2, _e58);
                global_6.member[(_e57 + 5u)] = _e84.x;
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
