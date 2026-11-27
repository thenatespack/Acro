// Skin and eye shading (SKIN_SHADING: mesh_skin.frag, mesh_skin_probes.frag), included by
// mesh_surface.glsl just before main. The CPU side is MaterialSkin.swift (`SkinPushConstants`,
// `SubsurfaceKernel`, `MeshGeometry.eyeball`) and SceneRenderer+Subsurface.swift. Not compiled on
// its own; rerun Scripts/compile-shaders.sh after editing it.
//
// Skin (Material.subsurface / specularLobes / detailNormal):
// - Diffuse: Lambert with the detail normal when the screen-space pass scatters it afterwards
//   (Jimenez et al. 2015, separable subsurface scattering: subsurface_blur.frag). The pixel then
//   writes its specular luminance into alpha as -(1 + s), so the pass can take the diffuse light
//   apart from the (near-white) specular without a second render target: diffuse = rgb - s.
//   Otherwise (WebGL 2, low quality, ENGINE_SSS=preintegrated) Penner's pre-integrated skin
//   shading (GPU Pro 2, 2011): the clamped cosine convolved with the skin profile around a ring
//   of the surface's curvature, computed in closed form here with 5-point Gauss-Hermite
//   quadrature per Gaussian (no lookup texture: no extra binding), plus normal "bending" per
//   channel (red follows the smooth geometric normal, blue the detailed one).
// - Transmission (Jimenez et al. 2010, "Real-Time Realistic Skin Translucency"): light through
//   thin parts from behind. The thickness comes from the shadow map: comparison-only lookups at
//   points stepped from just inside the surface toward the light (a ladder of distances) give
//   how much of d'Eon's transmittance profile T(s) gets through: sum (T(t[i-1]) - T(t[i])) x
//   lit(t[i]). Lights without a shadow map guess the thickness from the curvature.
// - Specular: two GGX lobes (roughness x lobes.x and x lobes.y, mixed by lobes.z).
// - Detail normal: pores (sharpened value noise) and fine creases in the mesh's own space, as a
//   height whose analytic gradient becomes a surface gradient (Mikkelsen 2010) through the
//   screen derivatives of the object and world positions; faded out below a pixel.
//
// Eye (Material.eye, mode skinPush.scatter.z = 1; Jimenez, "Next-Generation Character Rendering",
// GDC 2013): the eyeball's UVs give its own frame (MeshGeometry.eyeball: uv = 0.5 + 0.5 (x, y)
// on the front half, tangents along its +X). The view ray refracts at the cornea (IOR 1.336) down
// to the iris plane; the iris is procedural (radial fibers, crypts, collarette, pupil, darker
// limbal ring) and lit from the gaze direction; the sclera is soft-lit (wrap), slightly blue-grey
// with veins toward the corners; a wet GGX highlight and the environment reflect off the whole
// surface; occlusion darkens the corners and under the upper lid.

layout(push_constant) uniform SkinPush {
    vec4 subsurface;  // rgb: falloff, w: strength (0: none)
    vec4 scatter;     // x: radius (m), y: transmission, z: 1 eye, w: 1 the screen pass scatters this pixel
    vec4 lobes;       // x, y: lobe roughness factors, z: second lobe weight, w: 1 with two lobes
    vec4 detail;      // x: strength, y: frequency (per meter of the mesh's space)
    vec4 iris;        // eye: rgb iris color, w: iris radius / eyeball radius
    vec4 sclera;      // eye: rgb sclera color, w: pupil radius / iris radius
    vec4 eye;         // eye: x limbal ring, y veins, z iris depth (eyeball radii)
} skinPush;

// Jimenez's channel strengths at strength 1 (`MaterialSubsurface.skinStrength`).
const vec3 SKIN_STRENGTH = vec3(0.48, 0.41, 0.28);

// d'Eon's transmittance profile for skin, s in millimeters (Jimenez 2010).
vec3 skinTransmittanceProfile(float s) {
    float s2 = -s * s;
    return vec3(0.233, 0.455, 0.649) * exp(s2 / 0.0064) + vec3(0.1, 0.336, 0.344) * exp(s2 / 0.0484)
        + vec3(0.118, 0.198, 0.0) * exp(s2 / 0.187) + vec3(0.113, 0.007, 0.007) * exp(s2 / 0.567)
        + vec3(0.358, 0.004, 0.0) * exp(s2 / 1.99) + vec3(0.078, 0.0, 0.0) * exp(s2 / 7.41);
}

