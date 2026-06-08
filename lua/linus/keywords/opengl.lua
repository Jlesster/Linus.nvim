-- linus/keywords/opengl.lua
-- OpenGL core profile (3.3+ / 4.x). Uses `<glad/gl.h>`, `<gl3w.h>`, `<GL/glew.h>`, etc.

return {

  -- ── Vertex Buffer Objects ──────────────────────────────────────────────────

  ["glGenBuffers"] = [[
**`glGenBuffers`** — Generate buffer object names (`<GL/gl.h>`)

```c
GLuint vbo, ebo;
glGenBuffers(1, &vbo);               // single buffer
glGenBuffers(1, &ebo);
glGenBuffers(N, buffers);            // multiple at once

glDeleteBuffers(1, &vbo);           // delete when done
```

**See also:** `glBindBuffer`, `glBufferData`, `glBufferSubData`, `glDeleteBuffers`, `glIsBuffer`]],

  ["glBindBuffer"] = [[
**`glBindBuffer`** — Bind a named buffer object (`<GL/gl.h>`)

```c
glBindBuffer(GL_ARRAY_BUFFER, vbo);          // vertex data
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);  // index data
glBindBuffer(GL_UNIFORM_BUFFER, ubo);        // uniform data
glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo); // shader storage

// Bind 0 to unbind:
glBindBuffer(GL_ARRAY_BUFFER, 0);
```

**See also:** `glGenBuffers`, `glBufferData`, `glBufferSubData`, `glVertexAttribPointer`]],

  ["glBufferData"] = [[
**`glBufferData`** — Upload data to a buffer (`<GL/gl.h>`)

```c
float vertices[] = { ... };
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

// Usage hints:
GL_STATIC_DRAW  // set once, used many times (optimal for GPU)
GL_DYNAMIC_DRAW // updated occasionally, used many times
GL_STREAM_DRAW  // updated once, used a few times

// Subset update:
glBufferSubData(GL_ARRAY_BUFFER, offset, size, new_data);

// Map for direct CPU access:
void *ptr = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
memcpy(ptr, data, size);
glUnmapBuffer(GL_ARRAY_BUFFER);
```

**See also:** `glBindBuffer`, `glBufferSubData`, `glMapBuffer`, `glUnmapBuffer`, `glGenBuffers`]],

  ["glVertexAttribPointer"] = [[
**`glVertexAttribPointer`** — Define vertex attribute layout (`<GL/gl.h>`)

```c
// After binding VBO + VAO:
glVertexAttribPointer(
    0,                             // location (layout(location=0) in shader)
    3,                             // size (vec3 = 3 floats)
    GL_FLOAT,                      // type
    GL_FALSE,                      // normalised?
    5 * sizeof(float),             // stride (bytes between vertices)
    (void*)0                       // offset of this attribute in vertex
);
glEnableVertexAttribArray(0);

// Second attribute (e.g. texcoords):
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3*sizeof(float)));
glEnableVertexAttribArray(1);

// Integer attributes:
glVertexAttribIPointer(loc, 1, GL_INT, stride, offset);  // for ivec in shader
```

**See also:** `glEnableVertexAttribArray`, `glDisableVertexAttribArray`, `glVertexAttribDivisor`, `glBindVertexArray`, `glBindBuffer`]],

  ["glEnableVertexAttribArray"] = [[
**`glEnableVertexAttribArray`** — Enable a vertex attribute array (`<GL/gl.h>`)

```c
glEnableVertexAttribArray(0);   // enable attribute at location 0
glDisableVertexAttribArray(0);  // disable
```

Must be called for each attribute defined with `glVertexAttribPointer`.

**See also:** `glVertexAttribPointer`, `glDisableVertexAttribArray`, `glBindVertexArray`]],

  ["glVertexAttribDivisor"] = [[
**`glVertexAttribDivisor`** — Set instanced attribute divisor (`<GL/gl.h>`)

```c
glVertexAttribDivisor(1, 1);   // advance attribute 1 once per instance
glVertexAttribDivisor(2, 0);   // advance every vertex (default)
glDrawArraysInstanced(GL_TRIANGLES, 0, vertex_count, instance_count);
```

**See also:** `glDrawArraysInstanced`, `glDrawElementsInstanced`, `glVertexAttribPointer`]],

  -- ── VAO ────────────────────────────────────────────────────────────────────

  ["glGenVertexArrays"] = [[
**`glGenVertexArrays`** — Generate vertex array objects (`<GL/gl.h>`)

```c
GLuint vao;
glGenVertexArrays(1, &vao);
glBindVertexArray(vao);

// ... set up VBO, EBO, attrib pointers ...

glBindVertexArray(0);   // unbind

// To draw, just rebind:
glBindVertexArray(vao);
glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0);

glDeleteVertexArrays(1, &vao);
```

VAOs store vertex attribute configuration and bound VBO/EBO state. **Always use VAOs** in core profile (3.3+) — the default VAO does not exist.

**See also:** `glBindVertexArray`, `glDeleteVertexArrays`, `glVertexAttribPointer`, `glEnableVertexAttribArray`]],

  ["glBindVertexArray"] = [[
**`glBindVertexArray`** — Bind a vertex array object (`<GL/gl.h>`)

```c
glBindVertexArray(vao);   // enable VAO
glBindVertexArray(0);     // unbind
```

**See also:** `glGenVertexArrays`, `glDeleteVertexArrays`]],

  -- ── Shaders ────────────────────────────────────────────────────────────────

  ["glCreateShader"] = [[
**`glCreateShader`** — Create a shader object (`<GL/gl.h>`)

```c
GLuint vs = glCreateShader(GL_VERTEX_SHADER);
GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
GLuint gs = glCreateShader(GL_GEOMETRY_SHADER);
GLuint tcs = glCreateShader(GL_TESS_CONTROL_SHADER);
GLuint tes = glCreateShader(GL_TESS_EVALUATION_SHADER);
GLuint cs = glCreateShader(GL_COMPUTE_SHADER);

glDeleteShader(vs);   // free after program is linked
```

**See also:** `glShaderSource`, `glCompileShader`, `glAttachShader`, `glDeleteShader`, `glCreateProgram`, `glGetShaderInfoLog`]],

  ["glShaderSource"] = [[
**`glShaderSource`** — Load shader source code (`<GL/gl.h>`)

```c
const char *src = "#version 330 core\nvoid main() { ... }\n";
glShaderSource(shader, 1, &src, NULL);   // count=1, length=NULL (null-terminated)
```

**See also:** `glCreateShader`, `glCompileShader`, `glGetShaderInfoLog`]],

  ["glCompileShader"] = [[
**`glCompileShader`** — Compile a shader object (`<GL/gl.h>`)

```c
glCompileShader(shader);

GLint success;
glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
if (!success) {
    char log[512];
    glGetShaderInfoLog(shader, sizeof(log), NULL, log);
    fprintf(stderr, "Shader compile error: %s\n", log);
}
```

**See also:** `glCreateShader`, `glShaderSource`, `glGetShaderInfoLog`, `glAttachShader`, `glGetShaderiv`]],

  ["glCreateProgram"] = [[
**`glCreateProgram`** — Create a shader program (`<GL/gl.h>`)

```c
GLuint prog = glCreateProgram();
glAttachShader(prog, vs);
glAttachShader(prog, fs);
glLinkProgram(prog);

// Check:
GLint success;
glGetProgramiv(prog, GL_LINK_STATUS, &success);
if (!success) {
    char log[512];
    glGetProgramInfoLog(prog, sizeof(log), NULL, log);
}

// After linking, shader objects can be deleted:
glDeleteShader(vs);
glDeleteShader(fs);

glUseProgram(prog);     // activate

glDeleteProgram(prog);  // clean up
```

**See also:** `glUseProgram`, `glAttachShader`, `glLinkProgram`, `glValidateProgram`, `glDeleteProgram`, `glGetProgramInfoLog`]],

  ["glUseProgram"] = [[
**`glUseProgram`** — Activate a shader program (`<GL/gl.h>`)

```c
glUseProgram(prog);      // use program for subsequent draw calls
glUseProgram(0);         // disable (fixed-function pipeline, not core profile)
```

**See also:** `glCreateProgram`, `glDeleteProgram`, `glGetAttribLocation`, `glGetUniformLocation`]],

  ["glGetAttribLocation"] = [[
**`glGetAttribLocation`** — Get the location of a vertex attribute (`<GL/gl.h>`)

```c
GLint pos = glGetAttribLocation(prog, "aPosition");
glVertexAttribPointer(pos, 3, GL_FLOAT, GL_FALSE, stride, offset);
glEnableVertexAttribArray(pos);
```

Returns -1 if the attribute is not active (optimised out). Prefer explicit `layout(location=N)` in shaders to avoid runtime lookups.

**See also:** `glGetUniformLocation`, `glBindAttribLocation`, `glVertexAttribPointer`]],

  ["glGetUniformLocation"] = [[
**`glGetUniformLocation`** — Get the location of a uniform variable (`<GL/gl.h>`)

```c
GLint loc = glGetUniformLocation(prog, "uModelViewProjection");
if (loc != -1) {
    glUniformMatrix4fv(loc, 1, GL_FALSE, &matrix[0][0]);
}
```

Returns -1 if the uniform is not active (optimised out). Cache uniform locations after program creation.

**See also:** `glUniform*`, `glUseProgram`, `glGetAttribLocation`]],

  -- ── Uniforms ───────────────────────────────────────────────────────────────

  ["glUniform"] = [[
**`glUniform`** — Set uniform values (`<GL/gl.h>`)

```c
glUniform1f(loc, 3.14f);                  // float
glUniform2f(loc, x, y);                   // vec2
glUniform3f(loc, r, g, b);                // vec3
glUniform4f(loc, r, g, b, a);             // vec4
glUniform1i(loc, 42);                     // int / sampler2D
glUniform3fv(loc, count, array);          // vec3 array
glUniformMatrix4fv(loc, 1, GL_FALSE, ptr); // mat4
glUniformMatrix3fv(loc, 1, GL_FALSE, ptr); // mat3

// GL_TRUE would transpose (row↔column) — never use with GLM/row-major libs
```

**See also:** `glGetUniformLocation`, `glUseProgram`, `glUniformBlockBinding`, `glProgramUniform`]],

  -- ── Textures ───────────────────────────────────────────────────────────────

  ["glGenTextures"] = [[
**`glGenTextures`** — Generate texture objects (`<GL/gl.h>`)

```c
GLuint tex;
glGenTextures(1, &tex);
glBindTexture(GL_TEXTURE_2D, tex);

// Upload image data:
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
glGenerateMipmap(GL_TEXTURE_2D);

// Set parameters:
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

glDeleteTextures(1, &tex);   // clean up
```

**See also:** `glBindTexture`, `glTexImage2D`, `glTexParameteri`, `glGenerateMipmap`, `glActiveTexture`, `glDeleteTextures`]],

  ["glBindTexture"] = [[
**`glBindTexture`** — Bind a named texture (`<GL/gl.h>`)

```c
glBindTexture(GL_TEXTURE_2D, tex);
glBindTexture(GL_TEXTURE_2D, 0);   // unbind
```

**See also:** `glGenTextures`, `glActiveTexture`, `glDeleteTextures`, `glTexImage2D`]],

  ["glTexImage2D"] = [[
**`glTexImage2D`** — Upload a 2D texture image (`<GL/gl.h>`)

```c
glTexImage2D(
    GL_TEXTURE_2D,       // target
    0,                   // mipmap level
    GL_RGBA,             // internal format (storage format on GPU)
    width, height,
    0,                   // border (must be 0)
    GL_RGBA,             // pixel data format
    GL_UNSIGNED_BYTE,    // pixel data type
    pixels               // source data (NULL = allocate without uploading)
);

// Internal format choices:
// GL_RGB, GL_RGBA, GL_SRGB, GL_SRGB_ALPHA,
// GL_R16F, GL_RG16F, GL_RGB16F, GL_RGBA16F, GL_RGB32F, GL_RGBA32F,
// GL_DEPTH_COMPONENT24, GL_DEPTH_COMPONENT32F,
// GL_RED, GL_RG, GL_RGB, GL_RGBA (base)
```

**See also:** `glGenTextures`, `glTexSubImage2D`, `glTexParameteri`, `glGenerateMipmap`, `glGetTexImage`]],

  ["glTexParameteri"] = [[
**`glTexParameteri`** — Set texture parameters (`<GL/gl.h>`)

```c
// Filtering:
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

// Wrapping:
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);     // or GL_CLAMP_TO_EDGE
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);     // or GL_MIRRORED_REPEAT
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_REPEAT);     // 3D textures

// Border colour (when using GL_CLAMP_TO_BORDER):
float border[] = {1.0, 0.0, 0.0, 1.0};
glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, border);
```

**See also:** `glTexParameterf`, `glTexParameterfv`, `glTexParameterIiv`, `glGenerateMipmap`]],

  ["glGenerateMipmap"] = [[
**`glGenerateMipmap`** — Generate mipmaps for a bound texture (`<GL/gl.h>`)

```c
glGenerateMipmap(GL_TEXTURE_2D);   // requires GL_ARB_framebuffer_object (core 3.0+)
```

Must set `GL_TEXTURE_MIN_FILTER` to `GL_LINEAR_MIPMAP_LINEAR` (or similar) for mipmaps to have effect.

**See also:** `glTexImage2D`, `glTexParameteri`, `glActiveTexture`]],

  ["glActiveTexture"] = [[
**`glActiveTexture`** — Select active texture unit (`<GL/gl.h>`)

```c
glActiveTexture(GL_TEXTURE0);     // texture unit 0
glBindTexture(GL_TEXTURE_2D, tex0);
glActiveTexture(GL_TEXTURE1);     // texture unit 1
glBindTexture(GL_TEXTURE_2D, tex1);

// In shader:
// uniform sampler2D uTex0, uTex1;
glUniform1i(glGetUniformLocation(prog, "uTex0"), 0);   // bind to unit 0
glUniform1i(glGetUniformLocation(prog, "uTex1"), 1);   // bind to unit 1
```

OpenGL guarantees at least 32 texture units (`GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS`).

**See also:** `glBindTexture`, `glGenTextures`, `glUniform1i`]],

  -- ── Framebuffers ───────────────────────────────────────────────────────────

  ["glGenFramebuffers"] = [[
**`glGenFramebuffers`** — Generate framebuffer objects (FBO) (`<GL/gl.h>`)

```c
GLuint fbo;
glGenFramebuffers(1, &fbo);
glBindFramebuffer(GL_FRAMEBUFFER, fbo);

// Attach colour texture:
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);

// Attach depth/stencil renderbuffer:
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

// Check completeness:
if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    // error
}

glBindFramebuffer(GL_FRAMEBUFFER, 0);    // back to default framebuffer
glDeleteFramebuffers(1, &fbo);           // clean up
```

**See also:** `glBindFramebuffer`, `glFramebufferTexture2D`, `glFramebufferRenderbuffer`, `glCheckFramebufferStatus`, `glBlitFramebuffer`, `glGenRenderbuffers`]],

  ["glBindFramebuffer"] = [[
**`glBindFramebuffer`** — Bind an FBO (`<GL/gl.h>`)

```c
glBindFramebuffer(GL_FRAMEBUFFER, fbo);   // read + draw
glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);  // read-only (for glBlitFramebuffer, glReadPixels)
glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);  // draw-only
glBindFramebuffer(GL_FRAMEBUFFER, 0);     // back to default
```

**See also:** `glGenFramebuffers`, `glCheckFramebufferStatus`, `glBlitFramebuffer`]],

  ["glCheckFramebufferStatus"] = [[
**`glCheckFramebufferStatus`** — Check FBO completeness (`<GL/gl.h>`)

```c
GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
if (status != GL_FRAMEBUFFER_COMPLETE) {
    switch (status) {
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:        // attachment not complete
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: // no attachments bound
        case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:        // missing draw buffer
        case GL_FRAMEBUFFER_UNSUPPORTED:                   // format not supported
    }
}
```

**See also:** `glGenFramebuffers`, `glBindFramebuffer`]],

  ["glBlitFramebuffer"] = [[
**`glBlitFramebuffer`** — Copy a region of pixels between framebuffers (`<GL/gl.h>`)

```c
glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo_src);
glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);          // blit to screen
glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_NEAREST);
```

Useful for picking, post-processing, and resolving multisampled FBOs.

**See also:** `glBindFramebuffer`, `glReadPixels`, `glGenFramebuffers`]],

  ["glGenRenderbuffers"] = [[
**`glGenRenderbuffers`** — Generate renderbuffer objects (`<GL/gl.h>`)

```c
GLuint rbo;
glGenRenderbuffers(1, &rbo);
glBindRenderbuffer(GL_RENDERBUFFER, rbo);
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);
glDeleteRenderbuffers(1, &rbo);
```

Renderbuffers are optimised for off-screen framebuffer attachments (depth, stencil, multisampled colour). Unlike textures, they cannot be sampled directly.

**See also:** `glGenFramebuffers`, `glBindRenderbuffer`, `glRenderbufferStorage`, `glRenderbufferStorageMultisample`, `glFramebufferRenderbuffer`]],

  -- ── Drawing ────────────────────────────────────────────────────────────────

  ["glDrawArrays"] = [[
**`glDrawArrays`** — Render primitives from vertex arrays (`<GL/gl.h>`)

```c
glDrawArrays(GL_TRIANGLES, 0, vertex_count);          // triangles
glDrawArrays(GL_TRIANGLE_STRIP, 0, vertex_count);     // triangle strip
glDrawArrays(GL_LINES, 0, vertex_count);              // lines
glDrawArrays(GL_POINTS, 0, vertex_count);             // points
glDrawArrays(GL_TRIANGLE_FAN, 0, vertex_count);       // triangle fan

// Instanced:
glDrawArraysInstanced(GL_TRIANGLES, 0, vertex_count, instance_count);
```

**See also:** `glDrawElements`, `glDrawArraysInstanced`, `glDrawElementsInstanced`, `glDrawArraysIndirect`, `glMultiDrawArrays`]],

  ["glDrawElements"] = [[
**`glDrawElements`** — Render indexed primitives (`<GL/gl.h>`)

```c
glDrawElements(GL_TRIANGLES, index_count, GL_UNSIGNED_INT, 0);
// index count, index type (UNSIGNED_BYTE, UNSIGNED_SHORT, UNSIGNED_INT), offset

// With base vertex:
glDrawElementsBaseVertex(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0, base_vertex);
```

Requires an element buffer bound to `GL_ELEMENT_ARRAY_BUFFER`.

**See also:** `glDrawArrays`, `glDrawElementsInstanced`, `glDrawElementsBaseVertex`, `glDrawRangeElements`]],

  ["glDrawArraysInstanced"] = [[
**`glDrawArraysInstanced`** — Draw multiple instances of vertex data (`<GL/gl.h>`)

```c
glDrawArraysInstanced(GL_TRIANGLES, 0, vertex_count, instance_count);
// Use gl_InstanceID in shader + glVertexAttribDivisor for per-instance data
```

**See also:** `glDrawArrays`, `glDrawElementsInstanced`, `glVertexAttribDivisor`, `gl_InstanceID`]],

  -- ── State ──────────────────────────────────────────────────────────────────

  ["glEnable"] = [[
**`glEnable`** / **`glDisable`** — Enable/disable OpenGL capabilities (`<GL/gl.h>`)

```c
glEnable(GL_DEPTH_TEST);       // depth testing
glEnable(GL_BLEND);            // blending
glEnable(GL_CULL_FACE);        // face culling
glEnable(GL_STENCIL_TEST);     // stencil testing
glEnable(GL_SCISSOR_TEST);     // scissor testing
glEnable(GL_MULTISAMPLE);      // multisample anti-aliasing

glDisable(GL_DEPTH_TEST);      // disable when needed

// Depth:
glDepthFunc(GL_LESS);          // default, also GL_LEQUAL, GL_EQUAL, GL_GREATER

// Blending:
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  // standard alpha blending
glBlendEquation(GL_FUNC_ADD);  // default, also GL_FUNC_SUBTRACT, GL_FUNC_REVERSE_SUBTRACT, GL_MIN, GL_MAX

// Culling:
glCullFace(GL_BACK);           // cull back faces (default)
glFrontFace(GL_CCW);           // counter-clockwise winding = front (default)
```

**See also:** `glDepthFunc`, `glBlendFunc`, `glBlendEquation`, `glCullFace`, `glFrontFace`, `glPolygonMode`, `glStencilFunc`, `glStencilOp`]],

  ["glClearColor"] = [[
**`glClearColor`** — Specify clear colour (`<GL/gl.h>`)

```c
glClearColor(0.1f, 0.2f, 0.3f, 1.0f);  // dark blue-grey
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  // clear colour + depth
```

**See also:** `glClear`, `glClearDepth`, `glClearStencil`, `glColorMask`]],

  ["glClear"] = [[
**`glClear`** — Clear buffers to preset values (`<GL/gl.h>`)

```c
glClear(GL_COLOR_BUFFER_BIT);                 // colour only
glClear(GL_DEPTH_BUFFER_BIT);                 // depth only
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  // both
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
```

**See also:** `glClearColor`, `glClearDepth`, `glClearStencil`, `glColorMask`, `glDepthMask`]],

  ["glViewport"] = [[
**`glViewport`** — Set the visible rendering region (`<GL/gl.h>`)

```c
glViewport(0, 0, width, height);   // x, y, w, h
```

Must be called after window resize. Typically set in the window resize callback.

**See also:** `glScissor`, `glClear`, `glEnable(GL_SCISSOR_TEST)`]],

  ["glPolygonMode"] = [[
**`glPolygonMode`** — Control polygon rasterisation (`<GL/gl.h>`)

```c
glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);   // fill (default)
glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);   // wireframe
glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);  // point cloud
```

**See also:** `glEnable`, `glCullFace`, `glLineWidth`]],

  ["glScissor"] = [[
**`glScissor`** — Define the scissor box (`<GL/gl.h>`)

```c
glScissor(x, y, width, height);
glEnable(GL_SCISSOR_TEST);    // activate scissor test
```

**See also:** `glViewport`, `glEnable`]],

  -- ── Queries and Sync ───────────────────────────────────────────────────────

  ["glGenQueries"] = [[
**`glGenQueries`** — Generate query objects (`<GL/gl.h>`)

```c
GLuint query;
glGenQueries(1, &query);

glBeginQuery(GL_SAMPLES_PASSED, query);     // occlusion query
// draw something
glEndQuery(GL_SAMPLES_PASSED);

GLuint result;
glGetQueryObjectuiv(query, GL_QUERY_RESULT, &result);  // blocks until available
glGetQueryObjectuiv(query, GL_QUERY_RESULT_AVAILABLE, &result);  // non-blocking check

// Other query targets:
// GL_TIME_ELAPSED, GL_PRIMITIVES_GENERATED, GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN
```

**See also:** `glBeginQuery`, `glEndQuery`, `glGetQueryObjectuiv`, `glGetQueryiv`, `glDeleteQueries`, `glQueryCounter`]],

  ["glFenceSync"] = [[
**`glFenceSync`** — Create a synchronisation fence (`<GL/gl.h>`)

```c
GLsync fence = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

// Wait on CPU (blocks until GPU reaches the fence):
GLenum wait = glClientWaitSync(fence, GL_SYNC_FLUSH_COMMANDS_BIT, 1000000000);
if (wait == GL_ALREADY_SIGNALED)  { /* GPU finished before we waited */ }
if (wait == GL_CONDITION_SATISFIED) { /* GPU finished within timeout */ }
if (wait == GL_TIMEOUT_EXPIRED)   { /* timeout, GPU still working */ }

glDeleteSync(fence);
```

**See also:** `glClientWaitSync`, `glWaitSync`, `glDeleteSync`, `glGetSynciv`]],
}
