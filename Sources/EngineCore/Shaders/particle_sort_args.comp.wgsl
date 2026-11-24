// Generated from particle_sort_args.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: f80676eac273c29e
// glsl-fnv1a64: 9035c28833b632d1

diagnostic(off, derivative_uniformity);

struct type_2 {
    member: array<u32>,
}

struct type_7 {
    member: vec4<u32>,
}

@group(2) @binding(30) 
var<storage, read_write> global: type_2;
@group(2) @binding(25) 
var<storage> global_1: type_2;
@group(3) @binding(0) 
var<uniform> global_2: type_7;

fn function_() {
    var phi_215_: u32;
    var local: u32;
    var local_1: u32;
    var local_2: u32;
    var phi_216_: u32;
    var local_3: u32;
    var local_4: u32;
    var phi_218_: u32;
    var local_5: u32;

    let _e23 = global_1.member[1i];
    let _e26 = global_2.member[0u];
    let _e27 = min(_e23, _e26);
    phi_215_ = 2048u;
    loop {
        let _e29 = phi_215_;
        local = _e29;
        local_1 = _e29;
        local_2 = _e29;
        local_3 = _e29;
        local_4 = _e29;
        if (_e29 < _e27) {
            continue;
        } else {
            break;
        }
        continuing {
            phi_215_ = (_e29 << bitcast<u32>(1i));
        }
    }
    let _e36 = local;
    global.member[0i] = _e36;
    global.member[1i] = _e27;
    let _e40 = local_1;
    global.member[4u] = (_e40 / 256u);
    global.member[5u] = 1u;
    global.member[6u] = 1u;
    let _e49 = local_2;
    let _e50 = (_e49 / 2048u);
    global.member[7u] = _e50;
    global.member[8u] = 1u;
    global.member[9u] = 1u;
    phi_216_ = 0u;
    loop {
        let _e58 = phi_216_;
        let _e61 = global_2.member[1u];
        local_5 = _e61;
        if (_e58 < _e61) {
            let _e66 = local_3;
            let _e67 = ((4096u << bitcast<u32>(_e58)) <= _e66);
            let _e68 = (2u * _e58);
            if _e67 {
                let _e71 = local_4;
                phi_218_ = (_e71 / 512u);
            } else {
                phi_218_ = 0u;
            }
            let _e74 = phi_218_;
            let _e75 = (3u * (2u + _e68));
            global.member[(4u + _e75)] = _e74;
            global.member[(5u + _e75)] = 1u;
            global.member[(6u + _e75)] = 1u;
            let _e87 = (3u * (3u + _e68));
            global.member[(4u + _e87)] = select(0u, _e50, _e67);
            global.member[(5u + _e87)] = 1u;
            global.member[(6u + _e87)] = 1u;
            continue;
        } else {
            break;
        }
        continuing {
            phi_216_ = (_e58 + bitcast<u32>(1i));
        }
    }
    let _e100 = local_5;
    let _e105 = (3u * (2u + (2u * _e100)));
    global.member[(4u + _e105)] = ((_e27 + 255u) / 256u);
    global.member[(5u + _e105)] = 1u;
    global.member[(6u + _e105)] = 1u;
    return;
}

@compute @workgroup_size(1, 1, 1) 
fn main() {
    function_();
}
