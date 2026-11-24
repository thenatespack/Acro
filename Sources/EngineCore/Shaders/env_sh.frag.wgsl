// Generated from env_sh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: af5b83d3820d2e9d
// glsl-fnv1a64: 1e55f120453b1744

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: vec2<i32>,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_12;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;

fn function_() {
    var local: array<f32, 9>;
    var phi_413_: vec3<f32>;
    var phi_410_: i32;
    var phi_415_: vec3<f32>;
    var phi_414_: i32;
    var local_1: vec3<f32>;
    var phi_411_: f32;
    var local_2: vec3<f32>;
    var local_3: vec3<f32>;
    var local_4: i32;

    let _e28 = global[0u];
    let _e29 = i32(_e28);
    let _e31 = global_1.member;
    let _e32 = vec2<f32>(_e31);
    phi_413_ = vec3<f32>(0f, 0f, 0f);
    phi_410_ = 0i;
    loop {
        let _e36 = phi_413_;
        let _e38 = phi_410_;
        let _e41 = global_1.member[1u];
        local_2 = _e36;
        if (_e38 < _e41) {
            let _e43 = f32(_e38);
            let _e48 = (_e38 + 1i);
            local_4 = _e48;
            phi_415_ = vec3<f32>(0f, 0f, 0f);
            phi_414_ = 0i;
            loop {
                let _e56 = phi_415_;
                let _e58 = phi_414_;
                let _e61 = global_1.member[0u];
                local_1 = _e56;
                if (_e58 < _e61) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e66 = ((vec2<f32>(f32(_e58), _e43) + vec2<f32>(0.5f, 0.5f)) / _e32);
                    let _e69 = ((_e66.x - 0.5f) * 6.2831855f);
                    let _e71 = (_e66.y * 3.1415927f);
                    let _e72 = sin(_e71);
                    let _e74 = (_e72 * sin(_e69));
                    let _e75 = cos(_e71);
                    let _e78 = (-(_e72) * cos(_e69));
                    let _e82 = (1.092548f * _e74);
                    local = array<f32, 9>(0.282095f, (0.488603f * _e75), (0.488603f * _e78), (0.488603f * _e74), (_e82 * _e75), ((1.092548f * _e75) * _e78), (0.315392f * (((3f * _e78) * _e78) - 1f)), (_e82 * _e78), (0.546274f * ((_e74 * _e74) - (_e75 * _e75))));
                    let _e97 = textureLoad(global_2, vec2<i32>(_e58, _e38), 0i);
                    let _e100 = local[_e29];
                    phi_415_ = (_e56 + (_e97.xyz * _e100));
                    phi_414_ = (_e58 + 1i);
                }
            }
            let _e105 = local_1;
            local_3 = (_e36 + (_e105 * ((6.2831855f / _e32.x) * (cos(((_e43 / _e32.y) * 3.1415927f)) - cos(((f32(_e48) / _e32.y) * 3.1415927f))))));
            continue;
        } else {
            break;
        }
        continuing {
            let _e122 = local_3;
            phi_413_ = _e122;
            let _e125 = local_4;
            phi_410_ = _e125;
        }
    }
    if (_e29 == 0i) {
        phi_411_ = 1f;
    } else {
        phi_411_ = select(0.25f, 0.6666667f, (_e29 < 4i));
    }
    let _e112 = phi_411_;
    let _e114 = local_2;
    let _e115 = (_e114 * _e112);
    global_4 = vec4<f32>(_e115.x, _e115.y, _e115.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