// The profile coordinate (mm) of light that crossed `meters` of skin: transmission lets it
// reach further.
float skinProfileDistance(float meters) {
    return meters * 1000.0 / (0.6 + 6.0 * skinPush.scatter.y);
}

const float SKIN_LADDER[4] = float[4](0.002, 0.005, 0.01, 0.02);

// The sun's light through the surface at p (normal ng, toward the light l): the transmittance
// profile integrated over the thickness the shadow cascade sees (see the top of this file).
vec3 skinSunTransmittance(vec3 p, vec3 ng, vec3 l, float guessThickness) {
    int count = int(frame.shadowInfo.x);
    if (frame.lightColor.w < 0.5 || count == 0) return skinTransmittanceProfile(skinProfileDistance(guessThickness));
    float depth = dot(frame.shadowDepthRow.xyz, p) + frame.shadowDepthRow.w;
    int c = 0;
    while (c < count - 1 && depth > frame.cascadeSplits[c]) c++;
    if (depth > frame.cascadeSplits[c]) return skinTransmittanceProfile(skinProfileDistance(guessThickness));
    // Start inside the surface (Jimenez shrinks by a few millimeters, past the shadow bias and the
    // map's stair steps at grazing angles), then step toward the light.
    vec3 inside = p - ng * max(frame.cascadeNormalOffsets[c] * 2.0, 0.004);
    // Thicker than the last step (most of a head): nothing gets through, one lookup.
    if (cascadeShadow(c, inside + l * SKIN_LADDER[3]) <= 0.0) return vec3(0.0);
    vec3 previous = vec3(1.0);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        vec3 t = skinTransmittanceProfile(skinProfileDistance(SKIN_LADDER[i]));
        sum += (previous - t) * cascadeShadow(c, inside + l * SKIN_LADDER[i]);
        previous = t;
    }
    return sum;
}

// The same for clustered light `index` (direction toward it `l`): its own shadow map, or the
// guess when it has none.
vec3 skinLocalTransmittance(uint index, vec3 p, vec3 ng, vec3 l, float guessThickness) {
    if (index >= uint(frame.shadowInfo.z + frame.shadowInfo.w)) return skinTransmittanceProfile(skinProfileDistance(guessThickness));
    vec3 inside = p - ng * 0.004;
    if (localShadow(index, inside + l * SKIN_LADDER[3], ng, l) <= 0.0) return vec3(0.0);
    vec3 previous = vec3(1.0);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        vec3 t = skinTransmittanceProfile(skinProfileDistance(SKIN_LADDER[i]));
        sum += (previous - t) * localShadow(index, inside + l * SKIN_LADDER[i], ng, l);
        previous = t;
    }
    return sum;
}

// Penner's pre-integrated diffuse: the clamped cosine averaged over the angles x ~ N(0, sigma²)
// light arrives from along a ring of radius 1 / curvature (x / curvature away), per channel, with
// 5-point Gauss-Hermite quadrature. cos(theta ± x_i) = cos theta cos x_i ∓ sin theta sin x_i, and
// cos x_i / sin x_i depend only on the pixel (its curvature), so skinPrepareRing computes them
// once and each light costs a few multiply-adds (no lookup texture, so no extra binding). The
// scattered part of the profile is two Gaussians (d'Eon's five merged: 0.52 mm and 1.72 mm,
// weights 0.43 / 0.57), each channel widened by its falloff; one profile millimeter is radius / 2
// in the world, as in the screen pass.
vec3 skRingC1[2], skRingS1[2], skRingC2[2], skRingS2[2];

void skinPrepareRing(float curvature) {
    vec3 scale = skinPush.subsurface.rgb * (skinPush.scatter.x * 0.5) * curvature;
    const float x1 = 1.3556262, x2 = 2.8569700;
    for (int k = 0; k < 2; k++) {
        vec3 sigma = scale * (k == 0 ? 0.52 : 1.72);
        skRingC1[k] = cos(sigma * x1);
        skRingS1[k] = sin(sigma * x1);
        skRingC2[k] = cos(sigma * x2);
        skRingS2[k] = sin(sigma * x2);
    }
}

