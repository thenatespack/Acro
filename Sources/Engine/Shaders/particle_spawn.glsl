// A new particle of the emitter `emitter` (an `EmitterParams` uniform the including shader
// declares), for particle_simulate.comp and particle_spawn.comp (sub-emitters). Not compiled
// on its own; rerun Scripts/compile-shaders.sh after editing it.

const float TAU = 6.28318530718;

Particle spawnParticle(uint spawnIndex) {
    uint key = pcgHash(spawnIndex ^ pcgHash(emitter.spawn.w));
    vec3 local = vec3(0.0);
    vec3 axis = emitter.shape.yzw;
    uint kind = uint(emitter.shape.x);
    if (kind == 1u) {  // sphere: uniform in the volume
        float z = particleRandom(key, 0u) * 2.0 - 1.0, phi = particleRandom(key, 1u) * TAU;
        vec3 dir = vec3(sqrt(max(1.0 - z * z, 0.0)) * vec2(cos(phi), sin(phi)), z);
        local = dir * axis.x * pow(particleRandom(key, 2u), 1.0 / 3.0);
    } else if (kind == 2u) {  // box
        local = (vec3(particleRandom(key, 0u), particleRandom(key, 1u), particleRandom(key, 2u)) * 2.0 - 1.0) * axis;
    } else if (kind == 3u) {  // disc in the local XZ plane, optionally gathered into spiral arms
        float r = axis.x * sqrt(particleRandom(key, 0u));
        float angle = particleRandom(key, 1u) * TAU;
        if (emitter.disc.x > 0.0) {
            // Arms: denser toward the center (radius uniform rather than area-uniform), each arm
            // a band of the given width that twists with the radius.
            r = axis.x * particleRandom(key, 0u);
            float arm = floor(particleRandom(key, 1u) * emitter.disc.x);
            angle = arm * TAU / emitter.disc.x + emitter.arms.x + r * emitter.disc.y + (particleRandom(key, 3u) - 0.5) * emitter.disc.z;
        }
        local = vec3(cos(angle) * r, (particleRandom(key, 2u) - 0.5) * axis.y, sin(angle) * r);
    }

    // A direction in the cone of half-angle acos(direction.w) around the emitter's direction.
    vec3 forward = normalize(emitter.direction.xyz);
    vec3 helper = abs(forward.y) < 0.99 ? vec3(0, 1, 0) : vec3(1, 0, 0);
    vec3 side = normalize(cross(helper, forward)), up = cross(forward, side);
    float cosTheta = mix(emitter.direction.w, 1.0, particleRandom(key, 4u));
    float sinTheta = sqrt(max(1.0 - cosTheta * cosTheta, 0.0)), phi = particleRandom(key, 5u) * TAU;
    vec3 localDirection = forward * cosTheta + (side * cos(phi) + up * sin(phi)) * sinTheta;
    float speed = mix(emitter.speedLife.x, emitter.speedLife.y, particleRandom(key, 6u));
    vec3 localVelocity = localDirection * speed;
    if (emitter.sizeSpin.w != 0.0) {
        // Orbit around the local Y axis: × the circular speed for the attraction (a spring: v = sqrt(k) r,
        // so everything circles in the same period), or a plain speed without one.
        float r = length(local.xz);
        vec3 tangent = r > 1e-4 ? vec3(-local.z, 0.0, local.x) / r : vec3(0.0);
        float orbital = emitter.turbulence.w > 0.0 ? sqrt(emitter.turbulence.w) * r : 1.0;
        localVelocity += tangent * emitter.sizeSpin.w * orbital;
    }

    Particle p;
    p.position = vec4((emitter.transform * vec4(local, 1.0)).xyz, 0.0);
    p.velocity = vec4((emitter.transform * vec4(localVelocity, 0.0)).xyz,
                      max(mix(emitter.speedLife.z, emitter.speedLife.w, particleRandom(key, 7u)), 1e-3));
    p.attributes = vec4(mix(emitter.sizeSpin.x, emitter.sizeSpin.y, particleRandom(key, 8u)), particleRandom(key, 9u) * TAU,
                        (particleRandom(key, 10u) * 2.0 - 1.0) * emitter.sizeSpin.z, particleRandom(key, 11u));
    return p;
}
