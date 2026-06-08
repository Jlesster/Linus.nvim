-- linus/keywords/raylib.lua
-- raylib 5.x / 6.x (game-dev focused C library). Uses "raylib.h".

return {

  -- ── Window / Initialisation ─────────────────────────────────────────────────

  ["InitWindow"] = [[
**`InitWindow`** — Create a window and OpenGL context (`raylib.h`)

```c
#include "raylib.h"

int main(void) {
    InitWindow(800, 600, "Hello, raylib");
    SetTargetFPS(60);
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, World!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
```

**See also:** `CloseWindow`, `WindowShouldClose`, `SetTargetFPS`, `IsWindowReady`]],

  ["CloseWindow"] = [[
**`CloseWindow`** — Close window and unload raylib (`raylib.h`)

```c
CloseWindow();   // call at exit
```

**See also:** `InitWindow`, `WindowShouldClose`]],

  ["WindowShouldClose"] = [[
**`WindowShouldClose`** — Check if window should close (`raylib.h`)

```c
while (!WindowShouldClose()) { /* game loop */ }
```

Returns true on `KEY_ESCAPE` or window close button. Can be overridden with `SetExitKey`.

**See also:** `InitWindow`, `CloseWindow`, `SetExitKey`]],

  ["SetTargetFPS"] = [[
**`SetTargetFPS`** — Set desired frame rate (`raylib.h`)

```c
SetTargetFPS(60);   // limit to 60 FPS; 0 = unbounded
```

**See also:** `GetFPS`, `GetFrameTime`, `SetConfigFlags`]],

  ["SetConfigFlags"] = [[
**`SetConfigFlags`** — Set window config before InitWindow (`raylib.h`)

```c
SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT);
InitWindow(800, 600, "App");
```

Must be called before `InitWindow`. Common flags: `FLAG_FULLSCREEN_MODE`, `FLAG_WINDOW_UNDECORATED`, `FLAG_WINDOW_TRANSPARENT`.

**See also:** `InitWindow`, `SetTargetFPS`]],

  -- ── Drawing ─────────────────────────────────────────────────────────────────

  ["BeginDrawing"] = [[
**`BeginDrawing`** — Start frame drawing (`raylib.h`)

```c
BeginDrawing();
ClearBackground(RAYWHITE);
// ... draw calls ...
EndDrawing();
```

**See also:** `EndDrawing`, `BeginMode2D`, `BeginMode3D`, `BeginShaderMode`]],

  ["EndDrawing"] = [[
**`EndDrawing`** — End frame drawing and swap buffers (`raylib.h`)

```c
EndDrawing();   // swaps front/back buffers
```

**See also:** `BeginDrawing`, `SwapScreenBuffer`]],

  ["ClearBackground"] = [[
**`ClearBackground`** — Clear screen with a colour (`raylib.h`)

```c
ClearBackground(BLACK);      // clear to solid colour
ClearBackground((Color){ 30, 30, 30, 255 });  // custom
```

Predefined colours: `RAYWHITE`, `BLACK`, `RED`, `GREEN`, `BLUE`, `LIGHTGRAY`, `DARKGRAY`, `YELLOW`, `ORANGE`, `PURPLE`, `SKYBLUE`, `PINK`, `BEIGE`, `BROWN`, `DARKBLUE`, `DARKGREEN`, `DARKPURPLE`, `LIME`, `MAGENTA`, `VIOLET`, `GOLD`, `DARKBROWN`.

**See also:** `BeginDrawing`, `EndDrawing`, `Color`]],

  -- ── Shapes ──────────────────────────────────────────────────────────────────

  ["DrawRectangle"] = [[
**`DrawRectangle`** — Draw a filled rectangle (`raylib.h`)

```c
DrawRectangle(x, y, width, height, RED);
DrawRectangleV((Vector2){10, 10}, (Vector2){100, 50}, GREEN);            // Vector2 variant
DrawRectangleRec((Rectangle){10, 10, 100, 50}, BLUE);                    // Rectangle variant
DrawRectanglePro((Rectangle){0, 0, 100, 50}, (Vector2){50, 25}, 45.0f, PURPLE); // rotated
```

**See also:** `DrawRectangleLines`, `DrawCircle`, `DrawTriangle`, `DrawPoly`]],

  ["DrawRectangleLines"] = [[
**`DrawRectangleLines`** — Draw a rectangle outline (`raylib.h`)

```c
DrawRectangleLines(x, y, width, height, DARKGRAY);   // 1px border
DrawRectangleLinesEx((Rectangle){10, 10, 100, 50}, 3, RED); // thick border
```

**See also:** `DrawRectangle`, `DrawCircleLines`, `DrawLine`]],

  ["DrawCircle"] = [[
**`DrawCircle`** — Draw a filled circle (`raylib.h`)

```c
DrawCircle(cx, cy, radius, RED);
DrawCircleV((Vector2){cx, cy}, radius, BLUE);        // Vector2 variant
DrawCircleSector((Vector2){cx, cy}, radius, 0, 90, 36, GREEN); // arc
```

**See also:** `DrawCircleLines`, `DrawRing`, `DrawEllipse`]],

  ["DrawCircleLines"] = [[
**`DrawCircleLines`** — Draw a circle outline (`raylib.h`)

```c
DrawCircleLines(cx, cy, radius, DARKGRAY);
```

**See also:** `DrawCircle`, `DrawRing`]],

  ["DrawTriangle"] = [[
**`DrawTriangle`** — Draw a filled triangle (`raylib.h`)

```c
DrawTriangle((Vector2){10, 10}, (Vector2){50, 100}, (Vector2){100, 20}, RED);
DrawTriangleLines((Vector2){10, 10}, (Vector2){50, 100}, (Vector2){100, 20}, DARKGRAY);
```

**See also:** `DrawPoly`, `DrawCircle`]],

  ["DrawLine"] = [[
**`DrawLine`** — Draw a line segment (`raylib.h`)

```c
DrawLine(x1, y1, x2, y2, RED);
DrawLineV((Vector2){x1, y1}, (Vector2){x2, y2}, BLUE);
DrawLineEx((Vector2){10, 10}, (Vector2){100, 10}, 3, RED); // thick line
DrawLineStrip((Vector2[]){ {0,0}, {50,50}, {100,0} }, 3, GREEN); // connected
```

**See also:** `DrawCircleLines`, `DrawRectangleLines`, `DrawSplineLinear`]],

  ["DrawPoly"] = [[
**`DrawPoly`** — Draw a regular polygon (`raylib.h`)

```c
DrawPoly((Vector2){400, 300}, 6, 100, 0, BLUE);            // hexagon
DrawPolyLines((Vector2){400, 300}, 6, 100, 0, DARKBLUE);   // outline
```

**See also:** `DrawTriangle`, `DrawCircle`, `DrawRing`]],

  -- ── Text ────────────────────────────────────────────────────────────────────

  ["DrawText"] = [[
**`DrawText`** — Draw text using default font (`raylib.h`)

```c
DrawText("Hello, World!", 10, 10, 20, BLACK);   // x, y, fontSize, color
DrawTextEx(GetFontDefault(), "Hello!", (Vector2){10, 10}, 20, 2, BLACK); // with spacing
```

For custom fonts, use `DrawTextEx`, `DrawTextCodepoint`, or `DrawTextPro`.

**See also:** `MeasureText`, `GetFontDefault`, `LoadFont`, `SetTextLineSpacing`]],

  ["MeasureText"] = [[
**`MeasureText`** — Measure text width for default font (`raylib.h`)

```c
int w = MeasureText("Hello", 20);   // width in pixels
Vector2 sz = MeasureTextEx(GetFontDefault(), "Hello", 20, 2); // precise size
```

**See also:** `DrawText`, `GetFontDefault`, `LoadFont`]],

  ["LoadFont"] = [[
**`LoadFont`** — Load a font from file or memory (`raylib.h`)

```c
Font font = LoadFont("resources/arial.ttf");
// ...
UnloadFont(font);
```

**See also:** `UnloadFont`, `DrawTextEx`, `GetFontDefault`, `GenImageFontAtlas`]],

  -- ── Textures ────────────────────────────────────────────────────────────────

  ["LoadTexture"] = [[
**`LoadTexture`** — Load a texture from file (`raylib.h`)

```c
Texture2D tex = LoadTexture("resources/player.png");
// ...
UnloadTexture(tex);
```

Supported formats: PNG, BMP, TGA, JPG, GIF, QOI, DDS, HDR, ASTC, KTX, PVR.

**See also:** `UnloadTexture`, `LoadTextureFromImage`, `LoadRenderTexture`, `DrawTexture`]],

  ["UnloadTexture"] = [[
**`UnloadTexture`** — Unload texture from GPU memory (`raylib.h`)

```c
UnloadTexture(tex);
```

**See also:** `LoadTexture`, `LoadRenderTexture`]],

  ["DrawTexture"] = [[
**`DrawTexture`** — Draw a texture (`raylib.h`)

```c
DrawTexture(tex, x, y, WHITE);                         // solid
DrawTextureV(tex, (Vector2){x, y}, WHITE);              // Vector2 position
DrawTextureEx(tex, (Vector2){x, y}, 0.0f, 1.0f, WHITE); // rotation + scale
DrawTexturePro(tex, srcRect, destRect, origin, rot, WHITE); // source/dest rects
DrawTextureRec(tex, (Rectangle){0, 0, 32, 32}, (Vector2){x, y}, WHITE); // spritesheet
```

**See also:** `LoadTexture`, `GenTextureMipmaps`, `SetTextureFilter`]],

  ["LoadRenderTexture"] = [[
**`LoadRenderTexture`** — Create a render texture (FBO) (`raylib.h`)

```c
RenderTexture2D rt = LoadRenderTexture(width, height);
// ...
BeginTextureMode(rt);
DrawText("rendered", 10, 10, 20, RED);
EndTextureMode();
// Draw rt.texture as a regular texture:
DrawTextureRec(rt.texture, (Rectangle){0, 0, width, -height}, (Vector2){0,0}, WHITE);
// ...
UnloadRenderTexture(rt);
```

**See also:** `UnloadRenderTexture`, `BeginTextureMode`, `EndTextureMode`]],

  ["GenImageColor"] = [[
**`GenImageColor`** — Generate a solid-colour image (`raylib.h`)

```c
Image img = GenImageColor(width, height, RED);
Texture2D tex = LoadTextureFromImage(img);
UnloadImage(img);
```

Other generators: `GenImageGradientV`, `GenImageGradientH`, `GenImageGradientRadial`, `GenImageChecked`, `GenImageCellular`.

**See also:** `LoadTextureFromImage`, `UnloadImage`, `Image`]],

  -- ── Input ───────────────────────────────────────────────────────────────────

  ["IsKeyDown"] = [[
**`IsKeyDown`** — Check if a key is held down (`raylib.h`)

```c
if (IsKeyDown(KEY_RIGHT)) x += 5;
if (IsKeyPressed(KEY_SPACE)) jump();    // single press
if (IsKeyReleased(KEY_F)) fire();       // on release
if (IsKeyReleased(KEY_UP)) y -= 5;
```

**See also:** `IsKeyPressed`, `IsKeyReleased`, `IsKeyUp`, `GetKeyPressed`, `KEY_*`]],

  ["IsKeyPressed"] = [[
**`IsKeyPressed`** — Check if a key was just pressed (`raylib.h`)

```c
if (IsKeyPressed(KEY_ENTER)) confirm();
if (IsKeyPressed(KEY_F11)) toggleFullscreen();
```

True only once per press — no repeat. For repeat, use `IsKeyDown`.

**See also:** `IsKeyDown`, `IsKeyReleased`, `GetKeyPressed`, `SetExitKey`]],

  ["GetMousePosition"] = [[
**`GetMousePosition`** — Get current mouse position (`raylib.h`)

```c
Vector2 mp = GetMousePosition();
if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) { /* drag */ }
if (GetMouseWheelMove() != 0) zoom(GetMouseWheelMove());
```

**See also:** `IsMouseButtonDown`, `IsMouseButtonPressed`, `GetMouseDelta`, `GetMouseWheelMove`]],

  ["IsMouseButtonDown"] = [[
**`IsMouseButtonDown`** — Check if mouse button is held (`raylib.h`)

```c
if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) { }
```

**See also:** `IsMouseButtonPressed`, `IsMouseButtonReleased`, `GetMousePosition`, `SetMouseCursor`]],

  -- ── Audio ───────────────────────────────────────────────────────────────────

  ["InitAudioDevice"] = [[
**`InitAudioDevice`** — Initialise audio subsystem (`raylib.h`)

```c
InitAudioDevice();
Music music = LoadMusicStream("resources/track.ogg");
PlayMusicStream(music);
// ...
StopMusicStream(music);
UnloadMusicStream(music);
CloseAudioDevice();
```

**See also:** `CloseAudioDevice`, `LoadSound`, `LoadMusicStream`, `PlaySound`, `SetMasterVolume`]],

  ["LoadSound"] = [[
**`LoadSound`** — Load a sound effect (`raylib.h`)

```c
Sound sfx = LoadSound("resources/click.wav");
PlaySound(sfx);
// ...
UnloadSound(sfx);
```

**See also:** `UnloadSound`, `PlaySound`, `StopSound`, `SetSoundVolume`]],

  ["PlaySound"] = [[
**`PlaySound`** — Play a sound effect (`raylib.h`)

```c
PlaySound(sfx);
PlaySoundMulti(sfx);  // overlapping instances
```

**See also:** `StopSound`, `SetSoundVolume`, `LoadSound`, `LoadMusicStream`]],

  ["LoadMusicStream"] = [[
**`LoadMusicStream`** — Load a music file (streamed) (`raylib.h`)

```c
Music music = LoadMusicStream("resources/ambient.ogg");
PlayMusicStream(music);
// In game loop:
UpdateMusicStream(music);   // refill buffers
// ...
UnloadMusicStream(music);
```

**See also:** `PlayMusicStream`, `UpdateMusicStream`, `StopMusicStream`, `SeekMusicStream`]],

  ["PlayMusicStream"] = [[
**`PlayMusicStream`** — Start streaming music (`raylib.h`)

```c
PlayMusicStream(music);
UpdateMusicStream(music);   // call every frame
```

**See also:** `StopMusicStream`, `UpdateMusicStream`, `LoadMusicStream`]],

  -- ── Camera / 3D ─────────────────────────────────────────────────────────────

  ["BeginMode3D"] = [[
**`BeginMode3D`** — Start 3D drawing mode (`raylib.h`)

```c
Camera3D cam = { 0 };
cam.position = (Vector3){ 10, 10, 10 };
cam.target   = (Vector3){ 0, 0, 0 };
cam.up       = (Vector3){ 0, 1, 0 };
cam.fovy     = 45.0f;
cam.projection = CAMERA_PERSPECTIVE;

BeginMode3D(cam);
DrawCube((Vector3){0, 0, 0}, 2, 2, 2, RED);
DrawGrid(10, 1);
EndMode3D();
```

**See also:** `EndMode3D`, `Camera3D`, `SetCameraMode`, `DrawCube`, `DrawModel`]],

  ["EndMode3D"] = [[
**`EndMode3D`** — End 3D drawing mode (`raylib.h`)

```c
EndMode3D();
```

**See also:** `BeginMode3D`]],

  ["DrawCube"] = [[
**`DrawCube`** — Draw a 3D cube (`raylib.h`)

```c
DrawCube((Vector3){0, 0, 0}, 2, 2, 2, RED);
DrawCubeV((Vector3){0,0,0}, (Vector3){2,2,2}, BLUE);  // Vector3 size
DrawCubeWires((Vector3){0, 0, 0}, 2, 2, 2, DARKGRAY);  // wireframe
DrawCubeTexture(tex, (Vector3){0, 0, 0}, 2, 2, 2, WHITE); // textured
```

**See also:** `DrawSphere`, `DrawPlane`, `DrawModel`, `BeginMode3D`]],

  ["DrawModel"] = [[
**`DrawModel`** — Draw a 3D model (`raylib.h`)

```c
Model model = LoadModel("resources/truck.glb");
DrawModel(model, (Vector3){0, 0, 0}, 1.0f, WHITE);   // position, scale, tint
DrawModelEx(model, (Vector3){0,0,0}, (Vector3){0,1,0}, 45, (Vector3){1,1,1}, WHITE); // rotate
// ...
UnloadModel(model);
```

**See also:** `LoadModel`, `UnloadModel`, `DrawMesh`, `DrawCube`]],

  ["LoadModel"] = [[
**`LoadModel`** — Load a 3D model from file (`raylib.h`)

```c
Model model = LoadModel("resources/truck.glb");
// Access materials/meshes: model.materialCount, model.materials[0]
// ...
UnloadModel(model);
```

Supported formats: GLTF/GLB, OBJ, IQM, VOX, M3D.

**See also:** `UnloadModel`, `DrawModel`, `LoadMaterials`, `LoadModelFromMesh`]],

  -- ── Colour / Math / Misc ────────────────────────────────────────────────────

  ["ColorAlpha"] = [[
**`ColorAlpha`** — Get colour with modified alpha (`raylib.h`)

```c
Color faded = ColorAlpha(RED, 0.5f);   // half-opaque red
Color blended = ColorAlphaBlend(WHITE, BLACK, (Color){0,0,0,128}); // manual blend
```

**See also:** `ColorFromHSV`, `ColorFromNormalized`, `Fade`, `Color`]],

  ["Vector2"] = [[
**`Vector2`** — 2D vector struct (`raylib.h`)

```c
typedef struct Vector2 { float x, y; } Vector2;
Vector2 v = { 10.0f, 20.0f };
Vector2 sum = Vector2Add(v, (Vector2){1, 1});
Vector2 scaled = Vector2Scale(v, 2.0f);
float len = Vector2Length(v);
float dot = Vector2DotProduct(v, (Vector2){1, 0});
Vector2 norm = Vector2Normalize(v);
```

**See also:** `Vector3`, `Vector2Add`, `Vector2Subtract`, `Vector2Scale`, `Vector2Length`]],

  ["Vector3"] = [[
**`Vector3`** — 3D vector struct (`raylib.h`)

```c
typedef struct Vector3 { float x, y, z; } Vector3;
Vector3 v = { 1, 2, 3 };
Vector3 sum  = Vector3Add(v, (Vector3){1, 0, 0});
Vector3 cross = Vector3CrossProduct(v, (Vector3){0, 1, 0});
float dot   = Vector3DotProduct(v, (Vector3){0, 0, 1});
```

**See also:** `Vector2`, `Vector3Add`, `Vector3Scale`, `Vector3CrossProduct`, `Vector3Normalize`]],

  ["Rectangle"] = [[
**`Rectangle`** — 2D rectangle struct (`raylib.h`)

```c
typedef struct Rectangle { float x, y, width, height; } Rectangle;
Rectangle r = { 10, 10, 100, 50 };
bool inside = CheckCollisionPointRec((Vector2){20, 20}, r);
Rectangle clipped = GetCollisionRec(r, other);
```

**See also:** `Vector2`, `CheckCollisionPointRec`, `CheckCollisionRecs`, `GetCollisionRec`]],

  ["Color"] = [[
**`Color`** — RGBA colour struct (`raylib.h`)

```c
typedef struct Color { unsigned char r, g, b, a; } Color;
Color c = { 255, 0, 0, 255 };   // solid red
Color hsv = ColorFromHSV(120, 1, 1);   // green via HSV
Color norm = ColorFromNormalized((Vector4){1,0,0,1}); // normalized float
```

Predefined colours: `RAYWHITE`, `BLACK`, `RED`, `GREEN`, `BLUE`, `LIGHTGRAY`, `YELLOW`, `ORANGE`, `PURPLE`, `SKYBLUE`, `PINK`, `BEIGE`, `BROWN`, `DARKGRAY`, `DARKBLUE`, `DARKGREEN`, `DARKPURPLE`, `LIME`, `MAGENTA`, `GOLD`, `VIOLET`, `MAROON`, `DARKBROWN`.

**See also:** `ColorAlpha`, `ColorFromHSV`, `Fade`, `ColorToInt`]],

  ["GetFrameTime"] = [[
**`GetFrameTime`** — Get time since last frame (`raylib.h`)

```c
float dt = GetFrameTime();    // seconds (e.g. 0.016 for 60 FPS)
player.pos.x += player.speed * dt;   // frame-independent movement
```

**See also:** `GetTime`, `SetTargetFPS`, `GetFPS`]],

  ["GetRandomValue"] = [[
**`GetRandomValue`** — Get random integer in range (`raylib.h`)

```c
int r = GetRandomValue(1, 6);     // dice roll 1-6
float rf = (float)GetRandomValue(0, 100) / 100.0f; // float [0, 1]
```

**See also:** `SetRandomSeed`, `GetTime`]],

  ["TraceLog"] = [[
**`TraceLog`** — Log a message with level (`raylib.h`)

```c
TraceLog(LOG_INFO,   "Game loaded %d assets", count);
TraceLog(LOG_WARNING, "Low memory");
TraceLog(LOG_ERROR,   "Failed to load file: %s", filename);
TraceLog(LOG_DEBUG,   "x=%f, y=%f", x, y);
```

Levels: `LOG_ALL`, `LOG_TRACE`, `LOG_DEBUG`, `LOG_INFO`, `LOG_WARNING`, `LOG_ERROR`, `LOG_FATAL`, `LOG_NONE`.

**See also:** `SetTraceLogLevel`, `SetTraceLogCallback`]],

  ["LoadFileData"] = [[
**`LoadFileData`** — Load file into memory (`raylib.h`)

```c
int dataSize;
unsigned char *data = LoadFileData("resources/data.bin", &dataSize);
// ... use data ...
UnloadFileData(data);
```

**See also:** `SaveFileData`, `LoadFileText`, `SaveFileText`, `FileExists`]],
}