vec3 skinPreintegrated(vec3 NoL, vec3 strength) {
    const float w0 = 0.5333333, w1 = 0.2220759, w2 = 0.0112574;
    vec3 c = clamp(NoL, -1.0, 1.0);
    vec3 s = sqrt(max(1.0 - c * c, vec3(0.0)));
    vec3 scattered = vec3(0.0);
    for (int k = 0; k < 2; k++) {
        vec3 r = w0 * max(c, vec3(0.0));
        r += w1 * (max(c * skRingC1[k] - s * skRingS1[k], vec3(0.0)) + max(c * skRingC1[k] + s * skRingS1[k], vec3(0.0)));
        r += w2 * (max(c * skRingC2[k] - s * skRingS2[k], vec3(0.0)) + max(c * skRingC2[k] + s * skRingS2[k], vec3(0.0)));
        scattered += r * (k == 0 ? 0.43 : 0.57);
    }
    return mix(max(NoL, vec3(0.0)), scattered, strength);
}

// Value noise with its analytic gradient (Quilez), from edgeHash: (value 0...1, d/dp).
vec4 skinNoised(vec3 x) {
    vec3 i = floor(x);
    vec3 w = x - i;
    vec3 u = w * w * (3.0 - 2.0 * w);
    vec3 du = 6.0 * w * (1.0 - w);
    float a = edgeHash(i), b = edgeHash(i + vec3(1, 0, 0)), c = edgeHash(i + vec3(0, 1, 0)), d = edgeHash(i + vec3(1, 1, 0));
    float e = edgeHash(i + vec3(0, 0, 1)), f = edgeHash(i + vec3(1, 0, 1)), g = edgeHash(i + vec3(0, 1, 1)), h = edgeHash(i + vec3(1, 1, 1));
    float k1 = b - a, k2 = c - a, k3 = e - a, k4 = a - b - c + d, k5 = a - c - e + g, k6 = a - b - e + f, k7 = -a + b + c - d + e - f - g + h;
    float value = a + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z;
    vec3 grad = du * vec3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z,
                          k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x,
                          k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y);
    return vec4(value, grad);
}

// `n` bumped by the procedural pores and creases (see the top of this file).
vec3 skinDetailNormal(vec3 n) {
    float frequency = skinPush.detail.y;
    float strength = skinPush.detail.x;
    if (strength <= 0.0 || frequency <= 0.0) return n;
    vec3 dodx = dFdx(vObjectPos), dody = dFdy(vObjectPos);
    float footprint = max(length(dodx), length(dody)) * frequency;
    float fade = 1.0 - smoothstep(0.25, 0.7, footprint);
    if (fade <= 0.0) return n;
    vec3 p = vObjectPos * frequency;
    // Pores: pits where the noise is low (height -(1 - v)^4); creases: a finer, softer octave.
    vec4 pores = skinNoised(p);
    float k = 1.0 - pores.x;
    vec3 gradient = 4.0 * k * k * k * pores.yzw;
    vec4 fine = skinNoised(p * vec3(2.9, 2.3, 2.6) + vec3(13.1, 7.7, 3.3));
    gradient += 0.35 * vec3(2.9, 2.3, 2.6) * fine.yzw * (1.0 - smoothstep(0.2, 0.5, footprint * 2.9));
    // Height in meters is 0.25 x strength / frequency x the noise: its gradient in object space.
    gradient *= 0.25 * strength * fade;
    float dhdx = dot(gradient, dodx), dhdy = dot(gradient, dody);
    vec3 dpdx = dFdx(vWorldPos), dpdy = dFdy(vWorldPos);
    vec3 r1 = cross(dpdy, n), r2 = cross(n, dpdx);
    float det = dot(dpdx, r1);
    if (abs(det) < 1e-20) return n;
    vec3 surfaceGradient = sign(det) * (dhdx * r1 + dhdy * r2);
    return normalize(abs(det) * n - surfaceGradient);
}

