-- linus/keywords/ncurses.lua
-- ncurses and notcurses terminal UI library.

return {

  -- ── Initialisation ─────────────────────────────────────────────────────────

  ["initscr"] = [[
**`initscr`** — Initialise curses terminal (`<curses.h>`)

```c
#include <curses.h>

int main() {
    initscr();              // allocate WINDOW, set terminal to curses mode
    raw();                  // disable line buffering
    keypad(stdscr, TRUE);   // enable function/arrow keys
    noecho();               // don't echo typed characters
    // ... use curses ...
    endwin();               // restore terminal
    return 0;
}
```

Returns `stdscr` (global `WINDOW*`). Allocates memory — must pair with `endwin()`. On failure, prints error and exits.

**See also:** `endwin`, `newterm`, `delscreen`, `raw`, `cbreak`, `noecho`, `keypad`, `stdscr`]],

  ["endwin"] = [[
**`endwin`** — Restore terminal and free resources (`<curses.h>`)

```c
endwin();   // must call after curses work is done
```

Restores terminal to the mode before `initscr()` or `newterm()`. Frees curses memory. Safe to call multiple times — after the first call, `stdscr` is invalid.

**See also:** `initscr`, `delscreen`, `newterm`, `isendwin`]],

  ["newwin"] = [[
**`newwin`** — Create a new window (`<curses.h>`)

```c
WINDOW *win = newwin(nlines, ncols, begin_y, begin_x);
// Creates a window of size nlines × ncols at position (begin_y, begin_x)
// If nlines or ncols is 0, the window extends to the screen edge

delwin(win);   // free when done
// Sub-windows (derwin, subwin) share memory with parent
```

**See also:** `delwin`, `subwin`, `derwin`, `mvwin`, `duplwin`]],

  ["delwin"] = [[
**`delwin`** — Delete a curses window (`<curses.h>`)

```c
delwin(win);   // free window resources
```

Deleting a sub-window created by `subwin()` or `derwin()` does **not** free the shared memory (owned by the parent). Deleting the parent first leaves sub-windows in an invalid state.

**See also:** `newwin`, `subwin`, `derwin`, `mvwin`]],

  ["subwin"] = [[
**`subwin`** — Create a sub-window within an existing window (`<curses.h>`)

```c
WINDOW *sub = subwin(parent, nlines, ncols, begin_y, begin_x);
```

Shares memory with the parent window. Changes to one affect the other. Does NOT allocate new character storage.

**See also:** `newwin`, `derwin`, `delwin`, `mvwin`]],

  ["derwin"] = [[
**`derwin`** — Create a derived window, offset relative to parent (`<curses.h>`)

```c
WINDOW *der = derwin(parent, nlines, ncols, y_offset, x_offset);
```

Like `subwin`, but the origin is relative to the parent window's origin (not absolute screen coordinates). Shares character storage with parent.

**See also:** `subwin`, `newwin`, `delwin`, `mvderwin`]],

  -- ── Output ─────────────────────────────────────────────────────────────────

  ["printw"] = [[
**`printw`** — Print formatted output to stdscr (`<curses.h>`)

```c
printw("hello %s %d", name, count);    // like printf, output to stdscr
mvprintw(5, 10, "(%d, %d)", x, y);     // move then print
wprintw(win, "value: %f", val);        // print to specific window
mvwprintw(win, 2, 3, "at (%d)", pos);  // move in window then print
```

Uses `printf`-style format strings. Output is buffered until `refresh()` or `wrefresh()` is called.

**See also:** `addch`, `addstr`, `mvaddstr`, `printw`, `refresh`]],

  ["addch"] = [[
**`addch`** — Add a single character to stdscr (`<curses.h>`)

```c
addch('A' | A_BOLD);                // bold 'A' at current cursor
mvaddch(10, 20, '*');               // move then add
waddch(win, ch);                    // add to window
mvwaddch(win, y, x, ch);           // move in window then add
```

Character is OR'd with attributes (`A_BOLD`, `A_REVERSE`, `A_UNDERLINE`, `A_BLINK`, etc.). The current cursor advances.

**See also:** `addstr`, `printw`, `echochar`, `mvwaddch`, `insch`]],

  ["addstr"] = [[
**`addstr`** — Add a string to stdscr at current cursor (`<curses.h>`)

```c
addstr("hello");                    // plain string
mvaddstr(15, 0, "positioned");      // move then add
waddstr(win, "in window");         // to a specific window
mvwaddstr(win, y, x, "text");      // move + window
```

**See also:** `addch`, `printw`, `waddstr`, `mvaddstr`, `insstr`]],

  -- ── Input ──────────────────────────────────────────────────────────────────

  ["getch"] = [[
**`getch`** — Get a character from terminal (`<curses.h>`)

```c
int ch = getch();                   // block until keypress
int ch = wgetch(win);              // window-specific
int ch = mvgetch(y, x);            // move then get
int ch = mvwgetch(win, y, x);     // move + window

// With keypad enabled:
if (ch == KEY_UP)     { /* up arrow */ }
if (ch == KEY_F(1))   { /* F1 */ }
if (ch == KEY_RESIZE) { /* terminal resized */ }
```

Returns `ERR` on failure or if `nodelay()` is set and no key is ready. With `keypad(stdscr, TRUE)`, returns KEY_ codes for function/arrow keys.

**See also:** `keypad`, `nodelay`, `halfdelay`, `timeout`, `ungetch`, `flushinp`, `scanw`]],

  ["scanw"] = [[
**`scanw`** — Formatted input from terminal (`<curses.h>`)

```c
scanw("%d %s", &num, buf);           // like scanf from stdscr
mvscanw(y, x, "%d", &val);          // move then scan
wscanw(win, "%s", buf);             // scan from window
mvwscanw(win, y, x, "%s", buf);    // move + window
```

**See also:** `getch`, `printw`, `flushinp`]],

  ["ungetch"] = [[
**`ungetch`** — Push a character back onto the input queue (`<curses.h>`)

```c
ungetch(ch);    // next getch() will return ch (can push multiple)
```

**See also:** `getch`, `flushinp`, `wunctrl`]],

  -- ── Cursor ─────────────────────────────────────────────────────────────────

  ["move"] = [[
**`move`** — Move cursor in stdscr (`<curses.h>`)

```c
move(y, x);          // move stdscr cursor to (y, x)
wmove(win, y, x);    // move window cursor
```

Next add/output operation writes at the new position. Coordinate: (0,0) = top-left.

**See also:** `getyx`, `getbegyx`, `getmaxyx`, `leaveok`, `curs_set`]],

  ["curs_set"] = [[
**`curs_set`** — Set cursor visibility (`<curses.h>`)

```c
curs_set(0);    // invisible
curs_set(1);    // normal (visible)
curs_set(2);    // very visible (block cursor)
```

Returns the previous visibility state, or `ERR` if the terminal doesn't support the requested mode.

**See also:** `move`, `leaveok`, `intrflush`]],

  -- ── Refresh ────────────────────────────────────────────────────────────────

  ["refresh"] = [[
**`refresh`** — Write pending output to terminal (`<curses.h>`)

```c
refresh();                // make changes to stdscr visible
wrefresh(win);            // make changes to win visible
wnoutrefresh(win);        // mark for update (no actual output)
doupdate();               // output all wnoutrefresh'd windows at once
```

Changes are buffered internally until `refresh()` / `wrefresh()` syncs them to the terminal. Use `wnoutrefresh` + `doupdate` for seamless multi-window updates (avoids flicker).

**See also:** `doupdate`, `wnoutrefresh`, `redrawwin`, `wredrawln`, `touchwin`, `untouchwin`]],

  ["doupdate"] = [[
**`doupdate`** — Output all pending window changes (`<curses.h>`)

```c
wnoutrefresh(win1);
wnoutrefresh(win2);
wnoutrefresh(win3);
doupdate();          // all 3 windows updated in one physical render
```

**See also:** `refresh`, `wnoutrefresh`, `redrawwin`]],

  -- ── Attributes ─────────────────────────────────────────────────────────────

  ["attron"] = [[
**`attron`** — Turn on window attributes (`<curses.h>`)

```c
attron(A_BOLD | A_UNDERLINE);   // stdscr: turn on bold + underline
attroff(A_BOLD);                // turn off bold

wattron(win, A_REVERSE);        // window-specific
wattroff(win, A_REVERSE);

attrset(A_NORMAL);              // set attributes to exact set (clear others)

// Common attributes:
// A_NORMAL, A_STANDOUT, A_UNDERLINE, A_REVERSE, A_BLINK,
// A_DIM, A_BOLD, A_PROTECT, A_INVIS, A_ALTCHARSET
```

Attributes apply to subsequent output operations. Use `COLOR_PAIR(n)` to set colour:
```c
attron(COLOR_PAIR(1));   // use colour pair 1
```

**See also:** `attroff`, `attrset`, `standout`, `standend`, `start_color`, `init_pair`, `COLOR_PAIR`]],

  ["standout"] = [[
**`standout`** — Enable standout mode (reverse video usually) (`<curses.h>`)

```c
standout();     // turn on standout
printw("highlighted");
standend();     // turn off
```

Equivalent to `attron(A_STANDOUT)` / `attroff(A_STANDOUT)`.

**See also:** `attron`, `standend`]],

  -- ── Colour ─────────────────────────────────────────────────────────────────

  ["start_color"] = [[
**`start_color`** — Initialise colour support (`<curses.h>`)

```c
if (has_colors()) {
    start_color();
    use_default_colors();         // allow -1 for terminal default
    init_pair(1, COLOR_RED, COLOR_BLACK);
    attron(COLOR_PAIR(1));
}
```

Must be called before any `init_pair()` or `COLOR_PAIR()` usage. Returns `OK` or `ERR` (terminal doesn't support colour). Use `has_colors()` to check first.

**See also:** `has_colors`, `init_pair`, `COLOR_PAIR`, `use_default_colors`, `can_change_color`, `init_color`]],

  ["init_pair"] = [[
**`init_pair`** — Define a colour pair (`<curses.h>`)

```c
init_pair(1, COLOR_RED, COLOR_WHITE);    // pair 1: red foreground, white bg
init_pair(2, COLOR_GREEN, -1);           // pair 2: green fg, default bg

attron(COLOR_PAIR(1));
```

Numbered 1–`COLOR_PAIRS`-1 (pair 0 is reserved for terminal defaults). Foreground/background colours: `COLOR_BLACK`, `COLOR_RED`, `COLOR_GREEN`, `COLOR_YELLOW`, `COLOR_BLUE`, `COLOR_MAGENTA`, `COLOR_CYAN`, `COLOR_WHITE`. Use `-1` with `use_default_colors()` for terminal default.

**See also:** `start_color`, `has_colors`, `COLOR_PAIR`, `use_default_colors`, `color_content`, `pair_content`, `init_color`]],

  ["has_colors"] = [[
**`has_colors`** — Check if terminal supports colour (`<curses.h>`)

```c
if (has_colors()) { start_color(); }
```

Returns `TRUE` or `FALSE`. Call before `start_color()`.

**See also:** `start_color`, `init_pair`, `COLOR_PAIR`, `can_change_color`]],

  ["use_default_colors"] = [[
**`use_default_colors`** — Allow -1 fg/bg in init_pair for terminal default (`<curses.h>`)

```c
use_default_colors();
init_pair(1, COLOR_RED, -1);   // red text on terminal default bg
```

**See also:** `start_color`, `init_pair`, `assume_default_colors`]],

  -- ── Options ────────────────────────────────────────────────────────────────

  ["cbreak"] = [[
**`cbreak`** — Disable line buffering (`<curses.h>`)

```c
cbreak();      // input available character-by-character (no Enter needed)
nocbreak();    // restore line buffering
```

`cbreak` (or `cb` `raw`) is usually called right after `initscr()`. In `cbreak` mode, `Ctrl+C` and `Ctrl+Z` still work as signals. Use `raw()` to also disable signal handling.

**See also:** `raw`, `nocbreak`, `noraw`, `echo`, `noecho`, `halfdelay`, `nodelay`]],

  ["raw"] = [[
**`raw`** — Disable line buffering AND signal processing (`<curses.h>`)

```c
raw();         // Ctrl+C sends literal 0x03 instead of SIGINT
noraw();       // restore signal processing
```

Like `cbreak()` but also disables `Ctrl+C`/`Ctrl+Z`/`Ctrl+\` signal processing. Use `cbreak` if you want signals to still work.

**See also:** `cbreak`, `noraw`, `noecho`]],

  ["echo"] = [[
**`echo`** / **`noecho`** — Control whether typed characters are displayed (`<curses.h>`)

```c
noecho();   // don't echo typed characters (usual for interactive programs)
echo();     // echo typed characters
```

Used directly after `initscr()`. `noecho()` is typical for full-screen programs.

**See also:** `cbreak`, `raw`, `getch`]],

  ["keypad"] = [[
**`keypad`** — Enable interpretation of function/arrow keys (`<curses.h>`)

```c
keypad(stdscr, TRUE);    // enable KEY_ codes (KEY_UP, KEY_DOWN, KEY_F(1), etc.)
keypad(win, FALSE);      // disable, return raw escape sequences
```

When enabled, `getch()` returns `KEY_` codes for function keys, arrow keys, etc. When disabled, escape sequences are returned as individual characters.

**See also:** `getch`, `nodelay`, `meta`, `has_key`]],

  ["nodelay"] = [[
**`nodelay`** — Set non-blocking input (`<curses.h>`)

```c
nodelay(stdscr, TRUE);   // getch() returns ERR if no key ready
nodelay(stdscr, FALSE);  // getch() blocks (default)

timeout(100);            // 100ms timeout
wtimeout(win, 500);      // per-window timeout
```

Makes `getch()` non-blocking. For a timeout instead, use `halfdelay(1)` (tenths of seconds) or `timeout(ms)`.

**See also:** `getch`, `halfdelay`, `timeout`, `cbreak`]],

  ["halfdelay"] = [[
**`halfdelay`** — Set timed delay input mode (`<curses.h>`)

```c
halfdelay(5);            // getch() returns ERR after ~0.5 seconds
halfdelay(0);            // disable, return to blocking
```

Input is in tenths of a second (1–255). Equivalent to `nodelay()` with a timer.

**See also:** `nodelay`, `timeout`, `cbreak`, `getch`]],

  ["timeout"] = [[
**`timeout`** — Set blocking delay for input (`<curses.h>`)

```c
timeout(250);            // wait up to 250ms for input, then ERR
wtimeout(win, 100);      // per-window
timeout(-1);             // blocking (default)
timeout(0);              // non-blocking (like nodelay)
```

**See also:** `nodelay`, `halfdelay`, `getch`]],

  -- ── Borders ────────────────────────────────────────────────────────────────

  ["border"] = [[
**`border`** — Draw a border around the edges of a window (`<curses.h>`)

```c
// All 8 characters specified:
border(LS, RS, TS, BS, TL, TR, BL, BR);
// Usually pass 0 to use defaults:
border(0, 0, 0, 0, 0, 0, 0, 0);     // default border

wborder(win, 0, 0, 0, 0, 0, 0, 0, 0);  // window-specific
box(win, 0, 0);                         // simpler: just vertical + horizontal
```

Arguments: left side, right side, top side, bottom side, top-left, top-right, bottom-left, bottom-right. Passing `0` uses the default line-drawing characters.

**See also:** `box`, `hline`, `vline`, `mvhline`, `mvvline`]],

  ["box"] = [[
**`box`** — Draw a box around a window (`<curses.h>`)

```c
box(win, 0, 0);                // default vertical & horizontal chars
box(win, ACS_VLINE, ACS_HLINE);  // explicit line-drawing chars
```

Simpler than `border()` — just draws the four sides. The second and third args are the vertical and horizontal line-drawing characters.

**See also:** `border`, `hline`, `vline`, `newwin`]],

  ["hline"] = [[
**`hline`** — Draw a horizontal line (`<curses.h>`)

```c
hline(ACS_HLINE, 20);              // horizontal line of 20 chars at cursor
mvhline(10, 5, ACS_HLINE, 30);     // at position (10, 5), 30 chars
whline(win, ACS_HLINE, 15);
mvwhline(win, y, x, ch, n);
vline(ACS_VLINE, 10);              // vertical line
```

Drawing characters: `ACS_HLINE`, `ACS_VLINE`, `ACS_PLUS`, `ACS_LTEE`, `ACS_RTEE`, `ACS_TTEE`, `ACS_BTEE`.

**See also:** `border`, `box`, `vline`, `mvhline`, `mvvline`]],

  ["vline"] = [[
**`vline`** — Draw a vertical line (`<curses.h>`)

```c
vline(ACS_VLINE, 15);               // vertical line of 15 chars
mvvline(5, 10, ACS_VLINE, 20);      // at (5, 10), 20 chars
wvline(win, ch, n);
mvwvline(win, y, x, ch, n);
```

**See also:** `hline`, `border`, `box`]],

  -- ── Scrolling and Misc ─────────────────────────────────────────────────────

  ["scroll"] = [[
**`scroll`** — Scroll a window (`<curses.h>`)

```c
scroll(win);              // scroll up one line
scrl(n);                  // scroll stdscr up by n lines (negative = down)
wscrl(win, n);            // scroll specific window
setscrreg(top, bot);      // set scroll region (stdscr)
wsetscrreg(win, t, b);    // set scroll region (window)
```

Window must have `scrollok()` enabled:
```c
scrollok(win, TRUE);      // allow scrolling
```

**See also:** `scrollok`, `setscrreg`, `mvwin`, `wsetscrreg`]],

  ["beep"] = [[
**`beep`** — Audible or visible alert (`<curses.h>`)

```c
beep();      // terminal bell (or flash if bell unsupported)
flash();     // flash screen (visible bell)
```

**See also:** `flash`, `napms`]],

  ["flash"] = [[
**`flash`** — Visible terminal flash (`<curses.h>`)

```c
flash();     // flash screen (inverse video briefly)
```

**See also:** `beep`]],

  ["napms"] = [[
**`napms`** — Sleep for a specified number of milliseconds (`<curses.h>`)

```c
napms(100);  // sleep 100ms
```

Unlike `sleep()` / `nanosleep()`, `napms` continues to process terminal input. May be interrupted by signals.

**See also:** `getch`, `timeout`, `beep`]],

  ["flushinp"] = [[
**`flushinp`** — Discard all pending input (`<curses.h>`)

```c
flushinp();   // ignore any queued keystrokes
```

Useful after getting a resize event (`KEY_RESIZE`) or when navigating between screens.

**See also:** `getch`, `ungetch`, `keypad`]],

  -- ── notcurses ──────────────────────────────────────────────────────────────

  ["notcurses"] = [[
**`notcurses`** — Modern terminal graphics library (`<notcurses/notcurses.h>`)

```c
#include <notcurses/notcurses.h>

struct notcurses_options opts = {0};
struct ncplane *ncp = notcurses_init(&opts, stdout);
// ... use ncplane API ...
notcurses_stop(ncp);
```

Modern alternative to ncurses with Unicode, images, video, and 24-bit colour support.

**See also:** `ncplane`, `ncdirect`, `notcurses_init`, `notcurses_stop`, `ncplane_putstr`, `notcurses_render`]],

  ["ncplane"] = [[
**`ncplane`** — A drawable surface in notcurses

```c
struct ncplane* n = ncplane_aligned(ncp, nrows, ncols, y, x, align);
ncplane_putstr(n, "hello");
ncplane_putstr_aligned(n, align, "centered");
ncplane_printf(n, "value: %d", val);
notcurses_render(ncp);

// Destroy:
ncplane_destroy(n);
```

Each window/panel is an `ncplane`. Can be piled, moved, and resized independently.

**See also:** `notcurses`, `ncdirect`, `ncplane_putstr`, `ncplane_putegc`, `notcurses_render`]],

  ["ncdirect"] = [[
**`ncdirect`** — Direct mode (simple text output) in notcurses

```c
struct ncdirect *nc = ncdirect_init(NULL, stdout, 0);
ncdirect_puts(nc, "colored text\n", 0, 0xff0000, 0);
ncdirect_stop(nc);
```

Lighter than `notcurses_init` for simple coloured output without full-screen management.

**See also:** `notcurses`, `notcurses_init`]],
}
