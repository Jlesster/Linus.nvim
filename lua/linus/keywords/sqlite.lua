-- linus/keywords/sqlite.lua
-- SQLite3 C API (<sqlite3.h>).

return {

  ["sqlite3_open"] = [[
**`sqlite3_open`** — Open a database (`<sqlite3.h>`)

```c
#include <sqlite3.h>

sqlite3 *db;
int rc = sqlite3_open("data.db", &db);
if (rc != SQLITE_OK) {
    fprintf(stderr, "Can't open: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return 1;
}
// ... use db ...
sqlite3_close(db);
```

Variants: `sqlite3_open16` (UTF-16), `sqlite3_open_v2` (with flags, VFS).

**See also:** `sqlite3_close`, `sqlite3_errmsg`, `sqlite3_open_v2`, `SQLITE_OK`]],

  ["sqlite3_close"] = [[
**`sqlite3_close`** — Close a database (`<sqlite3.h>`)

```c
sqlite3_close(db);   // finalises any unfinalised statements
```

Returns `SQLITE_BUSY` if there are unfinalised prepared statements. Use `sqlite3_close_v2` for deferred close.

**See also:** `sqlite3_open`, `sqlite3_close_v2`, `sqlite3_finalize`]],

  ["sqlite3_close_v2"] = [[
**`sqlite3_close_v2`** — Close database with deferred finalization (`<sqlite3.h>`)

```c
sqlite3_close_v2(db);   // closes when all prepared statements are finalised
```

**See also:** `sqlite3_close`, `sqlite3_open`]],

  ["sqlite3_exec"] = [[
**`sqlite3_exec`** — Execute one or more SQL statements (`<sqlite3.h>`)

```c
char *err = NULL;
int rc = sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS users (id INT, name TEXT);"
                            "INSERT INTO users VALUES (1, 'Alice');",
                      NULL, NULL, &err);
if (rc != SQLITE_OK) {
    fprintf(stderr, "SQL error: %s\n", err);
    sqlite3_free(err);
}
```

Callback variant: `sqlite3_exec(db, sql, callback, user_data, &errmsg)` — called for each result row.

**See also:** `sqlite3_prepare_v2`, `sqlite3_errmsg`, `sqlite3_free`]],

  ["sqlite3_prepare_v2"] = [[
**`sqlite3_prepare_v2`** — Compile SQL into a prepared statement (`<sqlite3.h>`)

```c
sqlite3_stmt *stmt;
int rc = sqlite3_prepare_v2(db, "SELECT id, name FROM users WHERE id = ?", -1, &stmt, NULL);
if (rc != SQLITE_OK) { /* error */ }

sqlite3_bind_int(stmt, 1, 42);   // bind to first ? parameter

while (sqlite3_step(stmt) == SQLITE_ROW) {
    int id = sqlite3_column_int(stmt, 0);
    const unsigned char *name = sqlite3_column_text(stmt, 1);
}

sqlite3_finalize(stmt);
```

**See also:** `sqlite3_bind_*`, `sqlite3_step`, `sqlite3_column_*`, `sqlite3_finalize`]],

  ["sqlite3_step"] = [[
**`sqlite3_step`** — Evaluate a prepared statement (`<sqlite3.h>`)

```c
rc = sqlite3_step(stmt);
```

Return values:
- `SQLITE_ROW` — a row is ready; call `sqlite3_column_*` to read columns.
- `SQLITE_DONE` — statement finished (no more rows).
- `SQLITE_BUSY` — database is locked; retry.
- `SQLITE_ERROR` — evaluation error.

**See also:** `sqlite3_prepare_v2`, `sqlite3_column_*`, `sqlite3_finalize`, `sqlite3_reset`]],

  ["sqlite3_finalize"] = [[
**`sqlite3_finalize`** — Destroy a prepared statement (`<sqlite3.h>`)

```c
sqlite3_finalize(stmt);   // free resources
```

Must call for every prepared statement before closing the database.

**See also:** `sqlite3_prepare_v2`, `sqlite3_reset`, `sqlite3_close`]],

  ["sqlite3_bind_int"] = [[
**`sqlite3_bind_int`** — Bind an integer to a parameter (`<sqlite3.h>`)

```c
sqlite3_bind_int(stmt, 1, 42);         // int
sqlite3_bind_int64(stmt, 1, (sqlite3_int64)big);  // 64-bit
sqlite3_bind_double(stmt, 1, 3.14);    // floating-point
sqlite3_bind_text(stmt, 1, "Alice", -1, SQLITE_TRANSIENT);  // string
sqlite3_bind_null(stmt, 1);            // NULL
sqlite3_bind_blob(stmt, 1, data, size, SQLITE_TRANSIENT);   // blob
```

Parameter indices start at 1. Named params: `"?name"`, `":name"`, `"@name"`, `"$name"` — use `sqlite3_bind_parameter_index`.

**See also:** `sqlite3_prepare_v2`, `sqlite3_bind_parameter_index`, `SQLITE_TRANSIENT`, `SQLITE_STATIC`]],

  ["sqlite3_bind_text"] = [[
**`sqlite3_bind_text`** — Bind a text string to a parameter (`<sqlite3.h>`)

```c
sqlite3_bind_text(stmt, 1, "Alice", -1, SQLITE_TRANSIENT);
```

- Length: -1 for null-terminated, or explicit byte count.
- Destructor: `SQLITE_TRANSIENT` (copy), `SQLITE_STATIC` (don't copy), or custom `sqlite3_destructor_type`.

**See also:** `sqlite3_bind_int`, `sqlite3_bind_blob`, `sqlite3_bind_null`, `SQLITE_TRANSIENT`]],

  ["sqlite3_bind_blob"] = [[
**`sqlite3_bind_blob`** — Bind a BLOB to a parameter (`<sqlite3.h>`)

```c
sqlite3_bind_blob(stmt, 1, data, nbytes, SQLITE_TRANSIENT);
sqlite3_bind_zeroblob(stmt, 1, size);  // pre-allocate zero-filled
```

**See also:** `sqlite3_bind_text`, `sqlite3_column_blob`, `sqlite3_column_bytes`]],

  ["sqlite3_column_int"] = [[
**`sqlite3_column_int`** — Get column as integer (`<sqlite3.h>`)

```c
int id          = sqlite3_column_int(stmt, 0);
sqlite3_int64 big  = sqlite3_column_int64(stmt, 0);
double val      = sqlite3_column_double(stmt, 0);
const unsigned char *text = sqlite3_column_text(stmt, 0);
int nbytes      = sqlite3_column_bytes(stmt, 0);
const void *blob    = sqlite3_column_blob(stmt, 0);
int col_type    = sqlite3_column_type(stmt, 0);  // SQLITE_INTEGER, SQLITE_TEXT, ...
```

Column indices are 0-based.

**See also:** `sqlite3_step`, `sqlite3_column_name`, `sqlite3_column_count`, `sqlite3_column_type`]],

  ["sqlite3_column_type"] = [[
**`sqlite3_column_type`** — Get the datatype of a column (`<sqlite3.h>`)

```c
switch (sqlite3_column_type(stmt, 0)) {
    case SQLITE_INTEGER: /* int */ break;
    case SQLITE_FLOAT:   /* double */ break;
    case SQLITE_TEXT:    /* string */ break;
    case SQLITE_BLOB:    /* blob */ break;
    case SQLITE_NULL:    /* null */ break;
}
```

**See also:** `sqlite3_column_int`, `sqlite3_column_text`, `sqlite3_column_blob`]],

  ["sqlite3_errmsg"] = [[
**`sqlite3_errmsg`** — Get last error message (`<sqlite3.h>`)

```c
const char *msg = sqlite3_errmsg(db);
// "no such table: foo", "UNIQUE constraint failed", ...
```

Returns a UTF-8 string valid until the next call on the same `sqlite3*`. `sqlite3_errstr(rc)` gives a static string for a result code.

**See also:** `sqlite3_errcode`, `sqlite3_errstr`, `sqlite3_extended_errcode`]],

  ["sqlite3_changes"] = [[
**`sqlite3_changes`** — Get number of rows changed by last statement (`<sqlite3.h>`)

```c
int n = sqlite3_changes(db);   // rows inserted/updated/deleted
```

**See also:** `sqlite3_total_changes`, `sqlite3_last_insert_rowid`]],

  ["sqlite3_last_insert_rowid"] = [[
**`sqlite3_last_insert_rowid`** — Get the rowid of last INSERT (`<sqlite3.h>`)

```c
sqlite3_int64 id = sqlite3_last_insert_rowid(db);
```

**See also:** `sqlite3_changes`, `sqlite3_prepare_v2`]],

  ["sqlite3_backup_init"] = [[
**`sqlite3_backup_init`** — Start online backup of a database (`<sqlite3.h>`)

```c
sqlite3 *from, *to;   // destination and source databases
sqlite3_backup *backup = sqlite3_backup_init(to, "main", from, "main");
if (backup) {
    sqlite3_backup_step(backup, -1);    // copy entire db
    sqlite3_backup_finish(backup);
}
sqlite3_close(to);
```

**See also:** `sqlite3_backup_step`, `sqlite3_backup_finish`, `sqlite3_backup_remaining`]],

  ["sqlite3_create_function"] = [[
**`sqlite3_create_function`** — Register a user-defined scalar function (`<sqlite3.h>`)

```c
static void myfunc(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    int val = sqlite3_value_int(argv[0]);
    sqlite3_result_int(ctx, val * val);  // square
}

sqlite3_create_function(db, "square", 1, SQLITE_UTF8, NULL, myfunc, NULL, NULL);
// Usage: SELECT square(5); -- 25
```

**See also:** `sqlite3_create_aggregate`, `sqlite3_result_*`, `sqlite3_value_*`, `sqlite3_create_window_function`]],
}
