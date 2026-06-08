-- linus/keywords/cpp/regex.lua
-- Regular expressions library (<regex>).

return {

  ["regex"] = [[
**`std::regex`** · Regular expression object (`<regex>`)

```cpp
#include <regex>
std::regex re(R"(\d+)", std::regex::ECMAScript);  // ECMAScript syntax (default)
std::regex re_basic(R"(\\d\\+)", std::regex::basic);  // POSIX basic
```

Grammar options: `ECMAScript` (default), `basic`, `extended`, `awk`, `grep`, `egrep`.
Syntax checked at construction — throws `std::regex_error` if invalid.

**Performance note:** constructing a `std::regex` is expensive (compiles the pattern). Reuse if possible.

**See also →** `std::regex_match`, `std::regex_search`, `std::regex_replace`, `std::smatch`]],

  ["regex_match"] = [[
**`std::regex_match`** · Match entire string against regex (`<regex>`)

```cpp
std::regex re(R"(\\d{3}-\\d{4})");
std::string s = "555-1234";

bool ok = std::regex_match(s, re);   // true — whole string matches

std::smatch m;
if (std::regex_match(s, m, re)) {    // with captures
    std::string match = m[0];        // full match
}
```

**Must** match the **entire** input string. Use `regex_search` for partial matches.

**See also →** `std::regex_search`, `std::regex_replace`, `std::smatch`, `std::regex_iterator`]],

  ["regex_search"] = [[
**`std::regex_search`** · Find first match of pattern (`<regex>`)

```cpp
std::regex re(R"(\\d+)");
std::string s = "abc 123 def 456";

std::smatch m;
if (std::regex_search(s, m, re)) {       // true, finds "123"
    std::string first_match = m.str();    // "123"
    size_t pos = m.position();            // 4
}
```

Returns the **first** occurrence. Use `std::regex_iterator` to find all occurrences.

**See also →** `std::regex_match`, `std::regex_replace`, `std::regex_iterator`, `std::smatch`]],

  ["regex_replace"] = [[
**`std::regex_replace`** · Replace regex matches (`<regex>`)

```cpp
std::regex re(R"(\\b(\\w+)\\b)");       // words
std::string s = "hello world";
std::string result = std::regex_replace(s, re, "'$1'");
// "'hello' 'world'"
```

Flags: `std::regex_constants::format_first_only` (replace first only), `format_no_copy` (omit unmatched segments).

**See also →** `std::regex_match`, `std::regex_search`, `std::regex_constants::format_type`]],

  ["smatch"] = [[
**`std::smatch`** · String match results (`<regex>`)

```cpp
std::smatch m;
std::regex_search("hello 42 world", m, std::regex(R"(\\d+)"));

m[0];          // full match: "42"
m.str();       // same
m.position();  // byte offset
m.length();    // match length
m.prefix();    // string before match: "hello "
m.suffix();    // string after match: " world"

// Groups:
std::regex_search("2024-01-15", m, std::regex(R"((\\d{4})-(\\d{2}))"));
m[1];   // "2024"
m[2];   // "01"
```

`s = std::string`; alias: `std::cmatch` for `const char*`. `m.ready()` returns true after successful search.

**See also →** `std::regex`, `std::regex_search`, `std::sub_match`, `std::regex_iterator`]],

  ["regex_iterator"] = [[
**`std::regex_iterator`** · Iterate all regex matches (`<regex>`)

```cpp
std::regex re(R"(\\w+)");
std::string s = "foo bar baz";

auto begin = std::sregex_iterator(s.begin(), s.end(), re);
auto end = std::sregex_iterator();

for (auto it = begin; it != end; ++it) {
    std::smatch match = *it;
    // match[0] = "foo", then "bar", then "baz"
}
```

`std::sregex_iterator` = `std::regex_iterator<std::string::const_iterator>`. Dereferencing yields a `std::smatch`.

**See also →** `std::regex_token_iterator`, `std::regex`, `std::smatch`]],

  ["regex_token_iterator"] = [[
**`std::regex_token_iterator`** · Iterate sub-matches or split fields (`<regex>`)

```cpp
std::regex re(R"(\s+)");
std::string s = "split this string";

// Split by delimiter:
auto begin = std::sregex_token_iterator(s.begin(), s.end(), re, -1);  // -1 = non-matches
auto end = std::sregex_token_iterator();

std::vector<std::string> words(begin, end);
// words = {"split", "this", "string"}

// Extract capture groups:
std::regex re2(R"((\\d+)-(\\d+))");
auto it = std::sregex_token_iterator("1-2 3-4", re2, 1);  // group 1
```

The fourth argument: `-1` = unmatched fragments, `0` = full matches, `N` = capture group N.

**See also →** `std::regex_iterator`, `std::regex`, `std::smatch`]],

  ["regex_error"] = [[
**`std::regex_error`** · Regex compilation error (`<regex>`)

```cpp
try {
    std::regex re("[invalid");
} catch (const std::regex_error& e) {
    e.code();   // std::regex_constants::error_type enum
    e.what();   // descriptive string
}
```

Error codes: `error_brack`, `error_paren`, `error_brace`, `error_badrepeat`, `error_complexity`, `error_stack`, and more.

**See also →** `std::regex_constants::error_type`, `std::regex`]],
}
