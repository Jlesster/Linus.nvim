-- linus/keywords/cpp/ftxui.lua
-- FTXUI — C++ terminal UI library (<ftxui/dom.hpp>, <ftxui/screen.hpp>, <ftxui/component.hpp>).

return {

  -- ── Screen ──────────────────────────────────────────────────────────────────

  ["Screen"] = [[
**`ScreenInteractive`** — Main terminal screen (`<ftxui/screen/screen_interactive.hpp>`)

```cpp
#include <ftxui/screen/screen_interactive.hpp>
#include <ftxui/component/component.hpp>
#include <ftxui/component/event.hpp>

using namespace ftxui;

int main() {
    auto screen = ScreenInteractive::Fullscreen();

    auto renderer = Renderer([] {
        return text("Hello, FTXUI!") | bold | color(Color::Cyan);
    });

    screen.Loop(renderer);
    return 0;
}
```

Modes: `Fullscreen()`, `TerminalOutput()`, `FixedSize(w, h)`, `FitComponent()`.

**See also:** `Renderer`, `Loop`, `Component`, `ScreenInteractive::Exit`]],

  -- ── Elements ────────────────────────────────────────────────────────────────

  ["text"] = [[
**`text`** — Create a text element (`<ftxui/dom/elements.hpp>`)

```cpp
Element e = text("Hello, World!");
Element numbered = text(L"Wide text");   // wstring overload
```

**See also:** `hbox`, `vbox`, `separator`, `gauge`, `paragraph`]],

  ["hbox"] = [[
**`hbox`** — Arrange elements horizontally (`<ftxui/dom/elements.hpp>`)

```cpp
Element row = hbox({
    text("Left"),
    separator(),
    text("Right"),
});
```

**See also:** `vbox`, `hflow`, `separator`]],

  ["vbox"] = [[
**`vbox`** — Arrange elements vertically (`<ftxui/dom/elements.hpp>`)

```cpp
Element col = vbox({
    text("Line 1"),
    text("Line 2"),
    separator(),
    text("After separator"),
});
```

**See also:** `hbox`, `hflow`, `separator`, `flex`]],

  ["separator"] = [[
**`separator`** — Draw a line separator (`<ftxui/dom/elements.hpp>`)

```cpp
Element sep = separator();               // thin line
Element dbl = separatorDouble();         // double line
Element hvy = separatorHeavy();          // heavy line
Element chs = separatorCharacter('.');   // custom character
```

**See also:** `hbox`, `vbox`, `border`]],

  ["border"] = [[
**`border`** — Draw a border around an element (`<ftxui/dom/elements.hpp>`)

```cpp
Element framed = border(text("Inside"));
Element heavy  = borderHeavy(text("Heavy border"));
Element rounded = borderRounded(text("Rounded corners"));
Element empty  = borderEmpty(text("Invisible border (padding)"));
```

**See also:** `hbox`, `vbox`, `separator`, `clear_under`]],

  ["gauge"] = [[
**`gauge`** — Draw a progress bar (`<ftxui/dom/elements.hpp>`)

```cpp
float progress = 0.5f;
Element bar = gauge(progress);          // default width
Element wbar = gauge(progress) | flex;  // expand to available width
Element dbar = gaugeDirection(progress, Direction::Right); // left-to-right
```

`progress` is in [0.0, 1.0]. Use `gaugeDirection` to set fill direction.

**See also:** `text`, `hbox`, `vbox`, `flex`]],

  ["paragraph"] = [[
**`paragraph`** — Word-wrapped text element (`<ftxui/dom/elements.hpp>`)

```cpp
Element p = paragraph("Long text that will be automatically wrapped to fit the available width.");
```

**See also:** `text`, `hbox`, `vbox`, `separator`]],

  ["flex"] = [[
**`flex`** — Make an element expand to fill available space (`<ftxui/dom/elements.hpp>`)

```cpp
Element e = text("Stretch me") | flex;
Element centered = text("Centered") | center;
Element right_aligned = text("Right") | alignRight;
```

Other decorators: `center`, `alignLeft`, `alignRight`, `focus`, `notfocus`, `clear_under`, `size(WIDTH, EQUAL, 20)`.

**See also:** `size`, `center`, `alignRight`, `hbox`, `vbox`, `border`]],

  ["size"] = [[
**`size`** — Constrain element dimensions (`<ftxui/dom/elements.hpp>`)

```cpp
Element fixed = text("Box") | size(WIDTH, EQUAL, 20) | size(HEIGHT, EQUAL, 5);
Element minw  = text("Min") | size(WIDTH, GREATER_THAN, 20);
Element maxh  = text("Max") | size(HEIGHT, LESS_THAN, 10);
```

Direction: `WIDTH`, `HEIGHT`. Constraint: `EQUAL`, `GREATER_THAN`, `LESS_THAN`.

**See also:** `flex`, `center`, `hbox`, `vbox`]],

  -- ── Components ──────────────────────────────────────────────────────────────

  ["Renderer"] = [[
**`Renderer`** — Create a render-only component (`<ftxui/component/component.hpp>`)

```cpp
auto renderer = Renderer([] {
    return text("Hello!") | bold;
});

// With state:
int count = 0;
auto counter = Renderer([&] {
    return text(std::to_string(count)) | center;
});
```

**See also:** `Component`, `Container`, `Menu`, `Checkbox`, `Input`, `Loop`]],

  ["Container"] = [[
**`Container`** — Group components for navigation (`<ftxui/component/component.hpp>`)

```cpp
auto container = Container::Horizontal({
    left_panel,
    right_panel,
});

auto tabs = Container::Tab({page1, page2, page3}, &selected_tab);
```

Types: `Horizontal`, `Vertical`, `Tab`.

**See also:** `Renderer`, `Menu`, `Tab`, `Component`]],

  ["Menu"] = [[
**`Menu`** — Selectable menu list (`<ftxui/component/component.hpp>`)

```cpp
std::vector<std::string> items = {"File", "Edit", "View", "Help"};
int selected = 0;

auto menu = Menu(&items, &selected);
// selected changes as user navigates with arrow keys
```

**See also:** `Container`, `Checkbox`, `Button`, `Dropdown`, `Input`]],

  ["Checkbox"] = [[
**`Checkbox`** — Toggleable checkbox (`<ftxui/component/component.hpp>`)

```cpp
bool checked = false;
auto cb = Checkbox("Enable feature", &checked);
```

**See also:** `Menu`, `Renderer`, `Button`, `Input`]],

  ["Input"] = [[
**`Input`** — Text input field (`<ftxui/component/component.hpp>`)

```cpp
std::string content;
auto input = Input(&content, "placeholder text...");

// Password mode:
auto pw = Input(&content, "Password", InputOption::Password);
```

**See also:** `Checkbox`, `Menu`, `Button`, `Renderer`]],

  ["Button"] = [[
**`Button`** — Clickable button (`<ftxui/component/component.hpp>`)

```cpp
std::string label = "Click me";
auto btn = Button(&label, [&] {
    // clicked callback
});
```

**See also:** `Checkbox`, `Input`, `Menu`, `Container`]],

  ["Dropdown"] = [[
**`Dropdown`** — Dropdown menu selector (`<ftxui/component/component.hpp>`)

```cpp
std::vector<std::string> options = {"Option A", "Option B", "Option C"};
int selected = 0;
auto dropdown = Dropdown(&options, &selected);
```

**See also:** `Menu`, `Container`, `Checkbox`, `Input`]],

  ["CatchEvent"] = [[
**`CatchEvent`** — Handle custom keyboard events (`<ftxui/component/component.hpp>`)

```cpp
auto comp = Renderer([] { return text("Press q to quit"); }) | CatchEvent([&](Event e) {
    if (e == Event::Character('q')) {
        screen.Exit();
        return true;   // event handled
    }
    return false;      // pass through
});
```

**See also:** `Event`, `Renderer`, `Component`, `ScreenInteractive::Exit`]],

  -- ── Colour / Style ──────────────────────────────────────────────────────────

  ["color"] = [[
**`color`** / **`bgcolor`** — Set text/background colour (`<ftxui/dom/elements.hpp>`)

```cpp
Element styled = text("Red text") | color(Color::Red);
Element bg     = text("Yellow bg") | bgcolor(Color::Yellow);
Element both   = text("White on blue") | color(Color::White) | bgcolor(Color::Blue);

// True color (24-bit):
Element tc = text("Custom") | color(Color::RGB(0x12, 0x34, 0x56));
```

**See also:** `bold`, `dim`, `inverted`, `blink`, `underlined`]],

  ["bold"] = [[
**`bold`** — Bold text decorator (`<ftxui/dom/elements.hpp>`)

```cpp
Element b = text("Bold") | bold;
```

**See also:** `color`, `dim`, `inverted`, `underlined`, `blink`]],

  ["dim"] = [[
**`dim`** — Dim/half-bright text (`<ftxui/dom/elements.hpp>`)

```cpp
Element d = text("Dim") | dim;
```

**See also:** `bold`, `color`, `inverted`, `underlined`]],

  ["inverted"] = [[
**`inverted`** — Swap foreground and background colours (`<ftxui/dom/elements.hpp>`)

```cpp
Element inv = text("Inverted") | inverted;
```

**See also:** `bold`, `dim`, `color`, `bgcolor`]],
}
