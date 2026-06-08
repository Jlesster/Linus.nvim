-- linus/keywords/wayland.lua
-- Wayland protocol client libraries (wayland-client, xdg-shell, wlroots).

return {

  -- ── Display / Registry ──────────────────────────────────────────────────────

  ["wl_display_connect"] = [[
**`wl_display_connect`** — Connect to a Wayland display (`<wayland-client.h>`)

```c
struct wl_display *display = wl_display_connect(NULL);  // $WAYLAND_DISPLAY or "wayland-0"
if (!display) { /* cannot connect */ }

struct wl_registry *registry = wl_display_get_registry(display);
wl_registry_add_listener(registry, &registry_listener, NULL);

wl_display_roundtrip(display);   // receive initial globals
// ...
wl_display_disconnect(display);
```

**See also:** `wl_display_disconnect`, `wl_display_get_registry`, `wl_display_roundtrip`, `wl_display_dispatch`]],

  ["wl_display_disconnect"] = [[
**`wl_display_disconnect`** — Disconnect from Wayland display (`<wayland-client.h>`)

```c
wl_display_disconnect(display);
```

Frees all proxy objects associated with this display.

**See also:** `wl_display_connect`]],

  ["wl_display_get_registry"] = [[
**`wl_display_get_registry`** — Get the global registry object (`<wayland-client.h>`)

```c
struct wl_registry *registry = wl_display_get_registry(display);
```

**See also:** `wl_registry_add_listener`, `wl_registry_bind`, `wl_display_roundtrip`]],

  ["wl_display_roundtrip"] = [[
**`wl_display_roundtrip`** — Block until all pending requests processed (`<wayland-client.h>`)

```c
wl_display_roundtrip(display);
```

Used after registry listener setup to ensure all globals are received before proceeding.

**See also:** `wl_display_dispatch`, `wl_display_flush`, `wl_display_connect`]],

  ["wl_display_dispatch"] = [[
**`wl_display_dispatch`** — Read and dispatch incoming events (`<wayland-client.h>`)

```c
wl_display_dispatch(display);          // blocks until events arrive
while (wl_display_dispatch(display) != -1) { /* event loop */ }
```

For non-blocking dispatch, use `wl_display_prepare_read` / `wl_display_read_events` with `poll()`.

**See also:** `wl_display_roundtrip`, `wl_display_flush`, `wl_display_prepare_read`]],

  ["wl_display_flush"] = [[
**`wl_display_flush`** — Flush pending requests to the server (`<wayland-client.h>`)

```c
wl_display_flush(display);   // non-blocking; returns -1 on EAGAIN
```

Use with `poll()` on `wl_display_get_fd()` for writeable events.

**See also:** `wl_display_get_fd`, `wl_display_dispatch`, `wl_display_connect`]],

  ["wl_display_get_fd"] = [[
**`wl_display_get_fd`** — Get the display socket fd (`<wayland-client.h>`)

```c
int fd = wl_display_get_fd(display);
struct pollfd pfd = { .fd = fd, .events = POLLIN };
poll(&pfd, 1, -1);   // wait for events
```

**See also:** `wl_display_dispatch`, `wl_display_flush`, `wl_display_prepare_read`]],

  -- ── Registry ────────────────────────────────────────────────────────────────

  ["wl_registry_add_listener"] = [[
**`wl_registry_add_listener`** — Listen for global add/remove events (`<wayland-client.h>`)

```c
static const struct wl_registry_listener registry_listener = {
    .global        = registry_global,
    .global_remove = registry_global_remove,
};

static void registry_global(void *data, struct wl_registry *registry,
                            uint32_t name, const char *interface, uint32_t version) {
    if (strcmp(interface, wl_compositor_interface.name) == 0)
        compositor = wl_registry_bind(registry, name, &wl_compositor_interface, 4);
    else if (strcmp(interface, xdg_wm_base_interface.name) == 0)
        xdg_wm_base = wl_registry_bind(registry, name, &xdg_wm_base_interface, 5);
}

wl_registry_add_listener(registry, &registry_listener, NULL);
```

**See also:** `wl_registry_bind`, `wl_display_get_registry`, `wl_display_roundtrip`]],

  ["wl_registry_bind"] = [[
**`wl_registry_bind`** — Bind to a global interface (`<wayland-client.h>`)

```c
struct wl_compositor *comp = wl_registry_bind(registry, name,
                                               &wl_compositor_interface, 4);
// version: requested interface version (<= advertised version)
```

**See also:** `wl_registry_add_listener`, `wl_display_get_registry`]],

  -- ── Surface / Shell ─────────────────────────────────────────────────────────

  ["wl_compositor_create_surface"] = [[
**`wl_compositor_create_surface`** — Create a wl_surface (`<wayland-client.h>`)

```c
struct wl_surface *surface = wl_compositor_create_surface(compositor);
// ... attach buffer, damage, commit ...
wl_surface_destroy(surface);
```

**See also:** `wl_surface_attach`, `wl_surface_damage`, `wl_surface_commit`, `wl_surface_destroy`]],

  ["wl_surface_attach"] = [[
**`wl_surface_attach`** — Attach a buffer to a surface (`<wayland-client.h>`)

```c
wl_surface_attach(surface, buffer, 0, 0);
wl_surface_damage(surface, 0, 0, width, height);
wl_surface_commit(surface);
```

**See also:** `wl_surface_commit`, `wl_surface_damage`, `wl_surface_frame`, `wl_buffer`]],

  ["wl_surface_commit"] = [[
**`wl_surface_commit`** — Submit pending surface state (`<wayland-client.h>`)

```c
wl_surface_commit(surface);   // apply pending attach/damage/input/opaque
```

**See also:** `wl_surface_attach`, `wl_surface_damage`, `wl_surface_frame`]],

  ["wl_surface_damage"] = [[
**`wl_surface_damage`** — Mark a region as damaged (`<wayland-client.h>`)

```c
wl_surface_damage(surface, x, y, width, height);
```

**See also:** `wl_surface_attach`, `wl_surface_commit`, `wl_surface_damage_buffer`]],

  ["wl_surface_frame"] = [[
**`wl_surface_frame`** — Request a frame callback (`<wayland-client.h>`)

```c
struct wl_callback *cb = wl_surface_frame(surface);
wl_callback_add_listener(cb, &frame_listener, NULL);

static void frame_done(void *data, struct wl_callback *cb, uint32_t time) {
    wl_callback_destroy(cb);
    struct wl_callback *next = wl_surface_frame(surface);   // request next
}
```

**See also:** `wl_callback_add_listener`, `wl_surface_commit`, `wl_callback_destroy`]],

  ["xdg_wm_base_get_xdg_surface"] = [[
**`xdg_wm_base_get_xdg_surface`** — Create an xdg surface (`<xdg-shell.h>`)

```c
struct xdg_surface *xdg_surf = xdg_wm_base_get_xdg_surface(xdg_wm_base, surface);
xdg_surface_add_listener(xdg_surf, &xdg_surface_listener, NULL);
```

**See also:** `xdg_surface_get_toplevel`, `xdg_surface_get_popup`, `xdg_surface_ack_configure`]],

  ["xdg_surface_get_toplevel"] = [[
**`xdg_surface_get_toplevel`** — Get the toplevel surface role (`<xdg-shell.h>`)

```c
struct xdg_toplevel *toplevel = xdg_surface_get_toplevel(xdg_surf);
xdg_toplevel_add_listener(toplevel, &toplevel_listener, NULL);
xdg_toplevel_set_title(toplevel, "My App");
xdg_toplevel_set_app_id(toplevel, "com.example.app");
wl_surface_commit(surface);
```

**See also:** `xdg_toplevel_set_title`, `xdg_surface_ack_configure`, `xdg_toplevel_add_listener`]],

  ["xdg_surface_ack_configure"] = [[
**`xdg_surface_ack_configure`** — Acknowledge a configure event (`<xdg-shell.h>`)

```c
static void xdg_surface_configure(void *data, struct xdg_surface *xdg_surf,
                                   uint32_t serial) {
    xdg_surface_ack_configure(xdg_surf, serial);
}

xdg_surface_add_listener(xdg_surf, &listener, NULL);
```

**See also:** `xdg_surface_get_toplevel`, `xdg_toplevel_add_listener`]],

  ["xdg_toplevel_set_title"] = [[
**`xdg_toplevel_set_title`** — Set the window title (`<xdg-shell.h>`)

```c
xdg_toplevel_set_title(toplevel, "My App");
```

**See also:** `xdg_toplevel_set_app_id`, `xdg_toplevel_set_min_size`, `xdg_toplevel_set_maximized`]],

  ["xdg_toplevel_set_app_id"] = [[
**`xdg_toplevel_set_app_id`** — Set the app ID (`<xdg-shell.h>`)

```c
xdg_toplevel_set_app_id(toplevel, "com.example.app");
```

**See also:** `xdg_toplevel_set_title`, `xdg_toplevel_add_listener`]],

  ["xdg_toplevel_add_listener"] = [[
**`xdg_toplevel_add_listener`** — Listen for toplevel state changes (`<xdg-shell.h>`)

```c
static void toplevel_configure(void *data, struct xdg_toplevel *toplevel,
                                int32_t width, int32_t height,
                                struct wl_array *states) { }
static void toplevel_close(void *data, struct xdg_toplevel *toplevel) { }

static const struct xdg_toplevel_listener listener = {
    .configure = toplevel_configure, .close = toplevel_close,
};
xdg_toplevel_add_listener(toplevel, &listener, NULL);
```

**See also:** `xdg_surface_get_toplevel`, `xdg_toplevel_set_title`]],

  -- ── SHM / Buffer ────────────────────────────────────────────────────────────

  ["wl_shm_create_pool"] = [[
**`wl_shm_create_pool`** — Create an SHM pool (`<wayland-client.h>`)

```c
int fd = memfd_create("wayland-shm", MFD_CLOEXEC);
ftruncate(fd, size);
struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, size);
struct wl_buffer *buffer = wl_shm_pool_create_buffer(pool, 0, width, height,
                                                      stride, WL_SHM_FORMAT_XRGB8888);
close(fd);

void *pixels = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
// ... draw ...
munmap(pixels, size);
wl_buffer_destroy(buffer);
wl_shm_pool_destroy(pool);
```

**See also:** `wl_shm_pool_create_buffer`, `wl_shm_pool_destroy`, `wl_buffer_destroy`, `WL_SHM_FORMAT_*`]],

  ["wl_shm_pool_create_buffer"] = [[
**`wl_shm_pool_create_buffer`** — Create a wl_buffer from an SHM pool (`<wayland-client.h>`)

```c
struct wl_buffer *buf = wl_shm_pool_create_buffer(pool, offset,
                                                    width, height, stride, format);
```

Formats: `WL_SHM_FORMAT_XRGB8888`, `WL_SHM_FORMAT_ARGB8888`, `WL_SHM_FORMAT_RGB565`.

**See also:** `wl_shm_create_pool`, `wl_shm_pool_destroy`, `wl_buffer_destroy`]],

  -- ── wlroots helpers ─────────────────────────────────────────────────────────

  ["wlr_backend_autocreate"] = [[
**`wlr_backend_autocreate`** — Auto-create wlroots backend (`<wlr/backend.h>`)

```c
struct wlr_backend *backend = wlr_backend_autocreate(wl_display_get_event_loop(display), NULL);
if (!backend) { /* error */ }
wlr_backend_start(backend);
```

Creates the appropriate backend (DRM, Wayland, X11) based on the environment.

**See also:** `wlr_backend_start`, `wlr_backend_destroy`, `wlr_output`]],

  ["wlr_renderer_autocreate"] = [[
**`wlr_renderer_autocreate`** — Auto-create a wlroots renderer (`<wlr/render/wlr_renderer.h>`)

```c
struct wlr_renderer *renderer = wlr_renderer_autocreate(backend);
wlr_renderer_init_wl_display(renderer, display);
```

**See also:** `wlr_texture`, `wlr_render_rect`, `wlr_backend_autocreate`]],

  ["wlr_output_create_global"] = [[
**`wlr_output_create_global`** — Advertise a wlroots output (`<wlr/types/wlr_output.h>`)

```c
struct wlr_output *output = wlr_output_create_global(display);
wlr_output_set_name(output, "my-output");
```

**See also:** `wlr_output_set_mode`, `wlr_output_commit`, `wlr_backend_autocreate`]],

  ["wlr_output_set_mode"] = [[
**`wlr_output_set_mode`** — Set output mode (`<wlr/types/wlr_output.h>`)

```c
struct wlr_output_mode *mode = wlr_output_preferred_mode(output);
wlr_output_set_mode(output, mode);
wlr_output_commit(output);
```

**See also:** `wlr_output_create_global`, `wlr_output_commit`, `wlr_output_preferred_mode`]],

  ["wlr_cursor_create"] = [[
**`wlr_cursor_create`** — Create a wlroots cursor (`<wlr/types/wlr_cursor.h>`)

```c
struct wlr_cursor *cursor = wlr_cursor_create();
wlr_cursor_attach_output_layout(cursor, output_layout);
wlr_cursor_set_xcursor(cursor, xcursor_mgr, "default");
```

**See also:** `wlr_cursor_destroy`, `wlr_cursor_warp`, `wlr_xcursor_manager_create`]],

  ["wlr_seat_create"] = [[
**`wlr_seat_create`** — Create a seat (`<wlr/types/wlr_seat.h>`)

```c
struct wlr_seat *seat = wlr_seat_create(display, "seat0");
wlr_seat_set_capabilities(seat, WL_SEAT_CAPABILITY_POINTER | WL_SEAT_CAPABILITY_KEYBOARD);
```

**See also:** `wlr_seat_set_capabilities`, `wlr_seat_keyboard_notify_enter`, `wlr_seat_pointer_notify_enter`]],

  ["wlr_xdg_surface_create"] = [[
**`wlr_xdg_surface_create`** — Create an xdg surface from a wlr_surface (`<wlr/types/wlr_xdg_shell.h>`)

```c
struct wlr_xdg_surface *xdg_surface;
xdg_surface_create_client.notify = handle_xdg_surface;
wl_signal_add(&xdg_shell->surface_create, &xdg_surface_create_client);
```

**See also:** `wlr_xdg_surface`, `wlr_xdg_toplevel`, `wlr_xdg_surface_from_resource`]],

  ["wlr_input_device"] = [[
**`wlr_input_device`** — wlroots input device base struct (`<wlr/types/wlr_input_device.h>`)

```c
struct wlr_input_device *dev;
struct wlr_keyboard *kb = wlr_keyboard_from_input_device(dev);
struct wlr_pointer *ptr = wlr_pointer_from_input_device(dev);
```

Types: `WLR_INPUT_DEVICE_KEYBOARD`, `WLR_INPUT_DEVICE_POINTER`, `WLR_INPUT_DEVICE_TOUCH`, `WLR_INPUT_DEVICE_TABLET_TOOL`.

**See also:** `wlr_keyboard`, `wlr_pointer`, `wlr_seat_create`]],
}
