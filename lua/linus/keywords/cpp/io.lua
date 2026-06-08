-- linus/keywords/cpp/io.lua
-- I/O streams and manipulators reference entries.

return {

  ["cout"] = [[
**`std::cout`** · Standard output stream (`<iostream>`)

```cpp
#include <iostream>
std::cout << "hello world" << 42 << std::endl;
```

Connected to stdout (file descriptor 1). Buffered; flushed on `std::endl` (`'\n' + flush`), `std::flush`, or buffer full.

**See also →** `std::cin`, `std::cerr`, `std::clog`, `std::endl`, `std::flush`]],

  ["cin"] = [[
**`std::cin`** · Standard input stream (`<iostream>`)

```cpp
#include <iostream>
int x;
std::cin >> x;            // read int, skip whitespace
std::string s;
std::getline(std::cin, s); // read line (including spaces)
```

Connected to stdin (fd 0). `operator>>` skips leading whitespace. After failed read, stream enters fail state — check after reading: `if (std::cin) { /* ok */ }`.

**See also →** `std::cout`, `std::getline`, `std::stringstream`]],

  ["cerr"] = [[
**`std::cerr`** · Standard error output stream (unbuffered) (`<iostream>`)

```cpp
std::cerr << "error: " << msg << std::endl;
```

Connected to stderr (fd 2). **Unbuffered** — every output appears immediately. Use for error messages and diagnostics.

**See also →** `std::cout`, `std::clog`, `std::endl`]],

  ["clog"] = [[
**`std::clog`** · Standard error output stream (buffered) (`<iostream>`)

```cpp
std::clog << "log message " << timestamp << std::endl;
```

Connected to stderr (fd 2) but **buffered** — more efficient than `std::cerr` for logging output.

**See also →** `std::cerr`, `std::cout`, `std::endl`]],

  ["ifstream"] = [[
**`std::ifstream`** · Input file stream (`<fstream>`)

```cpp
#include <fstream>
std::ifstream f("data.txt");
if (!f) { /* open failed */ }

std::string line;
while (std::getline(f, line)) { process(line); }
```

**See also →** `std::ofstream`, `std::fstream`, `std::stringstream`, `std::getline`]],

  ["ofstream"] = [[
**`std::ofstream`** · Output file stream (`<fstream>`)

```cpp
#include <fstream>
std::ofstream f("out.txt");
f << "data: " << 42 << std::endl;
```

Truncates file by default. Use `std::ofstream f("file", std::ios::app)` to append.

**See also →** `std::ifstream`, `std::fstream`, `std::stringstream`]],

  ["fstream"] = [[
**`std::fstream`** · Input/output file stream (`<fstream>`)

```cpp
#include <fstream>
std::fstream f("file", std::ios::in | std::ios::out);
```

**See also →** `std::ifstream`, `std::ofstream`, `std::stringstream`]],

  ["stringstream"] = [[
**`std::stringstream`** · Input/output string stream (`<sstream>`)

```cpp
#include <sstream>
int id = 0;
std::string name;
std::string line = "42 Alice";
std::istringstream(line) >> id >> name;   // parse

std::ostringstream os;
os << "id=" << id;                         // format
std::string result = os.str();
```

Zero-cost for formatting/parsing (no heap syscalls like file I/O). Lifetime: `os.str()` returns a copy of the underlying string.

**See also →** `std::istringstream`, `std::ostringstream`, `std::from_chars`, `std::to_string`]],

  ["endl"] = [[
**`std::endl`** · Insert newline and flush stream (`<ostream>`)

```cpp
std::cout << "line 1" << std::endl;
std::cout << "line 2\n";        // same output, no flush
```

**Flushes the stream**, which can be expensive. Prefer `'\n'` for most output; use `std::endl` only when you need immediate visibility (logging, interactive prompts).

**See also →** `std::flush`, `std::ends`, `std::ws`]],

  ["flush"] = [[
**`std::flush`** · Flush the output buffer (`<ostream>`)

```cpp
std::cout << "processing..." << std::flush;
// ... long computation ...
std::cout << "done" << std::endl;
```

**See also →** `std::endl`, `std::ends`, `std::unitbuf`]],

  ["setw"] = [[
**`std::setw`** · Set field width for next formatted output (`<iomanip>`)

```cpp
#include <iomanip>
std::cout << std::setw(10) << 42;    // "        42"
std::cout << std::setw(10) << std::left << 42;  // "42        "
```

Applies only to the **next** formatted I/O operation (unlike most manipulators which are sticky).

**See also →** `std::setprecision`, `std::setfill`, `std::left`, `std::right`, `std::internal`]],

  ["setprecision"] = [[
**`std::setprecision`** · Set floating-point precision (`<iomanip>`)

```cpp
#include <iomanip>
std::cout << std::setprecision(3) << 3.14159;   // "3.14"
std::cout << std::fixed << std::setprecision(2) << 3.14159;  // "3.14"
```

**See also →** `std::setw`, `std::fixed`, `std::scientific`, `std::defaultfloat` (C++11)]],

  ["setfill"] = [[
**`std::setfill`** · Set fill character for formatted output (`<iomanip>`)

```cpp
std::cout << std::setfill('0') << std::setw(5) << 42;  // "00042"
```

Sticky — persists across operations.

**See also →** `std::setw`, `std::left`, `std::right`]],

  ["hex"] = [[
**`std::hex`** · Use hexadecimal base for integer I/O (`<ios>`)

```cpp
std::cout << std::hex << 255;          // "ff"
std::cout << std::showbase << 255;     // "0xff"
std::cout << std::uppercase << 255;    // "0XFF"
```

Sticky. Revert to decimal with `std::dec`.

**See also →** `std::dec`, `std::oct`, `std::showbase`, `std::uppercase`]],

  ["boolalpha"] = [[
**`std::boolalpha`** · Print bool as text (`<ios>`)

```cpp
std::cout << std::boolalpha << true;   // "true" (not "1")
std::cout << std::noboolalpha;          // revert to "1"/"0"
```

**See also →** `std::showbase`, `std::showpoint`, `std::showpos`]],

  ["getline"] = [[
**`std::getline`** · Read a line from stream into string (`<string>`)

```cpp
std::string line;
while (std::getline(std::cin, line)) {
    process(line);
}
```

Reads until delimiter (default `'\n'`), which is extracted but **not** stored. Returns the stream reference (usable in boolean context to check for errors/EOF).

```cpp
std::getline(std::cin, line, ',');    // custom delimiter
```

**See also →** `std::cin`, `std::ifstream`, `std::stringstream`, `std::ws`]],

  ["to_string"] = [[
**`std::to_string`** · Convert numeric value to string (`<string>`)

```cpp
std::string s = std::to_string(42);          // "42"
std::string s = std::to_string(3.14);        // "3.140000" (default formatting)
```

Uses `sprintf`-like formatting under the hood. May throw `std::bad_alloc`.

**See also →** `std::stoi`, `std::ostringstream`, `std::to_chars` (faster, C++17)]],

  ["stoi"] = [[
**`std::stoi`** · Parse string to integer (`<string>`)

```cpp
int n = std::stoi("42"s);          // 42
size_t pos;
int n = std::stoi("42xyz", &pos);  // 42, pos = 2
```

Throws `std::invalid_argument` if no conversion, `std::out_of_range` if overflow/underflow. Variants: `stol`, `stoll`, `stoul`, `stoull`, `stof`, `stod`, `stold`.

**See also →** `std::to_string`, `std::from_chars` (faster, no exceptions), `std::strtol`]],
}