// GGX specular x NoL of one or two lobes (pi-scaled like mesh_surface.glsl's BRDF).
vec3 skinSpecular(vec3 n, vec3 v, vec3 l, vec3 f0, float roughness, float NoV) {
    vec3 h = normalize(l + v);
    float NoL = clamp(dot(n, l), 0.0, 1.0);
    if (NoL <= 0.0) return vec3(0.0);
    float NoH = clamp(dot(n, h), 0.0, 1.0);
    vec3 F = fresnelSchlick(f0, clamp(dot(v, h), 0.0, 1.0));
    float r0 = clamp(roughness * skinPush.lobes.x, 0.045, 1.0);
    float a0 = r0 * r0;
    float lobe = distributionGGX(NoH, a0) * visibilitySmithGGXCorrelated(NoV, NoL, a0);
    if (skinPush.lobes.w > 0.5) {
        float r1 = clamp(roughness * skinPush.lobes.y, 0.045, 1.0);
        float a1 = r1 * r1;
        lobe = mix(lobe, distributionGGX(NoH, a1) * visibilitySmithGGXCorrelated(NoV, NoL, a1), skinPush.lobes.z);
    }
    return F * (lobe * PI * NoL);
}

// The ambient light (irradiance at n, the reflection along r for `roughness`), with the probes.
void skinAmbient(vec3 n, vec3 r, float roughness, vec3 v, out vec3 irradiance, out vec3 reflected) {
    if (frame.environment.x > 0.5) {
        irradiance = environmentIrradiance(n);
        reflected = environmentRadiance(r, roughness);
    } else {
        irradiance = hemisphere(n);
        reflected = mix(hemisphere(r), irradiance, roughness);
    }
#ifdef LIGHT_PROBES
    if (frame.probes.y > 0.5) irradiance = probeIrradiance(irradiance, vWorldPos, n, v);
    if (frame.probes.x > 0.5) reflected = probeReflection(reflected, vWorldPos, r, roughness);
#endif
}

vec2 skinEnvironmentBRDF(float NoV, float roughness) {
    return frame.environment.x > 0.5 ? environmentBRDFTable(NoV, roughness) : environmentBRDF(NoV, roughness);
}

