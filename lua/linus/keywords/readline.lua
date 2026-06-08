-- linus/keywords/readline.lua
-- GNU Readline library (<readline/readline.h>, <readline/history.h>).

return {

  ["readline"] = [[
**`readline`** — Read a line of input with editing (`<readline/readline.h>`)

```c
#include <stdio.h>
#include <readline/readline.h>
#include <readline/history.h>

int main(void) {
    char *input;
    while ((input = readline("> ")) != NULL) {
        if (*input) add_history(input);         // save to history
        printf("You said: '%s'\n", input);
        free(input);                            // readline malloc's the result
    }
    return 0;
}
```

Uses `rl_outstream` for output. Supports Emacs/vim editing modes, tab completion, history search.

**See also:** `add_history`, `rl_bind_key`, `rl_completion_matches`, `rl_line_buffer`, `free`]],

  ["add_history"] = [[
**`add_history`** — Add a line to the history list (`<readline/history.h>`)

```c
add_history(input);   // append to history
```

Duplicate lines are not added if `HISTCONTROL` ignores duplicates. Use `using_history()` then `add_history()` to wipe and replace the history.

**See also:** `remove_history`, `clear_history`, `history_list`, `history_length`, `using_history`]],

  ["remove_history"] = [[
**`remove_history`** — Remove an entry from history (`<readline/history.h>`)

```c
HIST_ENTRY *entry = remove_history(0);   // remove entry at index 0
free(entry->line);
free(entry);
```

**See also:** `add_history`, `clear_history`, `history_list`, `history_length`]],

  ["clear_history"] = [[
**`clear_history`** — Clear the entire history list (`<readline/history.h>`)

```c
clear_history();   // free all entries
```

**See also:** `add_history`, `remove_history`, `history_list`]],

  ["history_list"] = [[
**`history_list`** — Get the full history as an array (`<readline/history.h>`)

```c
HIST_ENTRY **list = history_list();
if (list) {
    for (int i = 0; list[i]; i++)
        printf("%d: %s\n", i, list[i]->line);
}
```

Returns `NULL` if empty. The array is owned by readline — do not free individual entries without `remove_history`.

**See also:** `add_history`, `clear_history`, `history_length`, `using_history`]],

  ["history_length"] = [[
**`history_length`** — The number of entries in history (`<readline/history.h>`)

```c
extern int history_length;           // current count (read-only in practice)
extern int history_max_entries;      // max before truncation (0 = unlimited, default)
```

**See also:** `add_history`, `history_list`, `HIST_ENTRY`]],

  ["rl_bind_key"] = [[
**`rl_bind_key`** — Bind a key to a function (`<readline/readline.h>`)

```c
// Custom handler:
int insert_date(int ch, int key) {
    char date[64];
    time_t t = time(NULL);
    strftime(date, sizeof(date), "%Y-%m-%d", localtime(&t));
    rl_insert_text(date);
    return 0;
}

rl_bind_key('\t', rl_complete);          // Tab: complete
rl_bind_keyseq("\\C-x\\C-d", insert_date); // Ctrl+X Ctrl+D: insert date
```

`rl_bind_keyseq` for multi-key sequences. Key names: `"\\C-x"` (Ctrl+X), `"\\M-a"` (Alt+A).

**See also:** `rl_completion_matches`, `rl_insert_text`, `rl_line_buffer`, `rl_variable_bind`]],

  ["rl_completion_matches"] = [[
**`rl_completion_matches`** — Generate completion matches (`<readline/readline.h>`)

```c
static char **my_completion(const char *text, int start, int end) {
    rl_attempted_completion_over = 0;
    return rl_completion_matches(text, my_generator);
}

static char *my_generator(const char *text, int state) {
    static int idx;
    static const char *words[] = {"apple", "banana", "cherry", NULL};
    if (state == 0) idx = 0;
    while (words[idx]) {
        if (strncmp(words[idx], text, strlen(text)) == 0)
            return strdup(words[idx++]);   // must be malloc'd
        idx++;
    }
    return NULL;
}

rl_attempted_completion_function = my_completion;
```

**See also:** `rl_attempted_completion_function`, `rl_completion_append_character`, `rl_filename_completion_function`]],

  ["rl_line_buffer"] = [[
**`rl_line_buffer`** — The current line buffer (`<readline/readline.h>`)

```c
extern char *rl_line_buffer;        // full line text
extern int rl_point;                // cursor position (index into rl_line_buffer)
extern int rl_end;                  // line length

// In a completion hook:
printf("completing at position %d in '%s'\n", rl_point, rl_line_buffer);
```

**See also:** `readline`, `rl_point`, `rl_end`, `rl_insert_text`, `rl_delete_text`]],

  ["rl_point"] = [[
**`rl_point`** — Cursor position in the line buffer (`<readline/readline.h>`)

```c
extern int rl_point;    // index into rl_line_buffer
```

Set to move cursor: `rl_point = 0; rl_redisplay();` to jump to start.

**See also:** `rl_line_buffer`, `rl_end`, `rl_redisplay`]],

  ["rl_insert_text"] = [[
**`rl_insert_text`** — Insert text at the cursor (`<readline/readline.h>`)

```c
rl_insert_text("Hello");   // inserts at current rl_point
```

Useful in key binding handlers and completion functions.

**See also:** `rl_delete_text`, `rl_line_buffer`, `rl_bind_key`]],

  ["rl_redisplay"] = [[
**`rl_redisplay`** — Force redisplay of the input line (`<readline/readline.h>`)

```c
rl_point = 0;      // move to beginning
rl_redisplay();    // update display
```

**See also:** `rl_line_buffer`, `rl_point`, `rl_replace_line`, `rl_on_new_line`]],

  ["rl_startup_hook"] = [[
**`rl_startup_hook`** — Function called before reading first line (`<readline/readline.h>`)

```c
static int startup(void) {
    rl_bind_key('\t', rl_complete);
    return 0;
}

rl_startup_hook = startup;
```

**See also:** `rl_bind_key`, `readline`, `rl_pre_input_hook`]],

  ["rl_attempted_completion_function"] = [[
**`rl_attempted_completion_function`** — Custom completion function (`<readline/readline.h>`)

```c
char **my_cpl(const char *text, int start, int end);
rl_attempted_completion_function = my_cpl;
```

- `start`, `end`: word boundaries in `rl_line_buffer`.
- Return: `NULL` for fallback (filename), array of matches, or set `rl_attempted_completion_over = 1`.

**See also:** `rl_completion_matches`, `rl_attempted_completion_over`, `rl_filename_completion_function`]],

  ["rl_completion_append_character"] = [[
**`rl_completion_append_character`** — Character appended after a single match (`<readline/readline.h>`)

```c
rl_completion_append_character = ' ';   // default is ' '
rl_completion_append_character = '\0';  // append nothing
```

**See also:** `rl_completion_matches`, `rl_attempted_completion_function`]],
}
