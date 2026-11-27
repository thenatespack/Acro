// Generated from mesh_graph_depth.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 0bd754cb995ec690
// glsl-fnv1a64: f4b32d87c35f8261

diagnostic(off, derivative_uniformity);

struct MaterialGraphValues {
    values: array<vec4<f32>>,
}

struct MaterialGraphPush {
    params: vec4<f32>,
    eye: vec4<f32>,
}

@group(2) @binding(9) 
var baseColorMap: texture_2d<f32>;
@group(2) @binding(17) 
var materialSampler: sampler;
var<private> gUV: vec2<f32>;
@group(2) @binding(10) 
var metallicRoughnessMap: texture_2d<f32>;
@group(2) @binding(11) 
var normalMap: texture_2d<f32>;
@group(2) @binding(12) 
var occlusionMap: texture_2d<f32>;
@group(2) @binding(13) 
var emissiveMap: texture_2d<f32>;
@group(2) @binding(24) 
var<storage> graphValues: MaterialGraphValues;
var<private> gBaseColor: vec3<f32>;
var<private> gVertexColor: vec4<f32>;
var<private> gPosition: vec3<f32>;
var<private> gNormal: vec3<f32>;
var<private> gView: vec3<f32>;
var<private> gTime: f32;
var<private> gOpacity: f32;
var<private> gNormalTS: vec3<f32>;
var<private> gMetallic: f32;
var<private> gRoughness: f32;
var<private> gEmissive: vec3<f32>;
var<private> gOcclusion: f32;
var<private> vUV_1: vec2<f32>;
var<private> vWorldPos_1: vec3<f32>;
var<private> vNormal_1: vec3<f32>;
@group(3) @binding(0) 
var<uniform> graphPush: MaterialGraphPush;
var<private> vColor_1: vec4<f32>;

fn graphSurface_u0028_() {
    var a: vec4<f32>;
    var b: vec4<f32>;
    var c: vec4<f32>;
    var d: vec4<f32>;
    var e: vec4<f32>;
    var v: vec4<f32>;

    let _e39 = gUV;
    let _e40 = textureSample(baseColorMap, materialSampler, _e39);
    a = _e40;
    let _e41 = gUV;
    let _e42 = textureSample(metallicRoughnessMap, materialSampler, _e41);
    b = _e42;
    let _e43 = gUV;
    let _e44 = textureSample(normalMap, materialSampler, _e43);
    c = _e44;
    let _e45 = gUV;
    let _e46 = textureSample(occlusionMap, materialSampler, _e45);
    d = _e46;
    let _e47 = gUV;
    let _e48 = textureSample(emissiveMap, materialSampler, _e47);
    e = _e48;
    let _e51 = graphValues.values[0i];
    v = _e51;
    let _e52 = a;
    let _e54 = gVertexColor;
    let _e57 = v;
    let _e60 = gPosition;
    let _e61 = gNormal;
    let _e63 = gView;
    let _e65 = gTime;
    gBaseColor = (((_e52.xyz * _e54.xyz) * _e57.xyz) + (((_e60 + _e61) + _e63) * _e65));
    let _e69 = a[3u];
    let _e71 = v[3u];
    gOpacity = (_e69 * _e71);
    let _e73 = c;
    gNormalTS = ((_e73.xyz * 2f) - vec3(1f));
    let _e79 = b[2u];
    gMetallic = _e79;
    let _e81 = b[1u];
    gRoughness = _e81;
    let _e82 = e;
    gEmissive = _e82.xyz;
    let _e85 = d[0u];
    gOcclusion = _e85;
    return;
}

fn main_1() {
    let _e33 = vUV_1;
    gUV = _e33;
    let _e34 = vWorldPos_1;
    gPosition = _e34;
    let _e35 = vNormal_1;
    gNormal = normalize(_e35);
    let _e38 = graphPush.eye;
    let _e40 = vWorldPos_1;
    gView = normalize((_e38.xyz - _e40));
    let _e43 = vColor_1;
    gVertexColor = _e43;
    let _e46 = graphPush.params[0u];
    gTime = _e46;
    graphSurface_u0028_();
    let _e47 = gOpacity;
    let _e50 = graphPush.params[2u];
    if (_e47 < _e50) {
        discard;
    }
    return;
}

@fragment 
fn main(@location(2) vUV: vec2<f32>, @location(0) vWorldPos: vec3<f32>, @location(1) vNormal: vec3<f32>, @location(3) vColor: vec4<f32>) {
    vUV_1 = vUV;
    vWorldPos_1 = vWorldPos;
    vNormal_1 = vNormal;
    vColor_1 = vColor;
    main_1();
}