// Skin: returns the lit color; `specularOut` gets the specular part (for the screen pass).
vec3 skinShade(vec3 albedo, vec3 n, vec3 v, vec3 l, vec3 ng, vec3 light, float shadow, float ao, float roughness,
               float metallic, bool receivesShadows, out vec3 specularOut) {
    vec3 geometric = normalize(vNormal) * (gl_FrontFacing ? 1.0 : -1.0);
    n = skinDetailNormal(n);
    float NoV = max(dot(n, v), 1e-4);
    vec3 diffuseColor = albedo * (1.0 - metallic);
    // Skin's specular reflectance is about 0.028 (IOR 1.4); metals keep theirs.
    vec3 f0 = mix(vec3(0.028), albedo, metallic);
    vec3 strength = clamp(SKIN_STRENGTH * skinPush.subsurface.w, 0.0, 1.0);
    bool scatters = skinPush.subsurface.w > 0.0 && skinPush.scatter.x > 0.0;
    bool screen = skinPush.scatter.w > 0.5;
    bool preintegrated = scatters && !screen;
    float transmission = scatters ? skinPush.scatter.y : 0.0;
    // Curvature (1/m) from how fast the smooth normal turns across the pixel.
    float curvature = 0.0;
    if (preintegrated || transmission > 0.0) {
        curvature = clamp(length(fwidth(geometric)) / max(length(fwidth(vWorldPos)), 1e-7), 0.0, 400.0);
    }
    float guessThickness = 1.2 / max(curvature, 2.0);
    if (preintegrated) skinPrepareRing(curvature);
    // Normal bending: each channel's diffuse follows a smoother normal the further it scatters.
    vec3 nR = preintegrated ? normalize(mix(n, geometric, strength.r)) : n;
    vec3 nG = preintegrated ? normalize(mix(n, geometric, strength.g * 0.6)) : n;
    vec3 nB = preintegrated ? normalize(mix(n, geometric, strength.b * 0.4)) : n;

    vec3 diffuse = vec3(0.0);
    vec3 specular = vec3(0.0);
    // The sun.
    {
        vec3 NoL = vec3(dot(nR, l), dot(nG, l), dot(nB, l));
        vec3 d = preintegrated ? skinPreintegrated(NoL, strength) : vec3(max(NoL.g, 0.0));
        diffuse += d * light * shadow;
        specular += skinSpecular(n, v, l, f0, roughness, NoV) * light * shadow;
        if (transmission > 0.0 && dot(geometric, l) < 0.35 && frame.lightDir.w > 0.0) {
            vec3 through = receivesShadows ? skinSunTransmittance(vWorldPos, geometric, l, guessThickness)
                : skinTransmittanceProfile(skinProfileDistance(guessThickness));
            float back = clamp(0.3 - dot(geometric, l), 0.0, 1.0);
            diffuse += through * light * (back * transmission * 2.0);
        }
    }
    // Point and spot lights.
    if (frame.clusterGrid.w > 0.5) {
        uvec2 cell = clusterLights();
        for (uint i = cell.x; i < cell.x + cell.y; i++) {
            vec3 pl;
            uint li = lightIndex(i);
            vec3 radiance = punctualRadiance(li, pl);
            float visible = receivesShadows ? localShadow(li, vWorldPos, ng, pl) : 1.0;
            vec3 NoL = vec3(dot(nR, pl), dot(nG, pl), dot(nB, pl));
            vec3 d = preintegrated ? skinPreintegrated(NoL, strength) : vec3(max(NoL.g, 0.0));
            diffuse += d * radiance * visible;
            specular += skinSpecular(n, v, pl, f0, roughness, NoV) * radiance * visible;
            if (transmission > 0.0 && dot(geometric, pl) < 0.35) {
                vec3 through = receivesShadows ? skinLocalTransmittance(li, vWorldPos, geometric, pl, guessThickness)
                    : skinTransmittanceProfile(skinProfileDistance(guessThickness));
                float back = clamp(0.3 - dot(geometric, pl), 0.0, 1.0);
                diffuse += through * radiance * (back * transmission * 2.0);
            }
        }
    }
    // Ambient: diffuse irradiance and the split-sum reflection (at the lobes' mean roughness).
    float ambientRoughness = clamp(roughness * mix(skinPush.lobes.x, skinPush.lobes.y, skinPush.lobes.z), 0.045, 1.0);
    vec3 irradiance, reflected;
    skinAmbient(n, reflect(-v, n), ambientRoughness, v, irradiance, reflected);
    vec2 dfg = skinEnvironmentBRDF(NoV, ambientRoughness);
    vec3 specularAmbient = f0 * dfg.x + dfg.y;
    diffuse = diffuse * (vec3(1.0) - f0) + (vec3(1.0) - specularAmbient) * irradiance * ao;
    specular += specularAmbient * reflected * ao;
    specularOut = specular;
    return diffuseColor * diffuse + specular;
}

// The eye's local normal at planar coordinate e (eyeball radii) on MeshGeometry.eyeball's
// surface: the sphere with the cornea bulge (cornea 0.08 radii over the iris, `irisSize` wide).
vec3 eyeLocalNormal(vec2 e, float irisSize, out vec3 position) {
    float rho = min(length(e), 1.0);
    float theta = asin(rho);
    float irisAngle = asin(clamp(irisSize, 0.05, 0.95));
    float t = min(theta / irisAngle, 1.0);
    float bulge = 0.08 * (1.0 - t * t) * (1.0 - t * t);
    float phi = atan(e.y, e.x + 1e-9);
    vec3 d = vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
    position = d * (1.0 + bulge);
    if (theta >= irisAngle) return d;
    float slope = 0.08 * 4.0 * t * (1.0 - t * t) / irisAngle;
    vec3 outward = vec3(cos(theta) * cos(phi), cos(theta) * sin(phi), -sin(theta));
    return normalize(d + outward * slope / (1.0 + bulge));
}

