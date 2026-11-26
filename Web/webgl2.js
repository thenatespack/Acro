// The WebGL 2 side of the engine's WebGL 2 render device (Sources/EngineBackends/Backends/WebGL2).
//
// Swift records a frame's draw state and draws as numbers into a command buffer in WebAssembly
// memory, and calls `execute` once per batch (normally once a frame): per draw nothing crosses
// between WebAssembly and JavaScript, no strings are made and nothing is allocated. Objects
// (buffers, textures, samplers, framebuffers, programs, vertex arrays, queries) have numeric ids
// that Swift assigns; this file keeps the WebGL objects in a Map. Creation, uploads and readbacks
// are direct calls (rare), with pointers into WebAssembly memory for their bytes.
//
// `setUpWebGL2(canvas)` makes the context; the loader publishes the result as `acro.gl` and
// `acro.webgl` (this helper). `acro.wasmMemory()` gives the WebAssembly memory's buffer.
// `debug` (ENGINE_GL_DEBUG=1) checks gl.getError() after every command and names the command.

// Opcodes: keep in sync with `WebGL2Op` in WebGL2Resources.swift.
const OP = {
  BEGIN_PASS: 1, END_PASS: 2, PIPELINE: 3, VAO: 4, ATTRIB: 5, INDEX: 6, UBO: 7, TEX: 8, SCISSOR: 9, VIEWPORT: 10,
  DRAW: 11, DRAW_INDEXED: 12, BEGIN_QUERY: 13, END_QUERY: 14, BEGIN_TIMER: 15, END_TIMER: 16, CREATE_VAO: 17,
};
const OP_NAMES = Object.fromEntries(Object.entries(OP).map(([name, code]) => [code, name]));
// Command lengths in 32-bit words, opcode included.
const LENGTH = { 1: 12, 2: 6, 3: 17, 4: 2, 5: 7, 6: 2, 7: 5, 8: 4, 9: 6, 10: 5, 11: 4, 12: 5, 13: 3, 14: 1, 15: 3, 16: 1, 17: 2 };

const GL = {
  TEXTURE_2D: 0x0DE1, TEXTURE0: 0x84C0, ARRAY_BUFFER: 0x8892, ELEMENT_ARRAY_BUFFER: 0x8893, UNIFORM_BUFFER: 0x8A11,
  COPY_READ_BUFFER: 0x8F36, COPY_WRITE_BUFFER: 0x8F37, DYNAMIC_DRAW: 0x88E8, STATIC_DRAW: 0x88E4,
  FRAMEBUFFER: 0x8D40, READ_FRAMEBUFFER: 0x8CA8, DRAW_FRAMEBUFFER: 0x8CA9, RENDERBUFFER: 0x8D41,
  COLOR_ATTACHMENT0: 0x8CE0, COLOR_ATTACHMENT1: 0x8CE1, DEPTH_ATTACHMENT: 0x8D00, NONE: 0, BACK: 0x0405,
  COLOR_BUFFER_BIT: 0x4000, DEPTH_BUFFER_BIT: 0x100, NEAREST: 0x2600, LINEAR: 0x2601,
  TEXTURE_MAG_FILTER: 0x2800, TEXTURE_MIN_FILTER: 0x2801, TEXTURE_WRAP_S: 0x2802, TEXTURE_WRAP_T: 0x2803,
  TEXTURE_MIN_LOD: 0x813A, TEXTURE_MAX_LOD: 0x813B, TEXTURE_BASE_LEVEL: 0x813C, TEXTURE_MAX_LEVEL: 0x813D,
  TEXTURE_COMPARE_MODE: 0x884C, TEXTURE_COMPARE_FUNC: 0x884D, COMPARE_REF_TO_TEXTURE: 0x884E, LEQUAL: 0x0203,
  CLAMP_TO_EDGE: 0x812F, CULL_FACE: 0x0B44, CW: 0x0900, DEPTH_TEST: 0x0B71, BLEND: 0x0BE2, SCISSOR_TEST: 0x0C11,
  POLYGON_OFFSET_FILL: 0x8037, SAMPLE_ALPHA_TO_COVERAGE: 0x809E, FUNC_ADD: 0x8006, TRIANGLES: 0x0004,
  FLOAT: 0x1406, UNSIGNED_BYTE: 0x1401, HALF_FLOAT: 0x140B, RGBA: 0x1908, RGBA8: 0x8058, SRGB8_ALPHA8: 0x8C43,
  ANY_SAMPLES_PASSED_CONSERVATIVE: 0x8D6A, QUERY_RESULT: 0x8866, QUERY_RESULT_AVAILABLE: 0x8867,
  TIME_ELAPSED_EXT: 0x88BF, GPU_DISJOINT_EXT: 0x8FBB, FRAMEBUFFER_COMPLETE: 0x8CD5,
  UNIFORM_BLOCK_DATA_SIZE: 0x8A40, INVALID_INDEX: 0xFFFFFFFF, COMPILE_STATUS: 0x8B81, LINK_STATUS: 0x8B82,
  VERTEX_SHADER: 0x8B31, FRAGMENT_SHADER: 0x8B30, UNPACK_ALIGNMENT: 0x0CF5, PACK_ALIGNMENT: 0x0D05,
};

