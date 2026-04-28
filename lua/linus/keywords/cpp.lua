-- linus/keywords/cpp.lua
-- C++ keywords. Inherits all C entries; adds/overrides C++-specific ones.

local c = require("linus.keywords.c")

local cpp = {

  -- ── Type system ─────────────────────────────────────────────────────────────

  ["class"] = [[
**`class`** · Class type declaration

```cpp
class Animal {
public:
    Animal(std::string name);           // constructor
    virtual ~Animal() = default;        // virtual destructor — always for base classes
    virtual std::string speak() = 0;    // pure virtual → Animal is abstract

protected:
    std::string name_;

private:
    int id_;
};

class Dog : public Animal {
public:
    std::string speak() override { return "Woof"; }
};
```

Default member access is **`private`** (vs `struct` which defaults to `public`).

**Access specifiers**
- `public` — accessible to all.
- `protected` — accessible to derived classes.
- `private` — accessible only within the class and friends.

**Inheritance access**
- `class Derived : public Base` — public members stay public.
- `class Derived : private Base` — all Base members become private.

**See also:** `virtual`, `override`, `final`, `struct`]],

  ["struct"] = [[
**`struct`** · Aggregate type (default-public class)

```cpp
struct Point { float x, y; };
Point p{1.0f, 2.0f};           // aggregate initialisation
auto [x, y] = p;               // structured bindings (C++17)

struct Config {
    int width  = 1280;          // default member initialisers (C++11)
    int height = 720;
    bool vsync = true;
};
Config cfg{};                   // all defaults
Config custom{.width = 1920};   // designated initialiser (C++20)
```

Identical to `class` except default member access is `public`.
Preferred for **plain data types / POD aggregates** where behaviour is minimal.

**Rule of Zero:** if a struct manages no resources, don't define any of the special member functions — the compiler generates correct ones automatically.]],

  ["auto"] = [[
**`auto`** · Type deduction

```cpp
auto x    = 42;                         // int
auto d    = 3.14;                        // double
auto& ref = vec[0];                      // reference; type = element type
auto it   = map.find("key");             // iterator type (verbose without auto)
const auto& cref = expensive_obj;        // const reference

// trailing return type
auto add(int a, int b) -> int { return a + b; }

// C++14: return type deduction
auto square(int x) { return x * x; }

// C++20: abbreviated function template
auto twice(auto x) { return x + x; }    // equivalent to template<typename T> T twice(T x)
```

**`decltype(auto)`** — deduces type preserving value category (ref/const):
```cpp
decltype(auto) get() { return member_; }  // returns T& if member_ is T&
```

**Avoid** `auto` when the type is non-obvious and clarity matters more than brevity.]],

  ["namespace"] = [[
**`namespace`** · Group names to avoid conflicts

```cpp
namespace mylib {
    void init();

    namespace detail {          // nested namespace
        void impl();
    }
}

// C++17 nested namespace shorthand:
namespace mylib::detail { void impl(); }

// Usage:
mylib::init();
mylib::detail::impl();

using namespace mylib;          // import all — avoid in headers
using mylib::init;              // import specific name — preferred
namespace ml = mylib;           // alias
```

**Unnamed namespace** — internal linkage (replacement for `static` at file scope in C++):
```cpp
namespace {
    void private_helper() { }   // not visible outside this translation unit
}
```]],

  ["template"] = [[
**`template`** · Parameterise a class, function, alias, or variable by type or value

```cpp
// Function template
template<typename T>
T max(T a, T b) { return a > b ? a : b; }

// Class template
template<typename T, int N>
struct Array {
    T data[N];
    int size() const { return N; }
};

// Alias template (C++11)
template<typename T>
using Vec = std::vector<T>;

// Variable template (C++14)
template<typename T>
constexpr T pi = T(3.14159265358979);

// Explicit specialisation
template<> int max<int>(int a, int b) { return a > b ? a : b; }

// Partial specialisation (class templates only)
template<typename T> struct Wrapper<T*> { /* pointer specialisation */ };
```

**Concepts (C++20)** — constrain template parameters:
```cpp
template<std::integral T>
T gcd(T a, T b) { return b == 0 ? a : gcd(b, a % b); }
```]],

  -- ── OOP ──────────────────────────────────────────────────────────────────

  ["virtual"] = [[
**`virtual`** · Enable runtime polymorphism

```cpp
struct Shape {
    virtual double area() const = 0;    // pure virtual → Shape is abstract
    virtual void draw() const { }       // overridable with default
    virtual ~Shape() = default;         // always virtual in polymorphic bases
};

struct Circle : Shape {
    double r;
    double area() const override { return 3.14159 * r * r; }
};

Shape *s = new Circle{5.0};
s->area();   // dispatches to Circle::area() at runtime via vtable
```

**vtable:** each class with virtual methods has a hidden table of function pointers.
Each object holds a vptr to its class's vtable — typically one pointer overhead.

**Rule:** if a class is meant to be used polymorphically, its destructor **must** be `virtual`
to ensure derived destructors are called through a base pointer.]],

  ["override"] = [[
**`override`** · Assert virtual method is being overridden (C++11)

```cpp
struct Base {
    virtual void draw(int x);
};

struct Derived : Base {
    void draw(int x) override;   // ✓ matches — compile error if signature drifts
    void draw(float x) override; // ✗ compile error — no such virtual in Base
};
```

Without `override`, a mismatched signature silently creates a **new** function rather than
overriding — a common and hard-to-find bug.

**Always use `override`** on intended overrides. Pair with `-Wsuggest-override` to enforce it.]],

  ["final"] = [[
**`final`** · Prevent further overriding or subclassing (C++11)

```cpp
// Prevent subclassing:
class Immutable final : public Base { };

// Prevent further overriding of a virtual method:
struct Derived : Base {
    void draw() override final;
};
```

`final` classes enable the compiler to devirtualise calls — a meaningful optimisation
in hot paths since vtable dispatch is replaced with a direct call.]],

  -- ── Memory ───────────────────────────────────────────────────────────────

  ["new"] = [[
**`new`** · Heap allocate and construct

```cpp
Foo *p   = new Foo(args);    // allocate + construct
Foo *arr = new Foo[n];       // array — default-constructs each element
delete p;                    // destruct + deallocate
delete[] arr;                // array delete — must match new[]

// Placement new — construct in pre-allocated memory:
alignas(Foo) char buf[sizeof(Foo)];
Foo *p2 = new(buf) Foo(args);
p2->~Foo();                  // must call destructor manually
```

**Prefer smart pointers** over raw `new`/`delete`:
```cpp
auto p = std::make_unique<Foo>(args);   // RAII — no manual delete
auto s = std::make_shared<Foo>(args);   // shared ownership
```

`new` throws `std::bad_alloc` on failure. Use `new(std::nothrow)` to return `nullptr` instead.]],

  ["delete"] = [[
**`delete`** · Destruct and deallocate heap object

```cpp
delete ptr;      // calls destructor, then deallocates
delete[] arr;    // array form — must match new[]
```

- `delete nullptr` is a **no-op** — safe to call unconditionally.
- **Double-delete** is undefined behaviour.
- Use `delete[]` for arrays and `delete` for single objects — mixing them is UB.
- Set pointer to `nullptr` after delete to make dangling pointer bugs detectable.

**Prefer `std::unique_ptr` / `std::shared_ptr`** to avoid manual delete entirely.]],

  -- ── Type safety ──────────────────────────────────────────────────────────

  ["nullptr"] = [[
**`nullptr`** · Type-safe null pointer constant (C++11)

```cpp
int *p  = nullptr;          // type: std::nullptr_t
void *v = nullptr;

// Avoids overload ambiguity present with NULL/0:
void f(int);
void f(char*);
f(NULL);     // ambiguous — which overload?
f(nullptr);  // unambiguous — calls f(char*)
```

Type: `std::nullptr_t`. Implicitly converts to any pointer or pointer-to-member type.
**Always prefer `nullptr` over `NULL` or `0` in C++.**]],

  ["explicit"] = [[
**`explicit`** · Prevent implicit conversions

```cpp
class Buf {
public:
    explicit Buf(int size);          // must use Buf{512}, not implicit Buf(512) conversions
    explicit operator bool() const;  // must use static_cast<bool>(buf) or !!buf
};

Buf b = 512;          // ✗ compile error — implicit conversion blocked
Buf b{512};           // ✓
if (b) { }           // ✓ contextual bool conversion still works
```

**Always use `explicit`** on single-argument constructors and conversion operators
unless implicit conversion is intentional (e.g. `std::string` from `const char*`).]],

  ["constexpr"] = [[
**`constexpr`** · Evaluated at compile time

```cpp
constexpr int square(int x) { return x * x; }
constexpr int N = square(8);          // 64 — compile-time constant

constexpr double PI = 3.14159265358979;

// constexpr if (C++17) — compile-time branch in templates:
template<typename T>
auto process(T val) {
    if constexpr (std::is_integral_v<T>)
        return val * 2;
    else
        return val + 0.5;
}
```

- `constexpr` functions can also run at runtime when given non-constant arguments.
- C++20: **`consteval`** — must always evaluate at compile time (no runtime fallback).
- C++20: **`constinit`** — guaranteed compile-time initialisation but runtime-mutable.

**Use `constexpr` over `#define` for typed, debuggable compile-time constants.**]],

  ["decltype"] = [[
**`decltype`** · Deduce type of an expression without evaluating it

```cpp
int x = 5;
decltype(x) y = 10;          // int
decltype(x + 0.5) z;         // double

// Most useful in templates:
template<typename A, typename B>
auto add(A a, B b) -> decltype(a + b) { return a + b; }

// decltype(auto) — preserves value category:
int& get_ref();
decltype(auto) r = get_ref();  // int& — reference preserved
auto           v = get_ref();  // int  — copy made
```]],

  ["static_assert"] = [[
**`static_assert`** · Compile-time assertion (C++11)

```cpp
static_assert(sizeof(int) == 4, "int must be 4 bytes on this platform");
static_assert(std::is_trivially_copyable_v<MyStruct>);  // C++17: message optional

// Common uses:
template<typename T>
void serialize(T val) {
    static_assert(std::is_trivially_copyable_v<T>,
                  "T must be trivially copyable to memcpy safely");
    // ...
}
```

Fails with a **compile error** (not a runtime failure) if condition is false.
Zero runtime overhead. The message string is shown in the compiler diagnostic.]],

  -- ── Semantics ────────────────────────────────────────────────────────────

  ["move"] = [[
**`std::move`** · Cast to rvalue reference to enable move semantics

```cpp
std::vector<int> a = {1, 2, 3};
std::vector<int> b = std::move(a);   // b takes a's buffer; a is now empty (valid but unspecified)

// Move constructor / move assignment:
class Resource {
    int *data_;
public:
    Resource(Resource&& other) noexcept
        : data_(std::exchange(other.data_, nullptr)) { }
};
```

`std::move` itself does nothing — it is a cast. The **move constructor or move assignment
operator** does the actual work of transferring ownership.

**Rule of Five (C++11):** if you define any of destructor, copy constructor, copy assignment,
move constructor, move assignment — define or delete all five.

**Prefer `std::move` for:**
- Transferring unique_ptr ownership.
- Returning local objects (though NRVO often handles this).
- Inserting into containers without copying.]],

  ["noexcept"] = [[
**`noexcept`** · Specify function does not throw

```cpp
void swap(T& a, T& b) noexcept {
    using std::swap;
    swap(a, b);
}

// Conditional noexcept:
template<typename T>
void move_insert(T val) noexcept(std::is_nothrow_move_constructible_v<T>);
```

**Why it matters:**
- `std::vector` uses move constructors only if they are `noexcept` — otherwise it copies for strong exception safety.
- Enables optimisations: the compiler can elide exception handling overhead.

**Mark `noexcept` on:** destructors (compilers do this implicitly), swap functions, move constructors, move assignment operators.]],

  -- ── Control and exceptions ────────────────────────────────────────────────

  ["try"] = [[
**`try`** · Exception handling

```cpp
try {
    auto result = riskyOperation();
    file.write(result);
} catch (const std::ios_base::failure& e) {
    std::cerr << "I/O error: " << e.what() << '\n';
} catch (const std::runtime_error& e) {
    std::cerr << "Runtime error: " << e.what() << '\n';
} catch (...) {
    std::cerr << "Unknown error\n";
    throw;   // rethrow
}
```

**RAII ensures cleanup during stack unwinding** — destructors run for all local objects
as the stack unwinds, so `try`/`catch` is only needed at recovery boundaries, not cleanup.

**Throw by value, catch by const reference:**
```cpp
throw std::runtime_error("reason");        // throw value
catch (const std::runtime_error& e) { }   // catch by const ref — avoids slicing
```]],

  ["using"] = [[
**`using`** · Type alias, namespace import, or base member promotion

```cpp
// Type alias (C++11) — preferred over typedef:
using Bytes    = std::vector<uint8_t>;
using Callback = std::function<void(int)>;

// Template alias:
template<typename T>
using Map = std::unordered_map<std::string, T>;

// Namespace import (avoid in headers):
using namespace std;
using std::string;    // import specific — less polluting

// Bring base class member into derived scope:
class Derived : public Base {
    using Base::hidden_method;   // make public
};
```]],

  ["enum"] = [[
**`enum class`** · Scoped, strongly-typed enumeration (C++11)

```cpp
enum class Color { Red, Green, Blue };
Color c = Color::Red;    // must qualify — no accidental int conversion

// Specify underlying type:
enum class Flags : uint8_t {
    None  = 0,
    Read  = 1 << 0,
    Write = 1 << 1,
    Exec  = 1 << 2,
};

// Bitwise ops require explicit cast (by design — prevents accidents):
Flags f = static_cast<Flags>(static_cast<uint8_t>(Flags::Read)
                             | static_cast<uint8_t>(Flags::Write));
```

**Prefer `enum class` over plain `enum`:**
- Scoped names (`Color::Red` not just `Red`).
- No implicit conversion to `int`.
- Can forward-declare with underlying type: `enum class Color : int;`.

**Plain `enum`** (C-compatible) still available but should be confined to C-interop code.]],

  -- ── Lambda ───────────────────────────────────────────────────────────────

  ["lambda"] = [[
**Lambda expression** · Anonymous function object (C++11)

```cpp
// Basic syntax:
auto fn = [capture](params) -> RetType { body; };

// Capture modes:
[=]           // capture all locals by value (copy)
[&]           // capture all locals by reference
[x, &y]       // x by value, y by reference
[this]        // capture this pointer (member access)
[*this]       // capture *this by value (C++17)
[=, &y]       // all by value except y by reference

// Examples:
auto sq  = [](int x) { return x * x; };
auto sum = [total = 0](int x) mutable { total += x; return total; };

std::sort(v.begin(), v.end(), [](const auto& a, const auto& b) {
    return a.key < b.key;
});

// Immediately invoked:
int result = [&]{ return computeExpensive(); }();
```

Lambdas generate a unique anonymous functor class. Each capture adds a data member.
`mutable` allows modification of by-value captures.]],
}

-- Merge C entries underneath (C++ overrides take precedence for shared keywords)
return vim.tbl_extend("keep", cpp, c)
