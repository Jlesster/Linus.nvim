-- linus/keywords/cpp/filesystem.lua
-- Filesystem library (C++17).

return {

  ["path"] = [[
**`std::filesystem::path`** · Cross-platform filesystem path (`<filesystem>`, C++17)

```cpp
#include <filesystem>
namespace fs = std::filesystem;

fs::path p = "/usr/local/bin/app";
p = p.parent_path();      // "/usr/local/bin"
p = p.filename();          // "app"
p = p.stem();              // "app"  (no extension)
p = p.extension();         // ""     (".txt" for "app.txt")

p /= "subdir";             // append (uses native separator)
p += "suffix";             // concatenate raw string
```

Automatic platform-specific separator (`/` or `\\`). No validation — invalid paths still create a valid `path` object (check with `exists()`).

**See also →** `std::filesystem::directory_entry`, `std::filesystem::exists`, `std::filesystem::create_directory`]],

  ["current_path"] = [[
**`std::filesystem::current_path`** · Get/set current working directory (`<filesystem>`, C++17)

```cpp
auto cwd = std::filesystem::current_path();
std::filesystem::current_path("/tmp");     // change
```

**See also →** `std::filesystem::path`, `std::filesystem::absolute`]],

  ["exists"] = [[
**`std::filesystem::exists`** · Check if path exists (`<filesystem>`, C++17)

```cpp
if (std::filesystem::exists("/tmp/foo")) { /* file or dir */ }
```

**Symlinks** are followed. Checks both file and directory.

**See also →** `std::filesystem::is_regular_file`, `std::filesystem::is_directory`, `std::filesystem::status`]],

  ["is_regular_file"] = [[
**`std::filesystem::is_regular_file`** · Check if path is a regular file (`<filesystem>`, C++17)

```cpp
if (std::filesystem::is_regular_file(p)) { /* ... */ }
```

**See also →** `std::filesystem::is_directory`, `std::filesystem::is_symlink`, `std::filesystem::is_block_file`, `std::filesystem::status`]],

  ["is_directory"] = [[
**`std::filesystem::is_directory`** · Check if path is a directory (`<filesystem>`, C++17)

```cpp
if (std::filesystem::is_directory(p)) { /* ... */ }
```

**See also →** `std::filesystem::is_regular_file`, `std::filesystem::create_directory`, `std::filesystem::directory_iterator`]],

  ["create_directory"] = [[
**`std::filesystem::create_directory`** · Create a directory (`<filesystem>`, C++17)

```cpp
std::filesystem::create_directory("/tmp/newdir");
std::filesystem::create_directories("/tmp/a/b/c");  // creates parents too
```

`create_directory` fails if parent doesn't exist. `create_directories` creates all missing intermediate directories.

**See also →** `std::filesystem::is_directory`, `std::filesystem::remove`, `std::filesystem::copy`]],

  ["remove"] = [[
**`std::filesystem::remove`** · Delete a file or empty directory (`<filesystem>`, C++17)

```cpp
bool removed = std::filesystem::remove("file.txt");
std::uintmax_t n = std::filesystem::remove_all("/tmp/dir");  // recursive delete
```

`remove` returns `false` if file doesn't exist. `remove_all` returns number of files removed.

**See also →** `std::filesystem::create_directory`, `std::filesystem::copy`, `std::filesystem::rename`]],

  ["copy"] = [[
**`std::filesystem::copy`** · Copy files or directories (`<filesystem>`, C++17)

```cpp
std::filesystem::copy("source.txt", "dest.txt");           // file copy
std::filesystem::copy("src_dir", "dst_dir",                 // recursive directory copy
    std::filesystem::copy_options::recursive);
```

Options: `skip_existing`, `overwrite_existing`, `update_existing`, `recursive`, `directories_only`, etc.

**See also →** `std::filesystem::copy_file`, `std::filesystem::rename`, `std::filesystem::remove`]],

  ["rename"] = [[
**`std::filesystem::rename`** · Move/rename file or directory (`<filesystem>`, C++17)

```cpp
std::filesystem::rename("old.txt", "new.txt");
```

Works across filesystems (copy + delete if needed). For directories — source and target must be the same type (both regular or both directories).

**See also →** `std::filesystem::copy`, `std::filesystem::remove`]],

  ["file_size"] = [[
**`std::filesystem::file_size`** · Get file size in bytes (`<filesystem>`, C++17)

```cpp
std::uintmax_t sz = std::filesystem::file_size("data.bin");
```

Throws `std::filesystem::filesystem_error` if file does not exist or is not a regular file.

**See also →** `std::filesystem::exists`, `std::filesystem::space`, `std::filesystem::resize_file`]],

  ["last_write_time"] = [[
**`std::filesystem::last_write_time`** · Get/set file modification time (`<filesystem>`, C++17)

```cpp
auto ftime = std::filesystem::last_write_time("file.txt");
auto tp = std::chrono::clock_cast<std::chrono::system_clock>(ftime);
```

Returns `std::filesystem::file_time_type` (which is a `time_point`). Conversion to calendar types requires `clock_cast` (C++20) or manual duration math.

**See also →** `std::filesystem::path`, `std::chrono::system_clock`]],

  ["directory_iterator"] = [[
**`std::filesystem::directory_iterator`** · Iterate over directory entries (`<filesystem>`, C++17)

```cpp
for (const auto& entry : std::filesystem::directory_iterator("/path")) {
    entry.path();
    entry.is_regular_file();
    entry.file_size();
}
```

**Not recursive.** Order is unspecified. Fails if path is not a directory.

**See also →** `std::filesystem::recursive_directory_iterator`, `std::filesystem::directory_entry`]],

  ["recursive_directory_iterator"] = [[
**`std::filesystem::recursive_directory_iterator`** · Recursively iterate directory tree (`<filesystem>`, C++17)

```cpp
for (const auto& entry : std::filesystem::recursive_directory_iterator("/path")) {
    entry.path();
}

// Skip subdirectories:
auto it = std::filesystem::recursive_directory_iterator("/path");
for (; it != end(it); ++it) {
    if (it->is_directory()) it.disable_recursion_pending();
}
```

**See also →** `std::filesystem::directory_iterator`, `std::filesystem::directory_entry`]],

  ["space"] = [[
**`std::filesystem::space`** · Filesystem capacity information (`<filesystem>`, C++17)

```cpp
auto info = std::filesystem::space("/");
info.capacity;       // total bytes
info.free;           // bytes free
info.available;      // bytes free to non-privileged process
```

**See also →** `std::filesystem::file_size`, `std::filesystem::path`]],

  ["temp_directory_path"] = [[
**`std::filesystem::temp_directory_path`** · Get temp directory (`<filesystem>`, C++17)

```cpp
auto tmp = std::filesystem::temp_directory_path();   // e.g. "/tmp"
```

Follows platform conventions: `TMPDIR`, `TMP`, `TEMP`, `/tmp`.

**See also →** `std::filesystem::current_path`, `std::filesystem::absolute`]],

  ["absolute"] = [[
**`std::filesystem::absolute`** · Convert to absolute path (`<filesystem>`, C++17)

```cpp
auto abs = std::filesystem::absolute("rel/path");   // e.g. "/cwd/rel/path"
```

Does **not** resolve symlinks or normalize `.`/`..`. Use `std::filesystem::canonical` for that.

**See also →** `std::filesystem::canonical`, `std::filesystem::relative`, `std::filesystem::current_path`]],

  ["canonical"] = [[
**`std::filesystem::canonical`** · Resolve symlinks + normalize path (`<filesystem>`, C++17)

```cpp
auto real = std::filesystem::canonical("rel/../link/file");
```

**Path must exist** — throws `std::filesystem::filesystem_error` if it doesn't. For non-existent paths, use `std::filesystem::weakly_canonical`.

**See also →** `std::filesystem::absolute`, `std::filesystem::weakly_canonical`, `std::filesystem::proximate`]],

  ["weakly_canonical"] = [[
**`std::filesystem::weakly_canonical`** · Normalize path, may not exist (`<filesystem>`, C++17)

```cpp
auto norm = std::filesystem::weakly_canonical("rel/../bogus");  // normalizes last existing portion
```

Like `canonical` but doesn't require the entire path to exist — only normalizes what it can.

**See also →** `std::filesystem::canonical`, `std::filesystem::absolute`, `std::filesystem::proximate`]],

  ["relative"] = [[
**`std::filesystem::relative`** · Convert to relative path (`<filesystem>`, C++17)

```cpp
auto rel = std::filesystem::relative("/a/b/c", "/a");   // "b/c"
```

**See also →** `std::filesystem::absolute`, `std::filesystem::proximate`]],

  ["proximate"] = [[
**`std::filesystem::proximate`** · Find closest relative path (`<filesystem>`, C++17)

```cpp
auto p = std::filesystem::proximate("/a/b/c", "/a/x");  // "../b/c"
```

Like `relative` but returns the shorter of `relative()` or the original path.

**See also →** `std::filesystem::relative`, `std::filesystem::absolute`]],

  ["permissions"] = [[
**`std::filesystem::permissions`** · Change file permissions (`<filesystem>`, C++17)

```cpp
std::filesystem::permissions("file.txt",
    std::filesystem::perms::owner_read | std::filesystem::perms::owner_write);
```

Use `std::filesystem::status(p).permissions()` to query.

**See also →** `std::filesystem::status`, `std::filesystem::perms`, `std::filesystem::file_status`]],

  ["status"] = [[
**`std::filesystem::status`** · Get file status (no symlink follow) (`<filesystem>`, C++17)

```cpp
auto st = std::filesystem::status("symlink");  // if symlink → status(symlink)
auto st = std::filesystem::symlink_status("symlink");  // status(link itself)
```

Returns `std::filesystem::file_status` with type (`regular_file`, `directory`, `symlink`, etc.) and permissions.

**See also →** `std::filesystem::status_known`, `std::filesystem::is_regular_file`, `std::filesystem::permissions`]],
}