/**
 * A WebGL 2 context on `canvas`, or undefined (with the reason in `failure`) when the browser has none.
 * The device renders every pass into its own framebuffers, so the canvas needs no depth, stencil,
 * alpha or antialiasing of its own.
 */
export function setUpWebGL2(canvas) {
  let reason;
  const onLost = (event) => { reason = event.statusMessage || reason; };
  canvas.addEventListener("webglcontextcreationerror", onLost, { once: true });
  const gl = canvas.getContext("webgl2", {
    alpha: false, depth: false, stencil: false, antialias: false, premultipliedAlpha: false,
    preserveDrawingBuffer: false, powerPreference: "high-performance",
  });
  if (!gl) return { failure: reason ?? "this browser has no WebGL 2 (or it is turned off)" };
  const scale = devicePixelRatio || 1;
  canvas.width = Math.max(1, Math.round(canvas.clientWidth * scale));
  canvas.height = Math.max(1, Math.round(canvas.clientHeight * scale));
  return { gl, helper: new WebGL2Helper(gl) };
}

class WebGL2Helper {
  constructor(gl) {
    this.gl = gl;
    this.objects = new Map();
    this.debug = false;
    this.errors = 0;
    this.i32 = undefined;
    this.f32 = undefined;
    // Extensions the device asks about (`extensions`), enabled here once.
    this.extensions = {};
    for (const name of ["EXT_color_buffer_float", "EXT_color_buffer_half_float", "EXT_texture_compression_bptc",
      "EXT_texture_compression_rgtc", "WEBGL_compressed_texture_s3tc", "WEBGL_compressed_texture_s3tc_srgb",
      "WEBGL_compressed_texture_astc", "EXT_disjoint_timer_query_webgl2", "OES_texture_float_linear",
      "EXT_float_blend", "KHR_parallel_shader_compile"]) {
      const ext = gl.getExtension(name);
      if (ext) this.extensions[name] = ext;
    }
    const astc = this.extensions.WEBGL_compressed_texture_astc;
    this.astcHDR = !!astc && typeof astc.getSupportedProfiles === "function" && astc.getSupportedProfiles().includes("hdr");
    // Unit for creation and uploads; the device's draws use the units below it.
    this.scratchUnit = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS) - 1;
    this.scratchVAO = gl.createVertexArray();
    gl.pixelStorei(GL.UNPACK_ALIGNMENT, 1);
    gl.pixelStorei(GL.PACK_ALIGNMENT, 1);
    // The engine's front faces are counter-clockwise in its images (top row first, as in Vulkan and
    // WebGPU); GL decides winding with y pointing up, so the same triangles are clockwise here.
    gl.frontFace(GL.CW);
    this.invalidate();
    this.currentVAO = null;
    this.drawFramebuffer = null;
    this.querySets = new Map();
    this.timerSets = new Map();
    this.presentProgram = undefined;
    this.blitKeepsSRGB = undefined;
    // Calls from WebAssembly, by function (for measuring how often the engine crosses into JS).
    this.calls = {};
    for (const name of ["execute", "createBuffer", "bufferSubData", "getBufferSubData", "createTexture", "texSubImage",
      "createRenderbuffer", "createFramebuffer", "createSampler", "createProgram", "bindUniformBlock", "bindSamplerUnit",
      "readQueries", "readTimers", "readPixels", "copyEncoded", "deleteList", "info", "setDebug"]) {
      const method = this[name];
      this[name] = (...args) => { this.calls[name] = (this.calls[name] ?? 0) + 1; return method.apply(this, args); };
    }
  }

  /** What the device needs to know, read once. */
  info() {
    const gl = this.gl;
    const debugInfo = gl.getExtension("WEBGL_debug_renderer_info");
    const renderer = debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
    return {
      renderer: String(renderer ?? "WebGL 2"),
      maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
      maxSamples: gl.getParameter(gl.MAX_SAMPLES),
      uniformBufferOffsetAlignment: gl.getParameter(gl.UNIFORM_BUFFER_OFFSET_ALIGNMENT),
      maxUniformBlockSize: gl.getParameter(gl.MAX_UNIFORM_BLOCK_SIZE),
      extensions: Object.keys(this.extensions).join(" "),
      astcHDR: this.astcHDR,
    };
  }

  setDebug(on) { this.debug = !!on; }

  /** Forgets the cached fixed-function state (after something else changed it). */
  invalidate() {
    this.state = new Int32Array(16).fill(-1);
    this.stateFloats = new Float32Array(2).fill(NaN);
    this.program = -1;
    this.scissorOn = -1;
  }

  memory() {
    const buffer = globalThis.acro.wasmMemory();
    if (!this.i32 || this.i32.buffer !== buffer) {
      this.i32 = new Int32Array(buffer);
      this.f32 = new Float32Array(buffer);
      this.u8 = new Uint8Array(buffer);
    }
    return buffer;
  }

  bytes(ptr, length) { this.memory(); return this.u8.subarray(ptr, ptr + length); }

  checkError(what) {
    if (!this.debug) return;
    const error = this.gl.getError();
    if (error !== 0 && this.errors++ < 50) console.error(`[acro] WebGL error 0x${error.toString(16)} after ${what}`);
  }

  // MARK: - Objects

  delete(ids) {
    const gl = this.gl;
    for (const id of ids) {
      const object = this.objects.get(id);
      if (!object) continue;
      this.objects.delete(id);
      switch (object.kind) {
        case "buffer": gl.deleteBuffer(object.gl); break;
        case "texture": gl.deleteTexture(object.gl); break;
        case "renderbuffer": gl.deleteRenderbuffer(object.gl); break;
        case "framebuffer": gl.deleteFramebuffer(object.gl); break;
        case "sampler": gl.deleteSampler(object.gl); break;
        case "program": gl.deleteProgram(object.gl); break;
        case "vao": if (this.currentVAO === object.gl) { gl.bindVertexArray(null); this.currentVAO = null; } gl.deleteVertexArray(object.gl); break;
      }
    }
  }

  /** Deletes the objects whose ids are the `count` Int32s at `ptr`. */
  deleteList(ptr, count) {
    this.memory();
    this.delete(Array.from(this.i32.subarray(ptr >> 2, (ptr >> 2) + count)));
  }

  get(id) { return this.objects.get(id)?.gl ?? null; }

  /**
   * A buffer of `size` bytes, its start filled from `length` bytes at `ptr` (when `length` > 0).
   * WebGL types a buffer by its first binding: index buffers can't be bound anywhere else, so
   * they are made (and written) in a vertex array of their own.
   */
  createBuffer(id, index, size, ptr, length) {
    const gl = this.gl;
    const buffer = gl.createBuffer();
    this.objects.set(id, { kind: "buffer", gl: buffer, index: !!index });
    this.withBuffer(buffer, !!index, (target) => {
      gl.bufferData(target, size, index ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
      if (length > 0) gl.bufferSubData(target, 0, this.bytes(ptr, length));
    });
    this.checkError("createBuffer");
  }

  bufferSubData(id, offset, ptr, length) {
    const object = this.objects.get(id);
    this.withBuffer(object.gl, object.index, (target) => this.gl.bufferSubData(target, offset, this.bytes(ptr, length)));
    this.checkError("bufferSubData");
  }

  getBufferSubData(id, offset, ptr, length) {
    const object = this.objects.get(id);
    this.withBuffer(object.gl, object.index, (target) => this.gl.getBufferSubData(target, offset, this.bytes(ptr, length)));
    this.checkError("getBufferSubData");
  }

  withBuffer(buffer, index, body) {
    const gl = this.gl;
    if (index) {
      gl.bindVertexArray(this.scratchVAO);
      gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffer);
      body(GL.ELEMENT_ARRAY_BUFFER);
      gl.bindVertexArray(this.currentVAO);
    } else {
      gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
      body(GL.ARRAY_BUFFER);
    }
  }

  /** Immutable storage for `levels` levels; sampled levels are capped at the last one. */
  createTexture(id, internalFormat, width, height, levels) {
    const gl = this.gl;
    const texture = gl.createTexture();
    this.objects.set(id, { kind: "texture", gl: texture });
    gl.activeTexture(GL.TEXTURE0 + this.scratchUnit);
    gl.bindTexture(GL.TEXTURE_2D, texture);
    gl.texStorage2D(GL.TEXTURE_2D, levels, internalFormat, width, height);
    gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAX_LEVEL, levels - 1);
    gl.bindTexture(GL.TEXTURE_2D, null);
    this.checkError(`createTexture 0x${internalFormat.toString(16)} ${width}x${height}`);
  }

  /**
   * Writes a region of one level from `length` bytes at `ptr`. `type` 0 means compressed
   * (`format` is then the compressed internal format); HALF_FLOAT data goes in as a Uint16Array.
   */
  texSubImage(id, level, x, y, width, height, format, type, ptr, length) {
    const gl = this.gl;
    gl.activeTexture(GL.TEXTURE0 + this.scratchUnit);
    gl.bindTexture(GL.TEXTURE_2D, this.get(id));
    const bytes = this.bytes(ptr, length);
    if (type === 0) {
      gl.compressedTexSubImage2D(GL.TEXTURE_2D, level, x, y, width, height, format, bytes);
    } else if (type === GL.HALF_FLOAT) {
      gl.texSubImage2D(GL.TEXTURE_2D, level, x, y, width, height, format, type,
                       new Uint16Array(bytes.buffer, bytes.byteOffset, length >> 1));
    } else if (type === GL.FLOAT) {
      gl.texSubImage2D(GL.TEXTURE_2D, level, x, y, width, height, format, type,
                       new Float32Array(bytes.buffer, bytes.byteOffset, length >> 2));
    } else {
      gl.texSubImage2D(GL.TEXTURE_2D, level, x, y, width, height, format, type, bytes);
    }
    gl.bindTexture(GL.TEXTURE_2D, null);
    this.checkError("texSubImage");
  }

  createRenderbuffer(id, internalFormat, samples, width, height) {
    const gl = this.gl;
    const renderbuffer = gl.createRenderbuffer();
    this.objects.set(id, { kind: "renderbuffer", gl: renderbuffer });
    gl.bindRenderbuffer(GL.RENDERBUFFER, renderbuffer);
    if (samples > 1) gl.renderbufferStorageMultisample(GL.RENDERBUFFER, samples, internalFormat, width, height);
    else gl.renderbufferStorage(GL.RENDERBUFFER, internalFormat, width, height);
    gl.bindRenderbuffer(GL.RENDERBUFFER, null);
    this.checkError(`createRenderbuffer 0x${internalFormat.toString(16)} x${samples} ${width}x${height}`);
  }

  /**
   * A framebuffer with up to two color attachments and a depth attachment: each an id, positive
   * for a texture and negative for a renderbuffer, 0 for none. Returns its status (0x8CD5: complete).
   */
  createFramebuffer(id, color0, color1, depth) {
    const gl = this.gl;
    const framebuffer = gl.createFramebuffer();
    this.objects.set(id, { kind: "framebuffer", gl: framebuffer });
    // Read and draw (readBuffer applies to the read binding).
    gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
    const attach = (attachment, object) => {
      if (object > 0) gl.framebufferTexture2D(GL.DRAW_FRAMEBUFFER, attachment, GL.TEXTURE_2D, this.get(object), 0);
      else if (object < 0) gl.framebufferRenderbuffer(GL.DRAW_FRAMEBUFFER, attachment, GL.RENDERBUFFER, this.get(-object));
    };
    attach(GL.COLOR_ATTACHMENT0, color0);
    attach(GL.COLOR_ATTACHMENT1, color1);
    attach(GL.DEPTH_ATTACHMENT, depth);
    const buffers = [];
    if (color0) buffers.push(GL.COLOR_ATTACHMENT0);
    if (color1) buffers.push(GL.COLOR_ATTACHMENT1);
    gl.drawBuffers(buffers.length ? buffers : [GL.NONE]);
    if (!color0) gl.readBuffer(GL.NONE);
    const status = gl.checkFramebufferStatus(GL.DRAW_FRAMEBUFFER);
    gl.bindFramebuffer(GL.READ_FRAMEBUFFER, null);
    gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, this.drawFramebuffer);
    this.checkError("createFramebuffer");
    return status;
  }

  /** `compare` 1: a depth comparison sampler (less-equal). `maxLod` < 0: no limit. */
  createSampler(id, minFilter, magFilter, wrap, compare, maxLod) {
    const gl = this.gl;
    const sampler = gl.createSampler();
    this.objects.set(id, { kind: "sampler", gl: sampler });
    gl.samplerParameteri(sampler, GL.TEXTURE_MIN_FILTER, minFilter);
    gl.samplerParameteri(sampler, GL.TEXTURE_MAG_FILTER, magFilter);
    gl.samplerParameteri(sampler, GL.TEXTURE_WRAP_S, wrap);
    gl.samplerParameteri(sampler, GL.TEXTURE_WRAP_T, wrap);
    if (maxLod >= 0) gl.samplerParameterf(sampler, GL.TEXTURE_MAX_LOD, maxLod);
    if (compare) {
      gl.samplerParameteri(sampler, GL.TEXTURE_COMPARE_MODE, GL.COMPARE_REF_TO_TEXTURE);
      gl.samplerParameteri(sampler, GL.TEXTURE_COMPARE_FUNC, GL.LEQUAL);
    }
    this.checkError("createSampler");
  }

  /** Compiles and links; returns "" or the log of what failed. */
  createProgram(id, vertexSource, fragmentSource) {
    const gl = this.gl;
    const compile = (type, source) => {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      return shader;
    };
    const vs = compile(GL.VERTEX_SHADER, vertexSource);
    const fs = compile(GL.FRAGMENT_SHADER, fragmentSource);
    const program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    let log = "";
    if (!gl.getProgramParameter(program, GL.LINK_STATUS)) {
      for (const [stage, shader] of [["vertex", vs], ["fragment", fs]]) {
        if (!gl.getShaderParameter(shader, GL.COMPILE_STATUS)) log += `${stage} shader: ${gl.getShaderInfoLog(shader)}\n`;
      }
      log += `link: ${gl.getProgramInfoLog(program)}`;
      gl.deleteProgram(program);
    } else {
      this.objects.set(id, { kind: "program", gl: program });
    }
    gl.deleteShader(vs);
    gl.deleteShader(fs);
    this.checkError("createProgram");
    return log;
  }

  /** Binds uniform block `name` of program `id` to binding point `point`: its size, or -1 if inactive. */
  bindUniformBlock(id, name, point) {
    const gl = this.gl;
    const program = this.get(id);
    const index = gl.getUniformBlockIndex(program, name);
    if (index === GL.INVALID_INDEX) return -1;
    gl.uniformBlockBinding(program, index, point);
    return gl.getActiveUniformBlockParameter(program, index, GL.UNIFORM_BLOCK_DATA_SIZE);
  }

  /** Points sampler uniform `name` of program `id` at texture unit `unit`: false if inactive. */
  bindSamplerUnit(id, name, unit) {
    const gl = this.gl;
    const program = this.get(id);
    const location = gl.getUniformLocation(program, name);
    if (location === null) return false;
    gl.useProgram(program);
    gl.uniform1i(location, unit);
    this.program = -1;
    return true;
  }

  // MARK: - Commands

  /** Runs `count` command words at `ptr` (see `OP`). */
  execute(ptr, count) {
    const gl = this.gl;
    this.memory();
    const i32 = this.i32, f32 = this.f32;
    const state = this.state;
    let p = ptr >> 2;
    const end = p + count;
    while (p < end) {
      const op = i32[p];
      switch (op) {
        case 1: {  // BEGIN_PASS fbo width height colorCount clearColor r g b a clearDepth depth
          const framebuffer = this.get(i32[p + 1]);
          gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, framebuffer);
          this.drawFramebuffer = framebuffer;
          gl.viewport(0, 0, i32[p + 2], i32[p + 3]);
          if (this.scissorOn !== 0) { gl.disable(GL.SCISSOR_TEST); this.scissorOn = 0; }
          const colors = i32[p + 4];
          if (colors > 1) gl.drawBuffers([GL.COLOR_ATTACHMENT0, GL.COLOR_ATTACHMENT1]);
          if (colors > 0 && i32[p + 5]) {
            if (state[13] !== 1) { gl.colorMask(true, true, true, true); state[13] = 1; }
            const color = this.clearColor;
            color[0] = f32[p + 6]; color[1] = f32[p + 7]; color[2] = f32[p + 8]; color[3] = f32[p + 9];
            gl.clearBufferfv(gl.COLOR, 0, color);
            if (colors > 1) gl.clearBufferfv(gl.COLOR, 1, this.zero4);
          }
          if (i32[p + 10]) {
            if (state[5] !== 1) { gl.depthMask(true); state[5] = 1; }
            this.clearDepth[0] = f32[p + 11];
            gl.clearBufferfv(gl.DEPTH, 0, this.clearDepth);
          }
          this.motionBuffers = colors > 1 ? 1 : -1;
          break;
        }
        case 2: {  // END_PASS source destination width height mask
          const source = i32[p + 1];
          if (source) {
            gl.bindFramebuffer(GL.READ_FRAMEBUFFER, this.get(source));
            gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, this.get(i32[p + 2]));
            if (this.scissorOn !== 0) { gl.disable(GL.SCISSOR_TEST); this.scissorOn = 0; }
            gl.blitFramebuffer(0, 0, i32[p + 3], i32[p + 4], 0, 0, i32[p + 3], i32[p + 4], i32[p + 5], GL.NEAREST);
            gl.bindFramebuffer(GL.READ_FRAMEBUFFER, null);
          }
          gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, null);
          this.drawFramebuffer = null;
          break;
        }
        case 3: this.applyPipeline(i32, f32, p); break;
        case 4: {  // VAO id
          const vao = this.get(i32[p + 1]);
          gl.bindVertexArray(vao);
          this.currentVAO = vao;
          break;
        }
        case 5: {  // ATTRIB location buffer size stride offset divisor
          const location = i32[p + 1];
          gl.bindBuffer(GL.ARRAY_BUFFER, this.get(i32[p + 2]));
          gl.enableVertexAttribArray(location);
          gl.vertexAttribPointer(location, i32[p + 3], GL.FLOAT, false, i32[p + 4], i32[p + 5]);
          gl.vertexAttribDivisor(location, i32[p + 6]);
          break;
        }
        case 6: gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, this.get(i32[p + 1])); break;  // INDEX buffer
        case 7: gl.bindBufferRange(GL.UNIFORM_BUFFER, i32[p + 1], this.get(i32[p + 2]), i32[p + 3], i32[p + 4]); break;
        case 8: {  // TEX unit texture sampler
          const unit = i32[p + 1];
          gl.activeTexture(GL.TEXTURE0 + unit);
          gl.bindTexture(GL.TEXTURE_2D, this.get(i32[p + 2]));
          gl.bindSampler(unit, this.get(i32[p + 3]));
          break;
        }
        case 9: {  // SCISSOR on x y width height
          const on = i32[p + 1];
          if (on !== this.scissorOn) { if (on) gl.enable(GL.SCISSOR_TEST); else gl.disable(GL.SCISSOR_TEST); this.scissorOn = on; }
          if (on) gl.scissor(i32[p + 2], i32[p + 3], i32[p + 4], i32[p + 5]);
          break;
        }
        case 10: gl.viewport(i32[p + 1], i32[p + 2], i32[p + 3], i32[p + 4]); break;
        case 11: gl.drawArraysInstanced(GL.TRIANGLES, i32[p + 1], i32[p + 2], i32[p + 3]); break;
        case 12: gl.drawElementsInstanced(GL.TRIANGLES, i32[p + 1], i32[p + 2], i32[p + 3], i32[p + 4]); break;
        case 13: gl.beginQuery(GL.ANY_SAMPLES_PASSED_CONSERVATIVE, this.query(this.querySets, i32[p + 1], i32[p + 2])); break;
        case 14: gl.endQuery(GL.ANY_SAMPLES_PASSED_CONSERVATIVE); break;
        case 15: gl.beginQuery(GL.TIME_ELAPSED_EXT, this.query(this.timerSets, i32[p + 1], i32[p + 2])); break;
        case 16: gl.endQuery(GL.TIME_ELAPSED_EXT); break;
        case 17: {  // CREATE_VAO id (and binds it)
          const vao = gl.createVertexArray();
          this.objects.set(i32[p + 1], { kind: "vao", gl: vao });
          gl.bindVertexArray(vao);
          this.currentVAO = vao;
          break;
        }
        default:
          throw new Error(`[acro] bad WebGL 2 command ${op} at word ${p - (ptr >> 2)}`);
      }
      if (this.debug) this.checkError(`${OP_NAMES[op]} (${Array.from(i32.subarray(p + 1, p + LENGTH[op])).join(" ")})`);
      p += LENGTH[op];
    }
  }

  /**
   * PIPELINE program cull depthTest depthFunc depthWrite polygonOffset units factor blend srcRGB dstRGB
   * srcAlpha dstAlpha colorWrite alphaToCoverage motion: sets what differs from the current state.
   */
  applyPipeline(i32, f32, p) {
    const gl = this.gl, state = this.state;
    const program = i32[p + 1];
    if (program !== this.program) { gl.useProgram(this.get(program)); this.program = program; }
    const cull = i32[p + 2];
    if (cull !== state[0]) {
      if (cull === 0) gl.disable(GL.CULL_FACE);
      else { gl.enable(GL.CULL_FACE); gl.cullFace(cull); }
      state[0] = cull;
    }
    if (i32[p + 3] !== state[1]) { if (i32[p + 3]) gl.enable(GL.DEPTH_TEST); else gl.disable(GL.DEPTH_TEST); state[1] = i32[p + 3]; }
    if (i32[p + 4] !== state[2]) { gl.depthFunc(i32[p + 4]); state[2] = i32[p + 4]; }
    if (i32[p + 5] !== state[5]) { gl.depthMask(!!i32[p + 5]); state[5] = i32[p + 5]; }
    const offset = i32[p + 6];
    if (offset !== state[6]) { if (offset) gl.enable(GL.POLYGON_OFFSET_FILL); else gl.disable(GL.POLYGON_OFFSET_FILL); state[6] = offset; }
    if (offset && (f32[p + 7] !== this.stateFloats[0] || f32[p + 8] !== this.stateFloats[1])) {
      gl.polygonOffset(f32[p + 8], f32[p + 7]);
      this.stateFloats[0] = f32[p + 7];
      this.stateFloats[1] = f32[p + 8];
    }
    const blend = i32[p + 9];
    if (blend !== state[7]) { if (blend) gl.enable(GL.BLEND); else gl.disable(GL.BLEND); state[7] = blend; }
    if (blend && (i32[p + 10] !== state[8] || i32[p + 11] !== state[9] || i32[p + 12] !== state[10] || i32[p + 13] !== state[11])) {
      gl.blendFuncSeparate(i32[p + 10], i32[p + 11], i32[p + 12], i32[p + 13]);
      state[8] = i32[p + 10]; state[9] = i32[p + 11]; state[10] = i32[p + 12]; state[11] = i32[p + 13];
    }
    if (i32[p + 14] !== state[13]) { const on = !!i32[p + 14]; gl.colorMask(on, on, on, on); state[13] = i32[p + 14]; }
    if (i32[p + 15] !== state[14]) {
      if (i32[p + 15]) gl.enable(GL.SAMPLE_ALPHA_TO_COVERAGE); else gl.disable(GL.SAMPLE_ALPHA_TO_COVERAGE);
      state[14] = i32[p + 15];
    }
    // A pass with a motion-vector attachment: only pipelines that write motion vectors draw into it.
    if (this.motionBuffers !== -1 && i32[p + 16] !== this.motionBuffers) {
      gl.drawBuffers(i32[p + 16] ? [GL.COLOR_ATTACHMENT0, GL.COLOR_ATTACHMENT1] : [GL.COLOR_ATTACHMENT0, GL.NONE]);
      this.motionBuffers = i32[p + 16];
    }
  }

  query(sets, set, index) {
    let list = sets.get(set);
    if (!list) { list = []; sets.set(set, list); }
    while (list.length <= index) list.push(this.gl.createQuery());
    return list[index];
  }

  /**
   * Occlusion results of the first `count` queries of `set`, as 0 / 1 bytes at `ptr`, once all are
   * available: returns 1 then, 0 while some are still pending.
   */
  readQueries(set, count, ptr) {
    const gl = this.gl;
    const list = this.querySets.get(set) ?? [];
    if (count > 0 && !gl.getQueryParameter(list[count - 1], GL.QUERY_RESULT_AVAILABLE)) return 0;
    const out = this.bytes(ptr, count);
    for (let i = 0; i < count; i++) out[i] = gl.getQueryParameter(list[i], GL.QUERY_RESULT) ? 1 : 0;
    return 1;
  }

  /**
   * Elapsed nanoseconds of the first `count` timer queries of `set` as Float64s at `ptr` (8-byte
   * aligned): 1 when all are available, 0 while pending, -1 when the GPU was disjoint (discard them).
   */
  readTimers(set, count, ptr) {
    const gl = this.gl;
    const list = this.timerSets.get(set) ?? [];
    if (count > 0 && !gl.getQueryParameter(list[count - 1], GL.QUERY_RESULT_AVAILABLE)) return 0;
    if (gl.getParameter(GL.GPU_DISJOINT_EXT)) return -1;
    const out = new Float64Array(this.memory(), ptr, count);
    for (let i = 0; i < count; i++) out[i] = gl.getQueryParameter(list[i], GL.QUERY_RESULT);
    return 1;
  }

  /** Reads `width` x `height` RGBA8 texels of framebuffer `fbo`'s first color attachment to `ptr`. */
  readPixels(fbo, width, height, ptr) {
    const gl = this.gl;
    gl.bindFramebuffer(GL.READ_FRAMEBUFFER, this.get(fbo));
    gl.readBuffer(GL.COLOR_ATTACHMENT0);
    gl.readPixels(0, 0, width, height, GL.RGBA, GL.UNSIGNED_BYTE, this.bytes(ptr, width * height * 4));
    gl.bindFramebuffer(GL.READ_FRAMEBUFFER, null);
    this.checkError("readPixels");
  }

  // MARK: - sRGB copies and presenting

  /**
   * Copies an sRGB texture's encoded bytes (not the linear values sampling returns) into framebuffer
   * `fbo` (0: the canvas, flipped vertically: the device's images have their top row first, the
   * canvas its bottom row). A blit when the browser's blits keep sRGB bytes as they are; otherwise
   * a draw that samples and encodes again.
   */
  copyEncoded(texture, sourceFbo, fbo, width, height) {
    const gl = this.gl;
    const flip = fbo === 0;
    if (this.blitKeepsSRGB === undefined) this.blitKeepsSRGB = this.testSRGBBlit();
    if (this.blitKeepsSRGB) {
      gl.bindFramebuffer(GL.READ_FRAMEBUFFER, this.get(sourceFbo));
      gl.readBuffer(GL.COLOR_ATTACHMENT0);
      gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, fbo ? this.get(fbo) : null);
      gl.disable(GL.SCISSOR_TEST);
      gl.blitFramebuffer(0, 0, width, height, 0, flip ? height : 0, width, flip ? 0 : height, GL.COLOR_BUFFER_BIT, GL.NEAREST);
      gl.bindFramebuffer(GL.READ_FRAMEBUFFER, null);
    } else {
      const program = this.encodeProgram();
      gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, fbo ? this.get(fbo) : null);
      gl.viewport(0, 0, width, height);
      for (const cap of [GL.SCISSOR_TEST, GL.DEPTH_TEST, GL.BLEND, GL.CULL_FACE, GL.SAMPLE_ALPHA_TO_COVERAGE, GL.POLYGON_OFFSET_FILL]) gl.disable(cap);
      gl.colorMask(true, true, true, true);
      gl.useProgram(program.program);
      gl.uniform1i(program.flip, flip ? 1 : 0);
      gl.activeTexture(GL.TEXTURE0 + this.scratchUnit);
      gl.bindTexture(GL.TEXTURE_2D, this.get(texture));
      gl.bindSampler(this.scratchUnit, null);
      gl.bindVertexArray(this.scratchVAO);
      gl.drawArrays(GL.TRIANGLES, 0, 3);
      gl.bindTexture(GL.TEXTURE_2D, null);
      gl.bindVertexArray(this.currentVAO);
    }
    gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, null);
    this.drawFramebuffer = null;
    this.invalidate();
    this.checkError("copyEncoded");
  }

  encodeProgram() {
    if (this.presentProgram) return this.presentProgram;
    const gl = this.gl;
    const vs = `#version 300 es
void main() {
    vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}`;
    const fs = `#version 300 es
precision highp float;
uniform highp sampler2D image;
uniform int flip;
out vec4 color;
vec3 encode(vec3 c) {
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}
void main() {
    ivec2 size = textureSize(image, 0);
    ivec2 p = ivec2(gl_FragCoord.xy);
    if (flip != 0) p.y = size.y - 1 - p.y;
    vec4 c = texelFetch(image, p, 0);
    color = vec4(encode(clamp(c.rgb, 0.0, 1.0)), c.a);
}`;
    const program = gl.createProgram();
    for (const [type, source] of [[GL.VERTEX_SHADER, vs], [GL.FRAGMENT_SHADER, fs]]) {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      gl.attachShader(program, shader);
    }
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, GL.LINK_STATUS)) throw new Error(`[acro] sRGB copy program: ${gl.getProgramInfoLog(program)}`);
    gl.useProgram(program);
    gl.uniform1i(gl.getUniformLocation(program, "image"), this.scratchUnit);
    this.presentProgram = { program, flip: gl.getUniformLocation(program, "flip") };
    return this.presentProgram;
  }

  /** Whether blitting an sRGB image into a linear one keeps its bytes (no decoding on the way). */
  testSRGBBlit() {
    const gl = this.gl;
    const make = (format) => {
      const texture = gl.createTexture();
      gl.bindTexture(GL.TEXTURE_2D, texture);
      gl.texStorage2D(GL.TEXTURE_2D, 1, format, 1, 1);
      const fbo = gl.createFramebuffer();
      gl.bindFramebuffer(GL.FRAMEBUFFER, fbo);
      gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
      return { texture, fbo };
    };
    gl.activeTexture(GL.TEXTURE0 + this.scratchUnit);
    const source = make(GL.SRGB8_ALPHA8), target = make(GL.RGBA8);
    gl.bindTexture(GL.TEXTURE_2D, source.texture);
    gl.texSubImage2D(GL.TEXTURE_2D, 0, 0, 0, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, new Uint8Array([128, 64, 200, 255]));
    gl.bindFramebuffer(GL.READ_FRAMEBUFFER, source.fbo);
    gl.bindFramebuffer(GL.DRAW_FRAMEBUFFER, target.fbo);
    gl.disable(GL.SCISSOR_TEST);
    gl.blitFramebuffer(0, 0, 1, 1, 0, 0, 1, 1, GL.COLOR_BUFFER_BIT, GL.NEAREST);
    const pixel = new Uint8Array(4);
    gl.bindFramebuffer(GL.READ_FRAMEBUFFER, target.fbo);
    gl.readPixels(0, 0, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel);
    gl.bindFramebuffer(GL.FRAMEBUFFER, null);
    gl.bindTexture(GL.TEXTURE_2D, null);
    gl.deleteFramebuffer(source.fbo);
    gl.deleteFramebuffer(target.fbo);
    gl.deleteTexture(source.texture);
    gl.deleteTexture(target.texture);
    const keeps = Math.abs(pixel[0] - 128) <= 1 && Math.abs(pixel[1] - 64) <= 1;
    console.log(`[acro] WebGL 2: sRGB blits ${keeps ? "keep their bytes (presenting with a blit)" : "decode (presenting with a draw)"}`);
    return keeps;
  }
}

WebGL2Helper.prototype.clearColor = new Float32Array(4);
WebGL2Helper.prototype.zero4 = new Float32Array(4);
WebGL2Helper.prototype.clearDepth = new Float32Array(1);