// The iris's albedo at iris-plane coordinate q (eyeball radii from the axis).
vec3 eyeIris(vec2 q, float irisSize, float pupil, vec3 irisColor) {
    float r = length(q) / irisSize;  // 0 center ... 1 limbus
    float a = atan(q.y, q.x + 1e-9);
    vec2 dir = vec2(cos(a), sin(a));
    // Radial fibers (fast around, slow outward) and crypts (darker patches).
    float fibers = edgeNoise(vec3(dir * 26.0, r * 2.2)) * 0.65 + edgeNoise(vec3(dir * 61.0, r * 4.0 + 7.0)) * 0.35;
    float crypts = edgeNoise(vec3(dir * 9.0, r * 7.0 + 3.0));
    vec3 color = irisColor * (0.45 + 1.1 * fibers);
    color *= mix(0.55, 1.0, smoothstep(0.25, 0.55, crypts));
    // The collarette: a lighter, warmer ring just outside the pupil.
    float collarette = exp(-pow((r - (pupil + 0.17)) / 0.09, 2.0));
    color = mix(color, irisColor * 1.7 + vec3(0.05, 0.035, 0.0), collarette * 0.55);
    // The limbal ring darkens the outer edge.
    color *= 1.0 - skinPush.eye.x * 0.85 * smoothstep(0.72, 1.0, r);
    // The pupil.
    color = mix(vec3(0.004), color, smoothstep(pupil - 0.025, pupil + 0.025, r));
    return color;
}

// The sclera's albedo at planar coordinate e (outside the iris), `rho` its radius (> 1 behind).
vec3 eyeSclera(vec2 e, float rho, float irisSize, vec3 scleraColor) {
    vec3 color = scleraColor;
    // Slightly warmer and pinker toward the corners.
    color *= mix(vec3(1.0), vec3(1.02, 0.86, 0.82), smoothstep(0.45, 1.0, rho));
    // Veins: thin ridges of noise running out from the limbus (slow along the radius, fast
    // around it), branching finer further out, growing toward the corners.
    vec2 dir = e / max(rho, 1e-4);
    float n1 = edgeNoise(vec3(dir * 6.0, rho * 2.2 + 1.7));
    float n2 = edgeNoise(vec3(dir * 15.0, rho * 5.0 + 9.3));
    float ridge = pow(1.0 - abs(2.0 * n1 - 1.0), 24.0) + 0.5 * pow(1.0 - abs(2.0 * n2 - 1.0), 30.0) * smoothstep(0.6, 0.9, rho);
    float reach = smoothstep(irisSize + 0.08, 0.95, rho);
    color = mix(color, vec3(0.5, 0.07, 0.06), clamp(ridge * reach * skinPush.eye.y * 1.4, 0.0, 0.8));
    return color;
}

