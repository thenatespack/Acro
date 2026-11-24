// Generated from bloom_down.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: bd7d81531b4ddfd1
// glsl-fnv1a64: ff8fda7b7c369a09

diagnostic(off, derivative_uniformity);

struct type_14 {
    member: vec2<i32>,
    member_1: f32,
    member_2: f32,
}

@group(2) @binding(17) 
var global: sampler;
var<private> global_1: vec4<f32>;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_3: type_14;
var<private> global_4: vec4<f32>;

fn function_() {
    var local: array<vec3<f32>, 36>;
    var local_1: array<vec3<f32>, 5>;
    var local_2: array<f32, 5>;
    var phi_442_: i32;
    var phi_450_: i32;
    var phi_445_: f32;
    var phi_444_: vec3<f32>;
    var phi_443_: i32;
    var phi_446_: f32;
    var local_3: f32;
    var local_4: f32;
    var local_5: f32;
    var local_6: vec3<f32>;
    var local_7: f32;
    var local_8: vec3<f32>;

    let _e59 = global_1;
    phi_442_ = 0i;
    loop {
        let _e65 = phi_442_;
        if (_e65 < 6i) {
            phi_450_ = 0i;
            loop {
                let _e68 = phi_450_;
                if (_e68 < 6i) {
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e75 = global_3.member;
                    let _e77 = textureLoad(global_2, clamp((((vec2<i32>(_e59.xy) * vec2<i32>(2i, 2i)) - vec2<i32>(2i, 2i)) + vec2<i32>(_e68, _e65)), vec2<i32>(0i, 0i), _e75), 0i);
                    let _e80 = global_3.member_2;
                    local[((_e65 * 6i) + _e68)] = min(_e77.xyz, vec3(_e80));
                    phi_450_ = (_e68 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            phi_442_ = (_e65 + 1i);
        }
    }
    let _e87 = local[0i];
    let _e89 = local[1i];
    let _e92 = local[6i];
    let _e95 = local[7i];
    let _e99 = local[2i];
    let _e101 = local[3i];
    let _e104 = local[8i];
    let _e107 = local[9i];
    let _e109 = ((((_e99 + _e101) + _e104) + _e107) * 0.25f);
    let _e111 = local[4i];
    let _e113 = local[5i];
    let _e116 = local[10i];
    let _e119 = local[11i];
    let _e122 = local[7i];
    let _e123 = local[8i];
    let _e126 = local[13i];
    let _e129 = local[14i];
    let _e132 = local[9i];
    let _e133 = local[10i];
    let _e136 = local[15i];
    let _e139 = local[16i];
    let _e143 = local[12i];
    let _e144 = local[13i];
    let _e147 = local[18i];
    let _e150 = local[19i];
    let _e152 = ((((_e143 + _e144) + _e147) + _e150) * 0.25f);
    let _e153 = local[14i];
    let _e154 = local[15i];
    let _e157 = local[20i];
    let _e160 = local[21i];
    let _e162 = ((((_e153 + _e154) + _e157) + _e160) * 0.25f);
    let _e163 = local[16i];
    let _e165 = local[17i];
    let _e168 = local[22i];
    let _e171 = local[23i];
    let _e173 = ((((_e163 + _e165) + _e168) + _e171) * 0.25f);
    let _e174 = local[19i];
    let _e175 = local[20i];
    let _e178 = local[25i];
    let _e181 = local[26i];
    let _e184 = local[21i];
    let _e185 = local[22i];
    let _e188 = local[27i];
    let _e191 = local[28i];
    let _e195 = local[24i];
    let _e196 = local[25i];
    let _e199 = local[30i];
    let _e202 = local[31i];
    let _e205 = local[26i];
    let _e206 = local[27i];
    let _e209 = local[32i];
    let _e212 = local[33i];
    let _e214 = ((((_e205 + _e206) + _e209) + _e212) * 0.25f);
    let _e215 = local[28i];
    let _e217 = local[29i];
    let _e220 = local[34i];
    let _e223 = local[35i];
    local_1 = array<vec3<f32>, 5>(((((((((_e122 + _e123) + _e126) + _e129) * 0.25f) + ((((_e132 + _e133) + _e136) + _e139) * 0.25f)) + ((((_e174 + _e175) + _e178) + _e181) * 0.25f)) + ((((_e184 + _e185) + _e188) + _e191) * 0.25f)) * 0.25f), ((((((((_e87 + _e89) + _e92) + _e95) * 0.25f) + _e109) + _e152) + _e162) * 0.25f), ((((_e109 + ((((_e111 + _e113) + _e116) + _e119) * 0.25f)) + _e162) + _e173) * 0.25f), ((((_e152 + _e162) + ((((_e195 + _e196) + _e199) + _e202) * 0.25f)) + _e214) * 0.25f), ((((_e162 + _e173) + _e214) + ((((_e215 + _e217) + _e220) + _e223) * 0.25f)) * 0.25f));
    local_2 = array<f32, 5>(0.5f, 0.125f, 0.125f, 0.125f, 0.125f);
    phi_445_ = 0f;
    phi_444_ = vec3<f32>(0f, 0f, 0f);
    phi_443_ = 0i;
    loop {
        let _e248 = phi_445_;
        let _e250 = phi_444_;
        let _e252 = phi_443_;
        local_3 = _e248;
        local_4 = _e248;
        local_5 = _e248;
        local_6 = _e250;
        if (_e252 < 5i) {
            let _e255 = global_3.member_1;
            if (_e255 > 0.5f) {
                let _e258 = local_2[_e252];
                let _e260 = local_1[_e252];
                phi_446_ = (_e258 / (1f + dot(_e260, vec3<f32>(0.2126f, 0.7152f, 0.0722f))));
            } else {
                let _e265 = local_2[_e252];
                phi_446_ = _e265;
            }
            let _e267 = phi_446_;
            let _e269 = local_1[_e252];
            local_7 = (_e248 + _e267);
            local_8 = (_e250 + (_e269 * _e267));
            continue;
        } else {
            break;
        }
        continuing {
            let _e292 = local_7;
            phi_445_ = _e292;
            let _e295 = local_8;
            phi_444_ = _e295;
            phi_443_ = (_e252 + 1i);
        }
    }
    let _e275 = local_3;
    let _e277 = local_4;
    let _e279 = local_5;
    let _e282 = local_6;
    let _e283 = (_e282 / vec3<f32>(_e275, _e277, _e279));
    global_4 = vec4<f32>(_e283.x, _e283.y, _e283.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_1 = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
