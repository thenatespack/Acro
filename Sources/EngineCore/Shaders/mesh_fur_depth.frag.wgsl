// Generated from mesh_fur_depth.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 0d5c740a82889215
// glsl-fnv1a64: d56999b0e7f3a554

diagnostic(off, derivative_uniformity);

struct type_11 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_11;
@group(2) @binding(10) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec2<f32>;
var<private> global_5: vec3<f32>;
var<private> global_6: vec3<f32>;

fn function_() {
    var phi_1346_: f32;
    var phi_1345_: f32;
    var phi_1333_: vec3<f32>;
    var phi_1334_: vec3<f32>;
    var phi_1336_: vec3<f32>;
    var phi_1340_: vec3<f32>;
    var phi_1356_: f32;
    var phi_1355_: f32;
    var phi_1348_: f32;
    var phi_1347_: bool;

    let _e63 = global[2u];
    let _e64 = (_e63 > 0.5f);
    let _e65 = select(1.7f, 1f, _e64);
    switch bitcast<i32>(0u) {
        default: {
            let _e68 = global[0u];
            let _e70 = global[3u];
            let _e74 = global_1.member_1[0i];
            let _e77 = global_1.member_1[1i];
            let _e80 = global_1.member_1[2i];
            let _e84 = global_1.member_1[6i][2u];
            phi_1345_ = 1f;
            if (_e84 > 0.5f) {
                let _e86 = global_4;
                let _e87 = textureSample(global_2, global_3, _e86);
                let _e92 = global_1.member_1[6i][3u];
                phi_1346_ = _e87.x;
                if (_e92 > 0.5f) {
                    phi_1346_ = (1f - _e87.x);
                }
                let _e96 = phi_1346_;
                phi_1345_ = _e96;
            }
            let _e98 = phi_1345_;
            if (_e70 > 0.5f) {
                if (_e98 < 0.02f) {
                    phi_1348_ = 1f;
                    phi_1347_ = false;
                    break;
                }
                phi_1355_ = 1f;
            } else {
                if !(_e64) {
                    let _e102 = max(_e74.y, 0.00001f);
                    let _e103 = global_6;
                    let _e104 = normalize(_e103);
                    let _e105 = global_5;
                    phi_1333_ = _e105;
                    if (_e77.x > 0f) {
                        let _e108 = (_e102 * 4f);
                        let _e111 = floor((_e105 / vec3(_e108)));
                        let _e116 = bitcast<vec3<u32>>((vec3<i32>((_e111 + vec3<f32>(31f, 17f, 5f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e124 = (((_e116.x * 1597334677u) ^ (_e116.y * 3812015801u)) ^ (_e116.z * 2798796415u));
                        let _e128 = ((_e124 ^ (_e124 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e131 = (_e128 ^ (_e128 >> bitcast<u32>(13i)));
                        let _e132 = (_e131 * 3266489917u);
                        let _e135 = (_e132 ^ (_e132 >> bitcast<u32>(16i)));
                        let _e136 = (_e135 * 668265263u);
                        let _e151 = (((_e111 + vec3<f32>(0.5f, 0.5f, 0.5f)) + (((vec3<f32>(f32((_e131 & 65535u)), f32((_e135 & 65535u)), f32(((_e136 ^ (_e136 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)) - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.6f)) * _e108);
                        let _e155 = (_e151 - (_e104 * dot((_e151 - _e105), _e104)));
                        phi_1333_ = (_e155 + ((_e105 - _e155) / vec3((1f - min(((_e77.x * _e68) * 0.85f), 0.9f)))));
                    }
                    let _e165 = phi_1333_;
                    let _e168 = floor((_e165 / vec3(_e102)));
                    let _e171 = bitcast<vec3<u32>>((vec3<i32>(_e168) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e179 = (((_e171.x * 1597334677u) ^ (_e171.y * 3812015801u)) ^ (_e171.z * 2798796415u));
                    let _e183 = ((_e179 ^ (_e179 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e186 = (_e183 ^ (_e183 >> bitcast<u32>(13i)));
                    let _e187 = (_e186 * 3266489917u);
                    let _e190 = (_e187 ^ (_e187 >> bitcast<u32>(16i)));
                    let _e191 = (_e190 * 668265263u);
                    let _e202 = (vec3<f32>(f32((_e186 & 65535u)), f32((_e190 & 65535u)), f32(((_e191 ^ (_e191 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e207 = (((_e168 + vec3<f32>(0.5f, 0.5f, 0.5f)) + ((_e202 - vec3<f32>(0.5f, 0.5f, 0.5f)) * 0.5f)) * _e102);
                    if (abs(_e104.y) < 0.9f) {
                        phi_1334_ = cross(_e104, vec3<f32>(0f, 1f, 0f));
                    } else {
                        phi_1334_ = cross(_e104, vec3<f32>(1f, 0f, 0f));
                    }
                    let _e214 = phi_1334_;
                    let _e215 = normalize(_e214);
                    phi_1336_ = _e207;
                    if (_e77.y > 0f) {
                        let _e222 = ((_e68 * 12.566f) + (_e202.x * 6.283f));
                        phi_1336_ = (_e207 + (((_e215 * cos(_e222)) + (cross(_e104, _e215) * sin(_e222))) * ((_e77.y * 0.3f) * _e102)));
                    }
                    let _e233 = phi_1336_;
                    phi_1340_ = _e233;
                    if (_e77.z > 0f) {
                        let _e236 = (_e68 * 4f);
                        let _e238 = (floor(_e236) * 7f);
                        let _e243 = bitcast<vec3<u32>>((vec3<i32>((_e168 + vec3<f32>(_e238, 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e251 = (((_e243.x * 1597334677u) ^ (_e243.y * 3812015801u)) ^ (_e243.z * 2798796415u));
                        let _e255 = ((_e251 ^ (_e251 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e258 = (_e255 ^ (_e255 >> bitcast<u32>(13i)));
                        let _e259 = (_e258 * 3266489917u);
                        let _e262 = (_e259 ^ (_e259 >> bitcast<u32>(16i)));
                        let _e263 = (_e262 * 668265263u);
                        let _e280 = bitcast<vec3<u32>>((vec3<i32>((_e168 + vec3<f32>((_e238 + 7f), 3f, 11f))) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                        let _e288 = (((_e280.x * 1597334677u) ^ (_e280.y * 3812015801u)) ^ (_e280.z * 2798796415u));
                        let _e292 = ((_e288 ^ (_e288 >> bitcast<u32>(15i))) * 2246822519u);
                        let _e295 = (_e292 ^ (_e292 >> bitcast<u32>(13i)));
                        let _e296 = (_e295 * 3266489917u);
                        let _e299 = (_e296 ^ (_e296 >> bitcast<u32>(16i)));
                        let _e300 = (_e299 * 668265263u);
                        phi_1340_ = (_e233 + ((mix((vec3<f32>(f32((_e258 & 65535u)), f32((_e262 & 65535u)), f32(((_e263 ^ (_e263 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), (vec3<f32>(f32((_e295 & 65535u)), f32((_e299 & 65535u)), f32(((_e300 ^ (_e300 >> bitcast<u32>(15i))) & 65535u))) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f)), vec3(smoothstep(0f, 1f, fract(_e236)))) - vec3<f32>(0.5f, 0.5f, 0.5f)) * (((_e77.z * 0.4f) * _e102) * _e68)));
                    }
                    let _e323 = phi_1340_;
                    let _e324 = (_e165 - _e323);
                    let _e327 = (_e324 - (_e104 * dot(_e324, _e104)));
                    let _e333 = ((1f - (_e80.y * _e202.y)) * min(_e98, 1f));
                    if (_e68 > _e333) {
                        phi_1348_ = 1f;
                        phi_1347_ = false;
                        break;
                    }
                    let _e342 = (((mix(_e74.z, _e74.w, (_e68 / max(_e333, 0.001f))) * 0.5f) * _e102) * _e65);
                    if (dot(_e327, _e327) > (_e342 * _e342)) {
                        phi_1348_ = 1f;
                        phi_1347_ = false;
                        break;
                    }
                    phi_1356_ = 1f;
                } else {
                    let _e349 = global_1.member_1[4i][3u];
                    let _e352 = global_4[0u];
                    let _e353 = (_e352 * max(_e349, 1f));
                    let _e356 = global[1u];
                    let _e362 = bitcast<vec3<u32>>((vec3<i32>(vec3<f32>(floor(_e353), floor((_e356 * 65535f)), 7f)) + vec3<i32>(1048576i, 1048576i, 1048576i)));
                    let _e370 = (((_e362.x * 1597334677u) ^ (_e362.y * 3812015801u)) ^ (_e362.z * 2798796415u));
                    let _e374 = ((_e370 ^ (_e370 >> bitcast<u32>(15i))) * 2246822519u);
                    let _e377 = (_e374 ^ (_e374 >> bitcast<u32>(13i)));
                    let _e378 = (_e377 * 3266489917u);
                    let _e387 = (vec3<f32>(f32((_e377 & 65535u)), f32(((_e378 ^ (_e378 >> bitcast<u32>(16i))) & 65535u)), f32()) * vec3<f32>(0.000015259022f, 0.000015259022f, 0.000015259022f));
                    let _e397 = (1f - (_e80.y * _e387.y));
                    if (_e68 > _e397) {
                        phi_1348_ = 1f;
                        phi_1347_ = false;
                        break;
                    }
                    let _e400 = (_e68 / max(_e397, 0.001f));
                    let _e405 = ((mix(_e74.z, _e74.w, _e400) * 0.5f) * _e65);
                    let _e412 = ((1f - smoothstep((_e405 * 0.55f), _e405, abs(((fract(_e353) - 0.5f) + ((_e387.x - 0.5f) * 0.3f))))) * (1f - smoothstep(0.85f, 1f, _e400)));
                    if (_e412 < 0.03f) {
                        phi_1348_ = _e412;
                        phi_1347_ = false;
                        break;
                    }
                    phi_1356_ = _e412;
                }
                let _e415 = phi_1356_;
                phi_1355_ = _e415;
            }
            let _e417 = phi_1355_;
            phi_1348_ = _e417;
            phi_1347_ = true;
            break;
        }
    }
    let _e419 = phi_1348_;
    let _e421 = phi_1347_;
    if (!(_e421) || (_e419 < 0.5f)) {
        discard;
    }
    return;
}

@fragment 
fn main(@location(8) param: vec4<f32>, @location(2) param_1: vec2<f32>, @location(4) param_2: vec3<f32>, @location(10) param_3: vec3<f32>) {
    global = param;
    global_4 = param_1;
    global_5 = param_2;
    global_6 = param_3;
    function_();
}
