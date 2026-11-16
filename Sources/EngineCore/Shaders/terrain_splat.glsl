// Per-pixel terrain layer blending (`TerrainSplat`), graphSurface() of mesh_terrain.frag.
// Included by mesh_surface.glsl inside its MATERIAL_GRAPH block when TERRAIN_SPLAT is defined.
//
// Textures (material slots):
// - baseColorMap: the layers' albedo atlas (sRGB), a grid of square cells, layer i in cell
//   (i % columns, i / columns); a layer without a texture is a cell of its flat color.
// - normalMap: the layers' tangent-space normal maps in the same grid (linear XYZ in RGB), read
//   only for layers whose bit is set in the normal mask.
// - metallicRoughnessMap: splat weights of layers 0-3 in RGBA (linear, one texel per height sample).
// - emissiveMap: splat weights of layers 4-7.
// graphValues.values (must match `TerrainSplat.values`):
// - [0] x: layer count (1-8), y: normal map mask (bit i: layer i), z, w: splat UV = uv x z + w
// - [1] xy: terrain size in meters (uv 0-1 spans it), z: normal scale, w: roughness
// - [2] x: metallic, y: atlas columns, z: atlas rows, w: cell size in texels (a power of two)
// - [3], [4]: 1 / tile size (repeats per meter) of layers 0-3 and 4-7
//
// Each layer repeats every tile size meters from the terrain's center, like the baked albedo
// (`Terrain.bakeAlbedo`). Atlas cells don't wrap by themselves, so the cell coordinate is
// fract()ed and kept half a texel inside the cell at the level of detail sampled, which is
// picked from the unwrapped coordinate's derivatives (no seam at the repeat) and stops before
// mip levels where cells would blend into each other.

// The atlas level of detail for coordinate derivatives dx, dy (in repeats per pixel).
float terrainLod(vec2 dx, vec2 dy, float cellTexels) {
    float d = max(dot(dx, dx), dot(dy, dy)) * cellTexels * cellTexels;
    return clamp(0.5 * log2(max(d, 1e-8)), 0.0, max(log2(cellTexels) - 2.0, 0.0));
}

// Where repeat coordinate t of layer i falls in an atlas, at level of detail lod.
vec2 terrainAtlasUV(int i, vec2 t, float lod) {
    vec4 grid = graphValues.values[2];
    float columns = grid.y;
    vec2 cell = vec2(mod(float(i), columns), floor(float(i) / columns));
    float edge = 0.5 * exp2(lod) / grid.w;
    vec2 f = clamp(fract(t), vec2(edge), vec2(1.0 - edge));
    return (cell + f) / grid.yz;
}

void graphSurface() {
    vec4 head = graphValues.values[0];
    vec4 terrain = graphValues.values[1];
    vec4 grid = graphValues.values[2];
    int count = int(head.x + 0.5);
    int normalMask = int(head.y + 0.5);
    vec2 splatUV = gUV * head.z + head.w;
    vec4 w0 = textureLod(sampler2D(metallicRoughnessMap, materialSampler), splatUV, 0.0);
    vec4 w1 = count > 4 ? textureLod(sampler2D(emissiveMap, materialSampler), splatUV, 0.0) : vec4(0.0);
    // Meters from the terrain's center, and their change per pixel (taken here, in uniform control flow).
    vec2 meters = (gUV - 0.5) * terrain.xy;
    vec2 dx = dFdx(meters), dy = dFdy(meters);
    vec3 albedo = vec3(0.0);
    vec3 normal = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < 8; i++) {
        if (i >= count) break;
        float w = i < 4 ? w0[i] : w1[i - 4];
        if (w < 1.0 / 512.0) continue;
        float repeats = graphValues.values[3 + i / 4][i % 4];
        vec2 t = meters * repeats;
        float lod = terrainLod(dx * repeats, dy * repeats, grid.w);
        vec2 uv = terrainAtlasUV(i, t, lod);
        albedo += textureLod(sampler2D(baseColorMap, materialSampler), uv, lod).rgb * w;
        vec3 n = vec3(0.0, 0.0, 1.0);
        if (((normalMask >> i) & 1) != 0) {
            n = textureLod(sampler2D(normalMap, materialSampler), uv, lod).xyz * 2.0 - 1.0;
            n.xy *= terrain.z;
        }
        normal += n * w;
        total += w;
    }
    float scale = total > 0.0 ? 1.0 / total : 0.0;
    gBaseColor = albedo * scale;
    gOpacity = 1.0;
    gNormalTS = total > 0.0 ? normal * scale : vec3(0.0, 0.0, 1.0);
    gMetallic = grid.x;
    gRoughness = terrain.w;
    gEmissive = vec3(0.0);
    gOcclusion = 1.0;
}