// The eyeball: returns the lit color; `specularOut` gets the specular part.
vec3 eyeShade(vec3 tint, vec3 v, vec3 l, vec3 light, float shadow, float ao, out vec3 specularOut) {
    vec3 n = normalize(vNormal) * (gl_FrontFacing ? 1.0 : -1.0);
    vec2 e = (vUV - 0.5) * 2.0;
    float rho = length(e);
    float irisSize = skinPush.iris.w;
    float pupil = skinPush.sclera.w;
    // The eye's world axes: X from the tangent (MeshGeometry.eyeball), Y and Z solved from the
    // surface normal, whose local direction the UV gives.
    vec3 surface;
    vec3 local = eyeLocalNormal(rho > 1.0 ? e / rho : e, irisSize, surface);
    if (rho > 1.0) local = vec3(local.xy, -local.z);  // the back half (never seen much)
    vec3 X = vTangent.xyz;
    vec3 Y, Z;
    if (dot(X, X) < 1e-12) {
        Z = n;
        Y = normalize(cross(n, vec3(1.0, 0.0, 0.0)) + vec3(0.0, 1e-4, 0.0));
        X = cross(Y, Z);
    } else {
        X = normalize(X);
        vec3 w = n - X * local.x;
        float wl = length(w);
        vec2 yz = local.yz / max(length(local.yz), 1e-6);
        vec3 W = wl > 1e-6 ? w / wl : n;
        vec3 P = cross(X, W);
        Y = yz.x * W - yz.y * P;
        Z = yz.y * W + yz.x * P;
    }
    vec3 vl = vec3(dot(v, X), dot(v, Y), dot(v, Z));

    // Through the cornea: refract at the (bulged) surface, then down to the iris plane, which
    // meets the limbus `irisDepth` below the cornea's apex (1.08 radii from the center).
    float irisPlane = 1.08 - skinPush.eye.z;
    vec3 albedo;
    float irisWeight = 0.0;
    float scleraWeight = 1.0;
    if (rho < 1.0 && surface.z > irisPlane) {
        vec3 r = refract(-vl, local, 1.0 / 1.336);
        vec2 q = e;
        if (r.z < -1e-3) q = surface.xy + r.xy * ((irisPlane - surface.z) / r.z);
        float limbus = smoothstep(irisSize - 0.035, irisSize + 0.015, length(q));
        vec3 irisColor = eyeIris(q, irisSize, pupil, skinPush.iris.rgb);
        // Beyond the iris edge through the cornea: the dark inner limbus.
        vec3 inner = eyeSclera(e, rho, irisSize, skinPush.sclera.rgb) * (1.0 - 0.6 * skinPush.eye.x);
        albedo = mix(irisColor, inner, limbus);
        irisWeight = 1.0 - limbus;
        scleraWeight = limbus;
    } else {
        albedo = eyeSclera(e, rho, irisSize, skinPush.sclera.rgb);
        // A soft dark band where the sclera meets the cornea.
        albedo *= 1.0 - skinPush.eye.x * 0.35 * (1.0 - smoothstep(irisSize, irisSize + 0.07, rho));
    }
    albedo *= tint;

    // Occlusion from the lids: the corners and under the upper lid.
    float eyeAO = (1.0 - 0.65 * smoothstep(0.45, 0.95, abs(e.x))) * (1.0 - 0.45 * smoothstep(0.15, 0.6, e.y))
        * (1.0 - 0.3 * smoothstep(0.25, 0.7, -e.y));
    eyeAO = rho > 1.0 ? 0.2 : eyeAO;
    float lidShadow = mix(1.0, eyeAO, 0.6);

    // Diffuse: the iris faces along the gaze (light reaches it through the cornea); the sclera wraps softly.
    float NoL = dot(n, l);
    float irisLight = max(dot(Z, l) * 0.65 + NoL * 0.35, 0.0);
    float wrap = 0.3;
    float scleraLight = max((NoL + wrap) / (1.0 + wrap), 0.0);
    vec3 diffuse = vec3(irisLight * irisWeight + scleraLight * scleraWeight) * light * shadow * lidShadow;
    vec3 irradiance, reflected;
    float roughness = 0.07;
    skinAmbient(mix(n, Z, irisWeight), reflect(-v, n), roughness, v, irradiance, reflected);
    diffuse += irradiance * ao * eyeAO;

    // Specular: the wet surface, a sharp highlight and the environment.
    float NoV = max(dot(n, v), 1e-4);
    vec3 f0 = vec3(0.025);
    vec3 specular = vec3(0.0);
    {
        vec3 h = normalize(l + v);
        float sNoL = clamp(NoL, 0.0, 1.0);
        float a = roughness * roughness;
        vec3 F = fresnelSchlick(f0, clamp(dot(v, h), 0.0, 1.0));
        specular += distributionGGX(clamp(dot(n, h), 0.0, 1.0), a) * visibilitySmithGGXCorrelated(NoV, sNoL, a) * F * PI * sNoL
            * light * shadow * lidShadow;
    }
    if (frame.clusterGrid.w > 0.5) {
        uvec2 cell = clusterLights();
        for (uint i = cell.x; i < cell.x + cell.y; i++) {
            vec3 pl;
            uint li = lightIndex(i);
            vec3 radiance = punctualRadiance(li, pl) * lidShadow;
            vec3 gn = n;
            float pNoL = dot(gn, pl);
            float pIris = max(dot(Z, pl) * 0.65 + pNoL * 0.35, 0.0);
            float pSclera = max((pNoL + wrap) / (1.0 + wrap), 0.0);
            diffuse += vec3(pIris * irisWeight + pSclera * scleraWeight) * radiance;
            vec3 ph = normalize(pl + v);
            float sNoL = clamp(pNoL, 0.0, 1.0);
            float a = roughness * roughness;
            vec3 F = fresnelSchlick(f0, clamp(dot(v, ph), 0.0, 1.0));
            specular += distributionGGX(clamp(dot(gn, ph), 0.0, 1.0), a) * visibilitySmithGGXCorrelated(NoV, sNoL, a) * F * PI
                * sNoL * radiance;
        }
    }
    vec2 dfg = skinEnvironmentBRDF(NoV, roughness);
    vec3 specularAmbient = f0 * dfg.x + dfg.y;
    specular += specularAmbient * reflected * mix(1.0, eyeAO, 0.7);
    specularOut = specular;
    return albedo * diffuse * (vec3(1.0) - specularAmbient) + specular;
}
