-- linus/keywords/cpp/utilities.lua
-- Utility types: optional, variant, any, expected, pair, tuple, bitset.

return {

  ["optional"] = [[
**`std::optional`** · Value that may or may not be present (`<optional>`, C++17)

```cpp
#include <optional>
std::optional<int> might_fail(bool ok) {
    if (ok) return 42;
    return std::nullopt;   // or return {};
}

auto val = might_fail(true);
if (val) {                         // check for value
    use(*val);                     // dereference (undefined if val is empty)
    use(val.value());              // throws std::bad_optional_access if empty
    use(val.value_or(0));          // default value if empty
}
```

No heap allocation. Size overhead: at least one bool + alignment padding.

**See also →** `std::variant`, `std::any`, `std::expected` (C++23), `std::nullopt_t`]],

  ["nullopt"] = [[
**`std::nullopt`** · Disengaged state indicator for optional (`<optional>`, C++17)

```cpp
std::optional<int> o = std::nullopt;  // empty optional
```

Type: `std::nullopt_t`. Also used to reset an optional: `o = std::nullopt`.

**See also →** `std::optional`]],

  ["variant"] = [[
**`std::variant`** · Type-safe union (`<variant>`, C++17)

```cpp
#include <variant>
std::variant<int, float, std::string> v = 42;

v = 3.14f;                         // now holds float
v = "hello"s;                      // now holds string

std::get<int>(v);                  // access — throws std::bad_variant_access if wrong type
std::get_if<int>(&v);              // pointer or nullptr — safe check
std::holds_alternative<int>(v);    // check current type

std::visit([](auto&& val) {        // dispatch by current type
    std::cout << val;
}, v);
```

Never empty — always holds one of the alternative types (unless `valueless_by_exception`).

**See also →** `std::optional`, `std::any`, `std::visit`, `std::monostate`]],

  ["any"] = [[
**`std::any`** · Type-safe container for any value (`<any>`, C++17)

```cpp
#include <any>
std::any a = 42;
a = std::string("hello");

std::any_cast<int>(a);             // throws std::bad_any_cast if wrong type
auto* p = std::any_cast<int>(&a);  // nullptr if wrong type
a.has_value();                     // false if empty
a.reset();                         // make empty
```

Requires the contained type to be copy-constructible. Heap-allocates for non-trivial types.

**See also →** `std::variant` (preferred when type set is known), `std::optional`, `std::bad_any_cast`]],

  ["expected"] = [[
**`std::expected`** · Value or error (`<expected>`, C++23)

```cpp
#include <expected>
std::expected<int, std::string> parse(const std::string& s) {
    if (s.empty()) return std::unexpected("empty string");
    return 42;
}

auto r = parse("hello");
if (r) { use(*r); }               // access value
else { log(r.error()); }          // access error
```

Similar to Rust's `Result<T, E>`. `std::unexpected` constructs the error side. No exception overhead.

**See also →** `std::optional`, `std::variant`, `std::error_code`]],

  ["pair"] = [[
**`std::pair`** · Two heterogeneous values (`<utility>`)

```cpp
std::pair<int, std::string> p = {1, "hello"};
p.first;   // 1
p.second;  // "hello"

// C++17 structured bindings:
auto [id, name] = p;
```

Used extensively throughout the STL (map elements, algorithm returns). Since C++11, `std::tuple` is preferred for 3+ elements.

**See also →** `std::tuple`, `std::make_pair`, `std::piecewise_construct`]],

  ["tuple"] = [[
**`std::tuple`** · Fixed-size collection of heterogeneous values (`<tuple>`, C++11)

```cpp
std::tuple<int, float, std::string> t = {1, 2.5f, "hello"};

std::get<0>(t);             // 1 (by index)
std::get<int>(t);           // by type (must be unique)

// C++17 structured bindings:
auto [i, f, s] = t;

// Concatenate:
auto t2 = std::tuple_cat(t, std::tuple{4, 5.0});
```

**See also →** `std::pair`, `std::tie`, `std::apply` (C++17), `std::make_tuple`]],

  ["bitset"] = [[
**`std::bitset`** · Fixed-size sequence of bits (`<bitset>`)

```cpp
#include <bitset>
std::bitset<8> b = 0b10100101;

b[0];               // access LSB
b.set(2);           // set bit 2 to true
b.reset(2);         // set bit 2 to false
b.flip();           // toggle all bits
b.count();          // number of 1 bits
b.test(3);          // bounds-checked access

std::bitset<8> b2("10100101");   // from string
```

Size is a compile-time constant. For runtime-sized bit sets, use `std::vector<bool>` (but beware: it's not a real container).

**See also →** `std::vector<bool>`, `std::popcount` (C++20), `std::rotr`/`std::rotl`]],

  ["function"] = [[
**`std::function`** · Type-erased callable wrapper (`<functional>`)

```cpp
#include <functional>
std::function<int(int, int)> fn;

fn = std::plus<int>{};        // function object
fn = [](int a, int b) { return a + b; };  // lambda
fn = &some_function;           // function pointer

int result = fn(3, 4);         // invoke
```

May allocate on the heap. Invocation overhead: two indirect calls (vtable + target). If no callable is stored, invoking throws `std::bad_function_call`.

**Prefer `auto`** for lambdas and templates. Use `std::function` only for type-erased storage (maps of callbacks, etc.).

**See also →** `std::bind`, `std::invoke` (C++17), `std::move_only_function` (C++23), `std::copyable_function` (C++26)]],

  ["bind"] = [[
**`std::bind`** · Bind arguments to a callable (`<functional>`)

```cpp
auto add5 = std::bind(std::plus<int>{}, 5, std::placeholders::_1);
add5(3);  // 8
```

**Deprecated in favor of lambdas** in most cases:
```cpp
auto add5 = [](int x) { return 5 + x; };  // clearer, faster
```

**See also →** `std::function`, `std::placeholders`, `std::invoke`, `std::mem_fn`]],

  ["hash"] = [[
**`std::hash`** · Hash function objects (`<functional>`)

```cpp
std::hash<int> h;
size_t hash_val = h(42);          // hash of 42

// Used by std::unordered_map, std::unordered_set by default
std::unordered_map<int, std::string> m;
```

Specialized for all built-in types, pointers, `std::string`, `std::optional`, `std::variant`, `std::unique_ptr`, `std::shared_ptr` (C++11 and later). Custom types require specialization.

**See also →** `std::equal_to`, `std::unordered_map`, `std::hash_combine` (Boost)]],

  ["from_chars"] = [[
**`std::from_chars`** · Fast, locale-independent string to number conversion (`<charconv>`, C++17)

```cpp
#include <charconv>
int val;
auto [ptr, ec] = std::from_chars(s.data(), s.data() + s.size(), val);
if (ec == std::errc{}) { /* success */ }
else if (ec == std::errc::invalid_argument) { /* no digits */ }
else if (ec == std::errc::result_out_of_range) { /* overflow */ }
```

**Exception-free**, allocation-free, locale-independent. The fastest string-to-number conversion in C++.

**See also →** `std::to_chars`, `std::stoi`, `std::strtol`, `std::from_chars_result`]],
}
