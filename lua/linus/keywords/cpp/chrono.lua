-- linus/keywords/cpp/chrono.lua
-- Time library: durations, time points, clocks.

return {

  ["duration"] = [[
**`std::chrono::duration`** · A span of time (`<chrono>`)

```cpp
#include <chrono>
using namespace std::chrono_literals;

auto d = 42s;                  // 42 seconds (C++14)
auto ms = 500ms;               // 500 milliseconds
auto us = 100us;               // 100 microseconds

std::chrono::hours h(1);
std::chrono::minutes m(30);
std::chrono::seconds s = h + m;

// Casting:
auto secs = std::chrono::duration_cast<std::chrono::seconds>(ms);
int64_t count = secs.count();  // raw tick count
```

Template: `duration<Rep, Period>` where `Period` = e.g. `std::ratio<1, 1000>` for milliseconds. Truncates toward zero when cast.

**See also →** `std::chrono::time_point`, `std::chrono::duration_cast`, `std::chrono::system_clock`, `chrono_literals`]],

  ["time_point"] = [[
**`std::chrono::time_point`** · A point in time (`<chrono>`)

```cpp
#include <chrono>
auto tp = std::chrono::system_clock::now();

auto tp2 = tp + 1h;                     // add duration
auto diff = tp2 - tp;                   // nanoseconds (for system_clock)
auto ms = std::chrono::time_point_cast<std::chrono::milliseconds>(tp);

// Time since epoch:
auto epoch = tp.time_since_epoch();
```

**See also →** `std::chrono::duration`, `std::chrono::system_clock`, `std::chrono::steady_clock`, `std::chrono::high_resolution_clock`]],

  ["system_clock"] = [[
**`std::chrono::system_clock`** · Wall clock time (`<chrono>`)

```cpp
auto now = std::chrono::system_clock::now();

// Convert to C time:
std::time_t tt = std::chrono::system_clock::to_time_t(now);
std::cout << std::ctime(&tt);

// Convert from C time:
auto tp = std::chrono::system_clock::from_time_t(tt);
```

**Not monotonic** — may be adjusted (NTP, DST). Represents wall-clock / system-wide time.

**See also →** `std::chrono::steady_clock`, `std::chrono::high_resolution_clock`]],

  ["steady_clock"] = [[
**`std::chrono::steady_clock`** · Monotonic clock, never adjusted (`<chrono>`)

```cpp
auto start = std::chrono::steady_clock::now();
work();
auto end = std::chrono::steady_clock::now();
auto elapsed = end - start;   // always positive
```

**Monotonic** — physically advances at a steady rate. Use for measuring intervals (performance benchmarks, timeouts). Cannot be converted to calendar time.

**See also →** `std::chrono::system_clock`, `std::chrono::high_resolution_clock`, `std::chrono::duration_cast`]],

  ["high_resolution_clock"] = [[
**`std::chrono::high_resolution_clock`** · Clock with shortest tick period (`<chrono>`)

```cpp
auto start = std::chrono::high_resolution_clock::now();
```

Typically an alias for `std::chrono::steady_clock` or `std::chrono::system_clock` (implementation-defined). Usually not needed — use `steady_clock` for measurements.

**See also →** `std::chrono::steady_clock`, `std::chrono::system_clock`]],

  ["duration_cast"] = [[
**`std::chrono::duration_cast`** · Convert between durations (`<chrono>`)

```cpp
auto ms = std::chrono::milliseconds(2500);
auto s = std::chrono::duration_cast<std::chrono::seconds>(ms);  // 2s (truncates)

auto us = std::chrono::duration_cast<std::chrono::microseconds>(ms);  // 2500000us
```

Truncates toward zero (like integer division). For rounding, use `std::chrono::round` (C++17), `std::chrono::floor` (C++17), or `std::chrono::ceil` (C++17).

**See also →** `std::chrono::duration`, `std::chrono::time_point_cast`, `std::chrono::round` (C++17)]],

  ["time_point_cast"] = [[
**`std::chrono::time_point_cast`** · Convert time_point to a different tick duration (`<chrono>`)

```cpp
auto tp = std::chrono::system_clock::now();
auto tp_ms = std::chrono::time_point_cast<std::chrono::milliseconds>(tp);
```

Truncates. For rounding variants, see `std::chrono::round` (C++17), `std::chrono::floor` (C++17), `std::chrono::ceil` (C++17).

**See also →** `std::chrono::duration_cast`, `std::chrono::time_point`]],

  ["chrono_literals"] = [[
**`chrono_literals`** · User-defined literals for durations (`<chrono>`, C++14)

```cpp
using namespace std::chrono_literals;

auto d1 = 5h;     // hours
auto d2 = 30min;  // minutes
auto d3 = 10s;    // seconds
auto d4 = 250ms;  // milliseconds
auto d5 = 50us;   // microseconds
auto d6 = 10ns;   // nanoseconds
```

These are `std::chrono::duration` values. Use with `std::this_thread::sleep_for`, `std::chrono::steady_clock`, etc.

**See also →** `std::chrono::duration`, `std::this_thread::sleep_for`, `std::literals`]],

  ["year_month_day"] = [[
**`std::chrono::year_month_day`** · Calendar date (`<chrono>`, C++20)

```cpp
#include <chrono>
using namespace std::chrono;

auto date = 2024y / January / 15;
auto date2 = year_month_day{2024y, month{1}, day{15}};

// Extract:
int y = int(date.year());
unsigned m = unsigned(date.month());
unsigned d = unsigned(date.day());

// Field violence: this is a valid date — ok if ok()
bool valid = date.ok();   // checks for valid date (leap years handled)
```

**See also →** `std::chrono::year`, `std::chrono::month`, `std::chrono::day`, `std::chrono::weekday`]],

  ["year"] = [[
**`std::chrono::year`** · Year in the Gregorian calendar (`<chrono>`, C++20)

```cpp
auto y = 2024y;
int i = int(y);           // 2024
bool leap = y.is_leap();  // true for 2024
```

**See also →** `std::chrono::year_month_day`, `std::chrono::month`, `std::chrono::day`]],

  ["month"] = [[
**`std::chrono::month`** · Month of the year (`<chrono>`, C++20)

```cpp
auto m = January;
```

Named constants: `January`, `February`, ..., `December`. Range: [1, 12]. `m.ok()` checks validity.

**See also →** `std::chrono::year_month_day`, `std::chrono::year`]],

  ["weekday"] = [[
**`std::chrono::weekday`** · Day of the week (`<chrono>`, C++20)

```cpp
auto wd = Friday;
unsigned idx = wd.c_encoding();  // 0 = Sunday ... 6 = Saturday
unsigned iso  = wd.iso_encoding();  // 1 = Monday ... 7 = Sunday
```

Named constants: `Sunday`, `Monday`, ..., `Saturday`.

**See also →** `std::chrono::year_month_weekday`, `std::chrono::weekday_indexed`]],

  ["sys_time"] = [[
**`std::chrono::sys_time`** · Time point in system clock (`<chrono>`, C++20)

```cpp
std::chrono::sys_seconds tp = std::chrono::floor<std::chrono::seconds>(
    std::chrono::system_clock::now()
);
```

`sys_time<Duration>` is an alias for `time_point<system_clock, Duration>`. Since C++20, it has streaming operators: `std::cout << tp;`.

**See also →** `std::chrono::system_clock`, `std::chrono::time_point`, `std::chrono::zoned_time`]],
}
