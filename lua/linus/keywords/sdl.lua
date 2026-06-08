-- linus/keywords/sdl.lua
-- SDL2 / SDL3 (Simple Directmedia Layer).

return {

  -- ── Init / Quit ────────────────────────────────────────────────────────────

  ["SDL_Init"] = [[
**`SDL_Init`** — Initialise SDL subsystems (`<SDL.h>`)

```c
#include <SDL.h>

if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
}
// ... use SDL ...
SDL_Quit();
```

| Flag | Subsystem |
|------|-----------|
| `SDL_INIT_TIMER` | Timer |
| `SDL_INIT_AUDIO` | Audio |
| `SDL_INIT_VIDEO` | Video (also enables Events) |
| `SDL_INIT_JOYSTICK` | Joystick (implied by GAMECONTROLLER) |
| `SDL_INIT_GAMECONTROLLER` | Game controller |
| `SDL_INIT_EVENTS` | Event subsystem |
| `SDL_INIT_EVERYTHING` | All above |

SDL3: `SDL_Init(SDL_INIT_VIDEO)` returns bool (true on success).

**See also:** `SDL_Quit`, `SDL_InitSubSystem`, `SDL_QuitSubSystem`, `SDL_WasInit`]],

  ["SDL_Quit"] = [[
**`SDL_Quit`** — Shut down all SDL subsystems (`<SDL.h>`)

```c
SDL_Quit();   // clean up all subsystems, call at exit
```

**See also:** `SDL_Init`, `SDL_QuitSubSystem`]],

  ["SDL_GetError"] = [[
**`SDL_GetError`** — Get last SDL error message (`<SDL.h>`)

```c
const char *err = SDL_GetError();
```

Returns a thread-local string describing the last SDL operation error. Check after any SDL function that returns a failure indicator.

**See also:** `SDL_ClearError`, `SDL_SetError`]],

  -- ── Window ─────────────────────────────────────────────────────────────────

  ["SDL_CreateWindow"] = [[
**`SDL_CreateWindow`** — Create a window (`<SDL.h>`)

```c
SDL_Window *win = SDL_CreateWindow(
    "Title",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,  // x, y
    800, 600,                                           // w, h
    SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
);

if (!win) { fprintf(stderr, "Window: %s\n", SDL_GetError()); }

SDL_DestroyWindow(win);   // clean up

// SDL3: SDL_CreateWindow("Title", 800, 600, SDL_WINDOW_RESIZABLE);
```

SDL3 drops `x`/`y`/`SDL_WINDOWPOS_UNDEFINED` parameters. Use `SDL_SetWindowPosition()` to position.

**See also:** `SDL_DestroyWindow`, `SDL_SetWindowTitle`, `SDL_SetWindowSize`, `SDL_GetWindowSurface`, `SDL_UpdateWindowSurface`]],

  ["SDL_DestroyWindow"] = [[
**`SDL_DestroyWindow`** — Destroy a window (`<SDL.h>`)

```c
SDL_DestroyWindow(win);
```

Frees the window and its associated surface. Window must NOT be used after this call.

**See also:** `SDL_CreateWindow`, `SDL_GetWindowSurface`]],

  ["SDL_SetWindowTitle"] = [[
**`SDL_SetWindowTitle`** — Change window title (`<SDL.h>`)

```c
SDL_SetWindowTitle(win, "New Title");
```

**See also:** `SDL_GetWindowTitle`, `SDL_CreateWindow`]],

  ["SDL_SetWindowSize"] = [[
**`SDL_SetWindowSize`** — Change window size (`<SDL.h>`)

```c
SDL_SetWindowSize(win, 1024, 768);
SDL_GetWindowSize(win, &w, &h);   // query current size
```

**See also:** `SDL_SetWindowPosition`, `SDL_GetWindowSize`, `SDL_MaximizeWindow`, `SDL_SetWindowFullscreen`]],

  ["SDL_SetWindowFullscreen"] = [[
**`SDL_SetWindowFullscreen`** — Set window to fullscreen (`<SDL.h>`)

```c
SDL_SetWindowFullscreen(win, SDL_WINDOW_FULLSCREEN);          // exclusive
SDL_SetWindowFullscreen(win, SDL_WINDOW_FULLSCREEN_DESKTOP);  // borderless
SDL_SetWindowFullscreen(win, 0);                               // windowed
```

**See also:** `SDL_GetWindowFlags`, `SDL_SetWindowSize`]],

  -- ── Renderer ───────────────────────────────────────────────────────────────

  ["SDL_CreateRenderer"] = [[
**`SDL_CreateRenderer`** — Create a 2D renderer for a window (`<SDL.h>`)

```c
SDL_Renderer *ren = SDL_CreateRenderer(
    win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
);

if (!ren) { /* error */ }

SDL_DestroyRenderer(ren);   // clean up

// SDL3: SDL_CreateRenderer(win, NULL);
```

| Flag | Meaning |
|------|---------|
| `SDL_RENDERER_SOFTWARE` | Software renderer |
| `SDL_RENDERER_ACCELERATED` | Hardware-accelerated |
| `SDL_RENDERER_PRESENTVSYNC` | Vsync |
| `SDL_RENDERER_TARGETTEXTURE` | Render-to-texture support |

SDL3 uses a `SDL_Renderer *` returned as the default, and the `name` parameter (second) is `NULL` for default.

**See also:** `SDL_DestroyRenderer`, `SDL_RenderClear`, `SDL_RenderPresent`, `SDL_CreateTexture`]],

  ["SDL_DestroyRenderer"] = [[
**`SDL_DestroyRenderer`** — Destroy a renderer (`<SDL.h>`)

```c
SDL_DestroyRenderer(ren);
```

Destroy before the associated window.

**See also:** `SDL_CreateRenderer`, `SDL_DestroyWindow`]],

  ["SDL_RenderClear"] = [[
**`SDL_RenderClear`** — Clear the current rendering target with draw colour (`<SDL.h>`)

```c
SDL_SetRenderDrawColor(ren, r, g, b, a);
SDL_RenderClear(ren);
```

**See also:** `SDL_SetRenderDrawColor`, `SDL_RenderPresent`]],

  ["SDL_RenderPresent"] = [[
**`SDL_RenderPresent`** — Swap buffers and present to screen (`<SDL.h>`)

```c
SDL_RenderPresent(ren);   // update screen with all render commands since last present
```

**See also:** `SDL_RenderClear`, `SDL_RenderCopy`, `SDL_CreateRenderer`]],

  ["SDL_SetRenderDrawColor"] = [[
**`SDL_SetRenderDrawColor`** — Set colour for drawing operations (`<SDL.h>`)

```c
SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);   // red, fully opaque
```

rgba values 0–255. Affects `SDL_RenderClear`, `SDL_RenderDrawLine`, `SDL_RenderDrawRect`, `SDL_RenderFillRect`.

**See also:** `SDL_RenderClear`, `SDL_RenderDrawLine`, `SDL_RenderFillRect`]],

  ["SDL_RenderDrawLine"] = [[
**`SDL_RenderDrawLine`** — Draw a line between two points (`<SDL.h>`)

```c
SDL_RenderDrawLine(ren, x1, y1, x2, y2);          // single line
SDL_RenderDrawLines(ren, points, count);           // multiple lines
```

**See also:** `SDL_SetRenderDrawColor`, `SDL_RenderDrawPoint`, `SDL_RenderDrawRect`, `SDL_RenderFillRect`]],

  ["SDL_RenderFillRect"] = [[
**`SDL_RenderFillRect`** — Fill a rectangle (`<SDL.h>`)

```c
SDL_Rect rect = { .x = 10, .y = 20, .w = 100, .h = 50 };
SDL_RenderFillRect(ren, &rect);         // filled rect
SDL_RenderDrawRect(ren, &rect);         // outline only
SDL_RenderFillRects(ren, rects, count); // multiple
```

**See also:** `SDL_RenderDrawRect`, `SDL_SetRenderDrawColor`, `SDL_RenderClear`]],

  ["SDL_RenderCopy"] = [[
**`SDL_RenderCopy`** — Copy a texture to the render target (`<SDL.h>`)

```c
SDL_RenderCopy(ren, tex, &src_rect, &dest_rect);
// src_rect = portion of texture (NULL = full), dest_rect = target (NULL = full)

// With rotation (SDL2):
SDL_RenderCopyEx(ren, tex, &src, &dest, angle, &center, SDL_FLIP_NONE);
```

**See also:** `SDL_CreateTexture`, `SDL_RenderClear`, `SDL_RenderPresent`]],

  ["SDL_RenderCopyEx"] = [[
**`SDL_RenderCopyEx`** — Copy a texture with rotation and flipping (`<SDL.h>`)

```c
SDL_RenderCopyEx(ren, tex, &src, &dest, angle, &center, SDL_FLIP_NONE);
// angle in degrees, center = rotation pivot point, flip = SDL_FLIP_NONE/HORIZONTAL/VERTICAL
```

SDL3: combined into `SDL_RenderTextureRotated()`.

**See also:** `SDL_RenderCopy`, `SDL_CreateTexture`]],

  -- ── Texture ────────────────────────────────────────────────────────────────

  ["SDL_CreateTexture"] = [[
**`SDL_CreateTexture`** — Create a texture (`<SDL.h>`)

```c
SDL_Texture *tex = SDL_CreateTexture(
    ren,
    SDL_PIXELFORMAT_RGBA8888,       // pixel format
    SDL_TEXTUREACCESS_STATIC,        // access pattern
    width, height
);

if (!tex) { /* error */ }

SDL_DestroyTexture(tex);   // clean up

// From surface:
SDL_Texture *tex = SDL_CreateTextureFromSurface(ren, surf);
```

| Access | Usage |
|--------|-------|
| `SDL_TEXTUREACCESS_STATIC` | Upload rarely, render often |
| `SDL_TEXTUREACCESS_STREAMING` | Update frequently (SDL_UpdateTexture) |
| `SDL_TEXTUREACCESS_TARGET` | Render-to-texture |

**See also:** `SDL_DestroyTexture`, `SDL_UpdateTexture`, `SDL_RenderCopy`, `SDL_CreateTextureFromSurface`]],

  ["SDL_DestroyTexture"] = [[
**`SDL_DestroyTexture`** — Destroy a texture (`<SDL.h>`)

```c
SDL_DestroyTexture(tex);
```

**See also:** `SDL_CreateTexture`, `SDL_CreateTextureFromSurface`]],

  ["SDL_UpdateTexture"] = [[
**`SDL_UpdateTexture`** — Update a texture with new pixel data (`<SDL.h>`)

```c
SDL_UpdateTexture(tex, NULL, pixels, pitch);
// rect = region to update (NULL = entire texture)
// pixels = RGBA pixel data, pitch = row width in bytes (w * 4 for RGBA8888)

// Streaming texture (better for frequent updates):
void *pixels;
int pitch;
SDL_LockTexture(tex, NULL, &pixels, &pitch);
// write pixels directly
SDL_UnlockTexture(tex);
```

**See also:** `SDL_CreateTexture`, `SDL_LockTexture`, `SDL_UnlockTexture`, `SDL_QueryTexture`]],

  ["SDL_QueryTexture"] = [[
**`SDL_QueryTexture`** — Query texture attributes (`<SDL.h>`)

```c
uint32_t format;
int w, h;
SDL_QueryTexture(tex, &format, NULL, &w, &h);
```

**See also:** `SDL_GetTextureBlendMode`, `SDL_SetTextureBlendMode`, `SDL_SetTextureAlphaMod`]],

  ["SDL_SetTextureBlendMode"] = [[
**`SDL_SetTextureBlendMode`** — Set texture blend mode (`<SDL.h>`)

```c
SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);    // alpha blending
SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_ADD);      // additive
SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_MOD);      // colour modulate
SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_NONE);     // opaque
```

**See also:** `SDL_GetTextureBlendMode`, `SDL_SetTextureAlphaMod`, `SDL_SetTextureColorMod`]],

  -- ── Surface ────────────────────────────────────────────────────────────────

  ["SDL_CreateRGBSurface"] = [[
**`SDL_CreateRGBSurface`** — Create an empty surface (`<SDL.h>`)

```c
SDL_Surface *surf = SDL_CreateRGBSurface(0, w, h, 32,
    0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);

SDL_Surface *surf = SDL_LoadBMP("image.bmp");   // load BMP
SDL_Surface *surf = IMG_Load("image.png");       // load PNG (SDL_image)

SDL_FreeSurface(surf);   // clean up
```

SDL3 uses `SDL_Surface` with different pixel format API.

**See also:** `SDL_FreeSurface`, `SDL_BlitSurface`, `SDL_FillRect`, `SDL_ConvertSurface`, `SDL_CreateTextureFromSurface`]],

  ["SDL_BlitSurface"] = [[
**`SDL_BlitSurface`** — Blit (copy) a surface to another (`<SDL.h>`)

```c
SDL_BlitSurface(src, &src_rect, dst, &dst_rect);           // simple blit
SDL_BlitScaled(src, &src_rect, dst, &dst_rect);             // scaled blit
SDL_UpperBlit(src, &src_rect, dst, &dst_rect);              // surface blit
SDL_SoftStretch(src, &src_rect, dst, &dst_rect);            // stretch blit
```

**See also:** `SDL_CreateRGBSurface`, `SDL_ConvertSurface`, `SDL_FillRect`]],

  ["SDL_FillRect"] = [[
**`SDL_FillRect`** — Fill a rectangle on a surface with a colour (`<SDL.h>`)

```c
SDL_FillRect(surf, NULL, SDL_MapRGB(surf->format, 255, 0, 0));  // fill entire surface red
SDL_Rect rect = { 10, 10, 50, 50 };
SDL_FillRect(surf, &rect, SDL_MapRGBA(surf->format, 0, 255, 0, 255));
```

**See also:** `SDL_MapRGB`, `SDL_MapRGBA`, `SDL_BlitSurface`, `SDL_FreeSurface`]],

  -- ── Events ─────────────────────────────────────────────────────────────────

  ["SDL_PollEvent"] = [[
**`SDL_PollEvent`** — Poll for pending events (`<SDL.h>`)

```c
SDL_Event e;
while (SDL_PollEvent(&e)) {
    switch (e.type) {
        case SDL_QUIT:           running = false; break;
        case SDL_KEYDOWN:        handle_key(e.key); break;
        case SDL_MOUSEBUTTONDOWN: handle_mouse(e.button); break;
        case SDL_WINDOWEVENT:    handle_window(e.window); break;
    }
}
```

Returns 1 if event was available, 0 otherwise. Non-blocking — use `SDL_WaitEvent` to block.

SDL3: `e.type` values use `SDL_EVENT_QUIT`, `SDL_EVENT_KEY_DOWN`, etc.

**See also:** `SDL_WaitEvent`, `SDL_PushEvent`, `SDL_SetEventFilter`]],

  ["SDL_WaitEvent"] = [[
**`SDL_WaitEvent`** — Block until an event arrives (`<SDL.h>`)

```c
SDL_Event e;
SDL_WaitEvent(&e);        // blocks until event is available
```

Alternative to `SDL_PollEvent` when you want to idle between frames. Combine with `SDL_WaitEventTimeout` for periodic wakeups.

**See also:** `SDL_PollEvent`, `SDL_WaitEventTimeout`, `SDL_PushEvent`]],

  ["SDL_PushEvent"] = [[
**`SDL_PushEvent`** — Push a user-defined event into the queue (`<SDL.h>`)

```c
SDL_Event e;
e.type = SDL_USEREVENT;
e.user.code = 42;
e.user.data1 = ptr;
SDL_PushEvent(&e);
```

User events: `SDL_USEREVENT` and up (`SDL_USEREVENT + N`). Useful for cross-thread signalling.

**See also:** `SDL_PollEvent`, `SDL_WaitEvent`, `SDL_RegisterEvents`]],

  ["SDL_USEREVENT"] = [[
**`SDL_USEREVENT`** — User-defined event type base (`<SDL.h>`)

```c
#define MY_EVENT  (SDL_USEREVENT + 0)
#define OTHER_EVT (SDL_USEREVENT + 1)

// Register to ensure uniqueness:
static uint32_t MY_EVENT = SDL_RegisterEvents(1);
```

Up to `SDL_USEREVENT` + `SDL_NUMEVENTS` - `SDL_USEREVENT` - 1 user events available.

**See also:** `SDL_PushEvent`, `SDL_RegisterEvents`, `SDL_PollEvent`]],

  -- ── Keyboard ───────────────────────────────────────────────────────────────

  ["SDL_GetKeyboardState"] = [[
**`SDL_GetKeyboardState`** — Query the state of all keys (`<SDL.h>`)

```c
const uint8_t *keys = SDL_GetKeyboardState(NULL);
if (keys[SDL_SCANCODE_SPACE])  { /* space is held */ }
if (keys[SDL_SCANCODE_ESCAPE]) { /* esc is held */ }

// From SDL_KEYDOWN:
// e.key.keysym.scancode = SDL_SCANCODE_*
// e.key.keysym.sym = SDLK_*

// SDL3 scancodes: SDL_SCANCODE_SPACE, SDL_SCANCODE_W, etc.
```

`SDL_SCANCODE_*` vs `SDL_*`: scancodes are physical key positions; syms are interpreted values (affected by keyboard layout).

**See also:** `SDL_PollEvent`, `SDL_Keycode`, `SDL_Scancode`, `SDL_GetModState`, `SDL_GetKeyName`]],

  ["SDL_GetModState"] = [[
**`SDL_GetModState`** — Get current modifier key state (`<SDL.h>`)

```c
SDL_Keymod mod = SDL_GetModState();
if (mod & KMOD_SHIFT) { /* shift held */ }
if (mod & KMOD_CTRL)  { /* ctrl held */ }
if (mod & KMOD_ALT)   { /* alt held */ }
```

| Flag | Modifier |
|------|----------|
| `KMOD_SHIFT` | Shift (left or right) |
| `KMOD_CTRL` | Ctrl |
| `KMOD_ALT` | Alt |
| `KMOD_GUI` | Windows/Command key |

**See also:** `SDL_GetKeyboardState`, `SDL_PollEvent`]],

  -- ── Mouse ──────────────────────────────────────────────────────────────────

  ["SDL_GetMouseState"] = [[
**`SDL_GetMouseState`** — Get mouse cursor position and button state (`<SDL.h>`)

```c
int x, y;
uint32_t buttons = SDL_GetMouseState(&x, &y);

if (buttons & SDL_BUTTON_LMASK)  { /* left button held */ }
if (buttons & SDL_BUTTON_RMASK)  { /* right button held */ }

// Set cursor position:
SDL_WarpMouseInWindow(win, x, y);

// Show/hide:
SDL_ShowCursor(SDL_DISABLE);
SDL_ShowCursor(SDL_ENABLE);

// Relative mode (FPS cameras):
SDL_SetRelativeMouseMode(SDL_TRUE);
```

**See also:** `SDL_PollEvent`, `SDL_ShowCursor`, `SDL_SetRelativeMouseMode`, `SDL_CaptureMouse`]],

  ["SDL_ShowCursor"] = [[
**`SDL_ShowCursor`** — Show or hide the mouse cursor (`<SDL.h>`)

```c
SDL_ShowCursor(SDL_ENABLE);    // show
SDL_ShowCursor(SDL_DISABLE);   // hide
int shown = SDL_ShowCursor(SDL_QUERY);  // query current state
```

Returns previous visibility state. SDL3: `SDL_HideCursor()`, `SDL_ShowCursor()`, `SDL_CursorVisible()`.

**See also:** `SDL_GetMouseState`, `SDL_SetRelativeMouseMode`, `SDL_CreateCursor`, `SDL_CreateColorCursor`, `SDL_CreateSystemCursor`]],

  -- ── Timer ───────────────────────────────────────────────────────────────────

  ["SDL_GetTicks"] = [[
**`SDL_GetTicks`** — Get milliseconds since SDL initialised (`<SDL.h>`)

```c
uint32_t now = SDL_GetTicks();
uint32_t then = SDL_GetTicks() - 5000;  // 5 seconds ago

SDL_Delay(16);   // sleep ~16ms (≈60fps)

// Frame-rate limiter:
uint32_t start = SDL_GetTicks();
// ... render ...
uint32_t elapsed = SDL_GetTicks() - start;
if (elapsed < 16) SDL_Delay(16 - elapsed);
```

SDL3: returns 64-bit `uint64_t`. Wraps around after ~49 days in SDL2.

**See also:** `SDL_Delay`, `SDL_GetPerformanceCounter`, `SDL_GetPerformanceFrequency`, `SDL_AddTimer`]],

  ["SDL_Delay"] = [[
**`SDL_Delay`** — Wait for a specified number of milliseconds (`<SDL.h>`)

```c
SDL_Delay(1000);    // sleep for 1 second
```

Blocks the calling thread. For non-blocking delays, use `SDL_AddTimer` + event callback.

**See also:** `SDL_GetTicks`, `SDL_AddTimer`, `SDL_RemoveTimer`]],

  -- ── Audio ──────────────────────────────────────────────────────────────────

  ["SDL_OpenAudio"] = [[
**`SDL_OpenAudio`** — Open audio device (`<SDL.h>`)

```c
// SDL2:
SDL_AudioSpec want = {0};
want.freq = 44100;
want.format = AUDIO_S16SYS;
want.channels = 2;
want.samples = 4096;
want.callback = audio_callback;

SDL_AudioSpec have;
if (SDL_OpenAudio(&want, &have) < 0) {
    fprintf(stderr, "Audio: %s\n", SDL_GetError());
}
SDL_PauseAudio(0);   // start playback

// ... later ...
SDL_CloseAudio();
```

SDL3: uses `SDL_OpenAudioDeviceStream` instead.

**See also:** `SDL_PauseAudio`, `SDL_CloseAudio`, `SDL_QueueAudio`, `SDL_LoadWAV`, `SDL_MixAudioFormat`]],

  ["SDL_QueueAudio"] = [[
**`SDL_QueueAudio`** — Queue audio data for playback (`<SDL.h>`)

```c
SDL_QueueAudio(device_id, data, len);
uint32_t queued = SDL_GetQueuedAudioSize(device_id);
SDL_ClearQueuedAudio(device_id);
```

Simpler than the callback approach — just feed bytes. Works with `SDL_OpenAudioDevice`.

**See also:** `SDL_OpenAudio`, `SDL_GetQueuedAudioSize`, `SDL_ClearQueuedAudio`, `SDL_CloseAudio`]],

  ["SDL_LoadWAV"] = [[
**`SDL_LoadWAV`** — Load a WAV file (`<SDL.h>`)

```c
SDL_AudioSpec spec;
uint8_t *buf;
uint32_t len;
SDL_LoadWAV("sound.wav", &spec, &buf, &len);
// buf has len bytes of audio data
SDL_FreeWAV(buf);

// SDL3: SDL_LoadWAV(const char *path, SDL_AudioSpec *spec, uint8_t **audio_buf, uint32_t *audio_len)
```

**See also:** `SDL_OpenAudio`, `SDL_MixAudioFormat`, `SDL_QueueAudio`]],

  -- ── RWops ──────────────────────────────────────────────────────────────────

  ["SDL_RWFromFile"] = [[
**`SDL_RWFromFile`** — Open an SDL data stream from a file (`<SDL.h>`)

```c
SDL_RWops *rw = SDL_RWFromFile("data.bin", "rb");
Sint64 size = SDL_RWsize(rw);
void *buf = SDL_LoadFile_RW(rw, NULL, 1);  // load entire file (frees rw)
// or:
char buf[256];
SDL_RWread(rw, buf, 1, sizeof(buf));
SDL_RWclose(rw);

// SDL_RWFromMem(buf, size);    // stream from memory
// SDL_RWFromConstMem(buf, sz); // from const memory (read-only)
```

**See also:** `SDL_RWFromMem`, `SDL_RWFromConstMem`, `SDL_RWclose`, `SDL_LoadFile_RW`, `SDL_ReadU32`, `SDL_WriteLE16`, `SDL_ReadBE32`]],

  ["SDL_RWclose"] = [[
**`SDL_RWclose`** — Close an SDL data stream (`<SDL.h>`)

```c
SDL_RWclose(rw);   // frees the RWops
```

**See also:** `SDL_RWFromFile`, `SDL_RWFromMem`]],

  -- ── Game Controller ────────────────────────────────────────────────────────

  ["SDL_GameControllerOpen"] = [[
**`SDL_GameControllerOpen`** — Open a game controller (`<SDL.h>`)

```c
// Discover connected controllers:
for (int i = 0; i < SDL_NumJoysticks(); i++) {
    if (SDL_IsGameController(i)) {
        SDL_GameController *ctrl = SDL_GameControllerOpen(i);
        const char *name = SDL_GameControllerName(ctrl);

        // Check axes:
        Sint16 lx = SDL_GameControllerGetAxis(ctrl, SDL_CONTROLLER_AXIS_LEFTX);

        // Check buttons:
        if (SDL_GameControllerGetButton(ctrl, SDL_CONTROLLER_BUTTON_A)) { /* A pressed */ }

        SDL_GameControllerClose(ctrl);
    }
}
```

SDL3: uses `SDL_OpenGamepad`, `SDL_GetGamepadAxis`, etc.

**See also:** `SDL_GameControllerClose`, `SDL_GameControllerGetAxis`, `SDL_GameControllerGetButton`, `SDL_GameControllerRumble`, `SDL_NumJoysticks`, `SDL_IsGameController`]],

  ["SDL_GameControllerRumble"] = [[
**`SDL_GameControllerRumble`** — Rumble feedback (`<SDL.h>`)

```c
SDL_GameControllerRumble(ctrl, 0xFFFF, 0xFFFF, 500);  // 50% left, 50% right, 500ms
```

**See also:** `SDL_GameControllerOpen`, `SDL_GameControllerClose`, `SDL_HapticOpen`, `SDL_HapticRumblePlay`]],
}
