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

  -- ── Types ────────────────────────────────────────────────────────────────

  ["bool"] = [[
**`bool`** · Boolean type (C++, not C)

| Property | Value |
|----------|-------|
| Values | `true` (1), `false` (0) |
| Size | Implementation-defined (typically 1 byte) |
| Implicit conversions | Integer ↔ bool (0 = false, non-zero = true) |

```cpp
bool flag  = true;
bool empty = (size == 0);

// Arithmetic context — bool promotes to int:
int n = true + true;   // 2

// Pointer in condition:
if (ptr) { }           // equivalent to ptr != nullptr
```

Unlike C's pre-C99 convention of using `int` for booleans, C++ `bool` is a true keyword.
`sizeof(bool)` is at least 1; it is **not** guaranteed to be 1.

**See also** → `true`, `false`, `nullptr`]],

  ["wchar_t"] = [[
**`wchar_t`** · Wide character type

| Property | Value |
|----------|-------|
| Size | Implementation-defined (2 bytes on Windows/MSVC, 4 bytes on Linux/GCC) |
| Encoding | UTF-16 on Windows, UTF-32 on Linux |
| Literal | `L'A'`, wide string `L"hello"` |

```cpp
wchar_t ch = L'A';
const wchar_t *ws = L"Hello, World";
std::wstring s = L"wide string";
```

**Portability warning** — the size difference between platforms makes `wchar_t` awkward for portable code.
Prefer `char8_t` / `char16_t` / `char32_t` (C++11) or `std::u8string` / `std::u16string` / `std::u32string` for portable Unicode.

**See also** → `char`, `char8_t`, `char16_t`, `char32_t`]],

  -- ── Access specifiers ────────────────────────────────────────────────────

  ["public"] = [[
**`public`** · Access specifier — widest visibility

```cpp
class MyClass {
public:
    int value;              // accessible from anywhere
    void doWork();          // public method

    MyClass();              // public constructor
};

// Public inheritance — public/protected members retain their access:
class Derived : public Base { };
```

**Key facts**
- `struct` members are `public` by default; `class` members are `private` by default
- Use `public:` to begin a public section — applies to all following members until the next specifier
- Public inheritance models IS-A; private/protected inheritance models implementation-in-terms-of

**See also** → `private`, `protected`, `class`, `struct`]],

  ["private"] = [[
**`private`** · Access specifier — narrowest visibility

```cpp
class BankAccount {
private:
    double balance_;         // hidden from outside
    int    account_id_;

public:
    void deposit(double amt) { if (amt > 0) balance_ += amt; }
    double balance() const   { return balance_; }
};
```

**Key facts**
- `class` members are `private` by default (omitting the specifier)
- Private members are inaccessible from subclasses and external code
- `friend` functions/classes can access private members
- Private members ARE inherited — they just aren't accessible by name in derived classes

**Private inheritance**:
```cpp
class Stack : private std::vector<int> { /* ... */ };
// Hides vector's public API from Stack users
```

**See also** → `public`, `protected`, `friend`]],

  ["protected"] = [[
**`protected`** · Access specifier — visible to derived classes

```cpp
class Animal {
protected:
    std::string name_;        // subclasses can read/write
    virtual void breathe();   // subclasses can call and override

public:
    explicit Animal(std::string name) : name_(std::move(name)) {}
};

class Dog : public Animal {
public:
    void bark() {
        breathe();            // fine — inherited protected access
        name_ = "Rex";        // fine
    }
};
```

**Key facts**
- Accessible from within the class and from derived classes
- Not accessible from unrelated external code
- `protected` data members couple base and derived classes tightly — prefer `protected` methods that expose controlled access to `private` data

**See also** → `public`, `private`, `virtual`]],

  -- ── OOP and type system ───────────────────────────────────────────────────

  ["this"] = [[
**`this`** · Pointer to the current object instance

```cpp
class Point {
    int x_, y_;
public:
    Point& setX(int x) { x_ = x; return *this; }   // enable chaining
    Point& setY(int y) { y_ = y; return *this; }

    bool operator==(const Point& other) const {
        return this == &other;          // identity check
    }

    Point* self() { return this; }     // explicit self-pointer
};

// Method chaining (fluent interface):
p.setX(3).setY(4);
```

**Key facts**
- `this` is a prvalue of type `T* const` (const pointer to current object) in non-const methods
- In a `const` method, `this` has type `const T* const`
- `this` is not available in static member functions
- `[this]` in a lambda captures the enclosing object's `this` pointer; `[*this]` (C++17) captures by value

**See also** → `class`, `static`, `friend`]],

  ["friend"] = [[
**`friend`** · Grant non-member access to private/protected members

```cpp
class Vector {
    double x_, y_;
    friend double dot(const Vector& a, const Vector& b);    // function friend
    friend class Matrix;                                     // class friend
};

double dot(const Vector& a, const Vector& b) {
    return a.x_ * b.x_ + a.y_ * b.y_;   // accesses private x_, y_
}

// Common: friend operator<< for stream output:
class Foo {
    int value_;
    friend std::ostream& operator<<(std::ostream& os, const Foo& f) {
        return os << f.value_;
    }
};
```

**Key facts**
- Friendship is not inherited — a friend of a base class is not a friend of derived classes
- Friendship is not transitive — a friend's friends are not automatically friends
- Use sparingly; it breaks encapsulation and creates tight coupling

**See also** → `private`, `class`, `operator`]],

  ["mutable"] = [[
**`mutable`** · Allow modification of a member in a `const` method

```cpp
class Cache {
    mutable std::unordered_map<int, Result> cache_;   // can be modified in const methods
    mutable std::mutex mutex_;                         // frequently mutable

public:
    Result get(int key) const {    // logically const — doesn't change observable state
        std::lock_guard lock{mutex_};
        if (auto it = cache_.find(key); it != cache_.end())
            return it->second;
        auto result = compute(key);
        cache_[key] = result;
        return result;
    }
};
```

**Also for lambda captures** — allow modification of by-value captured variables:
```cpp
auto counter = [n = 0]() mutable { return ++n; };
counter();   // 1
counter();   // 2
```

**Key facts**
- Signals "logically const but physically mutable" — used for caches, lazy init, mutexes
- `mutable` on a lambda makes all captured-by-value variables modifiable
- Overuse of `mutable` defeats the purpose of `const` correctness

**See also** → `const`, `volatile`, `lambda`]],

  -- ── Exception handling ────────────────────────────────────────────────────

  ["throw"] = [[
**`throw`** · Raise an exception

```cpp
// Throw by value:
throw std::runtime_error("something went wrong");
throw std::invalid_argument("value must be positive: " + std::to_string(n));

// Rethrow inside a catch:
catch (const std::exception& e) {
    log(e.what());
    throw;   // rethrow — preserves the original exception object and type
}

// Exception specification (C++11):
void safe() noexcept;            // guarantees no exception
void risky() noexcept(false);    // may throw (the default)
```

**Good practice**
- Throw by value (`throw MyError{...}`), catch by const reference (`catch (const MyError& e)`)
- Include context: `"expected > 0, got: " + std::to_string(n)`
- Use `std::nested_exception` / `std::throw_with_nested` to chain exceptions

**Common standard exceptions**
- `std::invalid_argument` — bad function argument
- `std::out_of_range` — index or value out of valid range
- `std::runtime_error` — detectable only at runtime
- `std::logic_error` — bug in the program (precondition violated)
- `std::bad_alloc` — allocation failure

**See also** → `try`, `catch`, `noexcept`, `terminate`]],

  ["catch"] = [[
**`catch`** · Handle an exception thrown in a `try` block

```cpp
try {
    auto result = riskyOperation();
    file.write(result);
} catch (const std::ios_base::failure& e) {
    std::cerr << "I/O error: " << e.what() << '\n';
} catch (const std::runtime_error& e) {
    std::cerr << "Runtime: " << e.what() << '\n';
} catch (const std::exception& e) {
    std::cerr << "Exception: " << e.what() << '\n';
} catch (...) {
    std::cerr << "Unknown exception\n";
    throw;   // rethrow unknown exceptions
}
```

**Key facts**
- Handlers are tried in declaration order — place derived types before base types
- `catch (...)` catches everything including non-`std::exception` types; rethrow with bare `throw;`
- Catching by const reference avoids slicing and copying
- RAII ensures destructors run during stack unwinding — `try`/`catch` is for recovery, not cleanup

**Exception hierarchy**
```
std::exception
├─ std::logic_error     (invalid_argument, out_of_range, ...)
└─ std::runtime_error   (range_error, overflow_error, ...)
std::bad_alloc, std::bad_cast, std::bad_typeid (separate hierarchy)
```

**See also** → `try`, `throw`, `noexcept`]],

  -- ── Operator overloading ─────────────────────────────────────────────────

  ["operator"] = [[
**`operator`** · Define the meaning of an operator for a user-defined type

```cpp
struct Vec2 {
    float x, y;

    Vec2 operator+(const Vec2& rhs) const { return {x+rhs.x, y+rhs.y}; }
    Vec2& operator+=(const Vec2& rhs) { x += rhs.x; y += rhs.y; return *this; }
    bool operator==(const Vec2&) const = default;   // C++20: auto-generated

    // Subscript (C++23 allows multi-dimensional []):
    float& operator[](int i) { return i == 0 ? x : y; }

    // Conversion operator:
    explicit operator bool() const { return x != 0 || y != 0; }
};

// Stream output (non-member friend):
friend std::ostream& operator<<(std::ostream& os, const Vec2& v) {
    return os << "(" << v.x << ", " << v.y << ")";
}
```

**Overloadable operators** (selection)
- Arithmetic: `+`, `-`, `*`, `/`, `%`, `++`, `--`
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`, `<=>` (C++20 spaceship)
- Logical: `!`, `&&`, `||`
- Bit: `&`, `|`, `^`, `~`, `<<`, `>>`
- Assignment: `=`, `+=`, `-=`, …
- Access: `->`, `*`, `[]`, `()`
- Allocation: `new`, `delete`, `new[]`, `delete[]`

**Guidelines**
- Prefer member functions for operators that need `this` (assignment, subscript)
- Prefer non-member functions for symmetric binary operators (`+`, `==`) to allow implicit conversion on both sides
- If you define `==`, define `!=`; use `= default` for trivial cases (C++20)

**See also** → `friend`, `explicit`, `constexpr`]],

  -- ── Casts ────────────────────────────────────────────────────────────────

  ["static_cast"] = [[
**`static_cast`** · Compile-time checked type conversion

```cpp
double d = 3.7;
int i = static_cast<int>(d);          // 3 — truncation, not rounding

// Upcast (always safe):
Derived* dp = new Derived;
Base* bp = static_cast<Base*>(dp);    // implicit — cast not needed

// Downcast (unsafe without runtime check — use dynamic_cast for polymorphic types):
Derived* dp2 = static_cast<Derived*>(bp);

// Void pointer:
void* vp = malloc(sizeof(int));
int* ip   = static_cast<int*>(vp);

// Enum conversions:
int n = static_cast<int>(MyEnum::Value);
```

**Use when**
- You know the conversion is safe and want the compiler to verify it's at least meaningful
- Converting numeric types (float↔int, int↔enum)
- Upcasting within a class hierarchy

**Do NOT use for** — removing `const` (use `const_cast`), arbitrary bit reinterpretation (use `reinterpret_cast`).

**See also** → `dynamic_cast`, `const_cast`, `reinterpret_cast`]],

  ["dynamic_cast"] = [[
**`dynamic_cast`** · Runtime-checked downcast for polymorphic types

```cpp
// Returns nullptr on failure (pointer form):
Base* bp = getBase();
if (Derived* dp = dynamic_cast<Derived*>(bp)) {
    dp->derivedMethod();   // safe
}

// Throws std::bad_cast on failure (reference form):
try {
    Derived& dr = dynamic_cast<Derived&>(*bp);
} catch (const std::bad_cast& e) { }
```

**Key facts**
- Requires at least one `virtual` function in the base class (enables RTTI)
- Has runtime cost — traverses the inheritance hierarchy
- Use `static_cast` instead when you know the type statically; use `dynamic_cast` only when uncertain
- Enabling/disabling RTTI: `-fno-rtti` (GCC/Clang) disables `dynamic_cast` and `typeid`

**See also** → `static_cast`, `typeid`, `virtual`]],

  ["const_cast"] = [[
**`const_cast`** · Add or remove `const`/`volatile` qualifier

```cpp
void legacyAPI(char* s);   // old C API: non-const parameter

const char* msg = "hello";
legacyAPI(const_cast<char*>(msg));   // OK only if legacyAPI doesn't write

// Adding const (rarely needed — implicit):
int x = 5;
const int& cr = const_cast<const int&>(x);
```

**Warning** — writing through a pointer that was originally `const` is **undefined behaviour**:
```cpp
const int ci = 42;
int* p = const_cast<int*>(&ci);
*p = 99;   // UB — even if it "works" on some platforms
```

Use `const_cast` only when interfacing with legacy APIs that lack proper const-correctness — not as a workaround for const design mistakes.

**See also** → `const`, `static_cast`, `mutable`]],

  ["reinterpret_cast"] = [[
**`reinterpret_cast`** · Low-level bit-pattern reinterpretation

```cpp
// Pointer ↔ integer:
uintptr_t addr = reinterpret_cast<uintptr_t>(ptr);
int* p2        = reinterpret_cast<int*>(addr);

// Type punning (prefer std::bit_cast in C++20):
float f = 1.0f;
uint32_t bits = *reinterpret_cast<uint32_t*>(&f);   // violates strict aliasing

// Hardware register access:
volatile uint32_t* reg = reinterpret_cast<volatile uint32_t*>(0x40000000UL);
```

**Key facts**
- No runtime cost — it is purely a compile-time directive to reinterpret the bit pattern
- The result is implementation-defined; most conversions are not portable
- Violating strict aliasing rules (reading a `float` through an `int*`) is **undefined behaviour**
- C++20 `std::bit_cast<T>(v)` is the safe, UB-free alternative for type punning

**See also** → `static_cast`, `const_cast`, `std::bit_cast`]],

  -- ── Template machinery ────────────────────────────────────────────────────

  ["typename"] = [[
**`typename`** · Introduce a template type parameter, or assert a dependent name is a type

```cpp
// Template type parameter (interchangeable with 'class'):
template<typename T>
T max(T a, T b) { return a > b ? a : b; }

// Required before a dependent qualified type name:
template<typename Container>
void print(const Container& c) {
    typename Container::iterator it = c.begin();   // 'typename' required
    // without it, compiler may parse 'Container::iterator' as a value
}

// C++11: in template aliases and variable templates too:
template<typename T>
using Ptr = std::unique_ptr<T>;
```

**`class` vs `typename`** — identical in template parameter lists; `typename` is preferred for clarity.
Only `typename` can disambiguate a dependent name (`T::type`) as a type; `class` cannot.

**See also** → `template`, `decltype`, `concept`]],

  ["typeid"] = [[
**`typeid`** · Runtime type identification (RTTI)

```cpp
#include <typeinfo>

int n = 42;
std::cout << typeid(n).name();          // implementation-defined (often mangled)

// Polymorphic types — reports the dynamic (actual) type:
Base* bp = new Derived;
std::cout << typeid(*bp).name();        // "Derived" (demangled with ABI)

// Equality test:
if (typeid(*bp) == typeid(Derived)) { }

// std::type_info is not copyable; use std::type_index for containers:
#include <typeindex>
std::unordered_map<std::type_index, std::string> names;
names[std::type_index(typeid(int))] = "int";
```

**Key facts**
- For non-polymorphic types, the type is determined at compile time
- For polymorphic types (with `virtual`), the type is determined at runtime via RTTI
- `typeid` on a null pointer throws `std::bad_typeid`
- Disable RTTI with `-fno-rtti` — this also disables `dynamic_cast`

**See also** → `dynamic_cast`, `virtual`, `type_info`]],

  -- ── Storage and alignment ─────────────────────────────────────────────────

  ["thread_local"] = [[
**`thread_local`** · Thread-local storage duration (C++11)

```cpp
thread_local int counter = 0;    // each thread gets its own copy

// Thread-local with non-trivial initialisation:
thread_local std::string threadName = "unnamed";

// In a function:
void increment() {
    thread_local int count = 0;  // initialised once per thread
    ++count;
    std::cout << count << '\n';
}
```

**Key facts**
- Each thread has its own independent copy of the variable
- Initialised the first time control passes through the declaration on each thread
- Can be combined with `static` or `extern` for different linkage
- Destructors run when the thread exits

**Use for** — per-thread error buffers, per-thread random number generators, per-thread caches.

**See also** → `static`, `volatile`, `std::thread`]],

  ["alignas"] = [[
**`alignas`** · Specify the alignment requirement of a type or variable (C++11)

```cpp
alignas(64) char cacheLine[64];         // cache-line aligned buffer
alignas(16) float simdData[4];          // SIMD-friendly alignment

struct alignas(16) Vec4 {
    float x, y, z, w;
};

// alignas must be a power of 2 and >= the natural alignment:
alignas(alignof(double)) char buf[sizeof(double)];
```

**Key facts**
- `alignas(N)` requires N to be a power of 2
- Cannot reduce alignment below the natural alignment of the type
- Combined with `alignof` to write portable aligned storage

**See also** → `alignof`, `std::aligned_storage`, `std::hardware_destructive_interference_size`]],

  ["alignof"] = [[
**`alignof`** · Query the alignment requirement of a type (C++11)

```cpp
alignof(char)    // 1
alignof(int)     // typically 4
alignof(double)  // typically 8
alignof(void*)   // 4 or 8 (platform pointer size)

// Use to allocate aligned storage:
alignas(alignof(T)) char storage[sizeof(T)];
new(storage) T{args};   // placement new into properly aligned buffer
```

Returns a `std::size_t` compile-time constant.
Equivalent to `_Alignof` from C11.

**See also** → `alignas`, `offsetof`, `std::max_align_t`]],

  -- ── C++20: Concepts ───────────────────────────────────────────────────────

  ["concept"] = [[
**`concept`** · Named compile-time constraint on template parameters (C++20)

```cpp
// Define a concept:
template<typename T>
concept Addable = requires(T a, T b) { a + b; };

template<typename T>
concept Numeric = std::is_arithmetic_v<T>;

// Named concept from the standard library:
#include <concepts>
template<std::integral T>
T gcd(T a, T b) { return b == 0 ? a : gcd(b, a % b); }

// Custom concept with compound requirements:
template<typename T>
concept Printable = requires(T t, std::ostream& os) {
    { os << t } -> std::same_as<std::ostream&>;
};

// Constrain a function:
template<Addable T>
T sum(T a, T b) { return a + b; }

// Shorthand (abbreviated template):
auto sum(Addable auto a, Addable auto b) { return a + b; }
```

**Standard library concepts** (in `<concepts>`)
- `std::integral`, `std::floating_point`, `std::signed_integral`
- `std::constructible_from`, `std::convertible_to`, `std::same_as`
- `std::invocable`, `std::predicate`
- `std::ranges::range`, `std::ranges::sized_range`

Concepts produce far cleaner error messages than SFINAE and `enable_if`.

**See also** → `requires`, `template`, `typename`]],

  ["requires"] = [[
**`requires`** · Specify or check constraints on template parameters (C++20)

```cpp
// requires-clause: gate a template on a constraint:
template<typename T>
    requires std::integral<T>
T factorial(T n) { return n <= 1 ? 1 : n * factorial(n - 1); }

// Inline requires (shorthand):
template<std::integral T>
T factorial(T n) { ... }

// requires-expression: check validity of expressions:
template<typename T>
concept Hashable = requires(T a) {
    { std::hash<T>{}(a) } -> std::convertible_to<std::size_t>;
};

// Compound requirement with nested type check:
template<typename Iter>
concept ForwardIterator = requires(Iter i) {
    typename Iter::value_type;
    { *i }  -> std::same_as<typename Iter::value_type&>;
    { ++i } -> std::same_as<Iter&>;
};
```

**Two roles of `requires`**
1. **requires-clause** — `requires Constraint` attaches a predicate to a template or function
2. **requires-expression** — `requires(params) { exprs; }` checks whether expressions are valid

**See also** → `concept`, `template`, `static_assert`]],

  -- ── C++20: Coroutines ─────────────────────────────────────────────────────

  ["co_await"] = [[
**`co_await`** · Suspend a coroutine until an awaitable completes (C++20)

```cpp
// Inside a coroutine function:
Task<std::string> fetchData(std::string url) {
    auto response = co_await httpGet(url);    // suspend here; resume when ready
    co_return response.body;
}

// co_await on a standard awaitable:
co_await std::suspend_always{};    // always suspend
co_await std::suspend_never{};     // never suspend (no-op)

// Awaiting a timer (Asio-style):
co_await timer.async_wait(use_awaitable);
```

**Key facts**
- A function becomes a coroutine when it contains `co_await`, `co_yield`, or `co_return`
- The return type must be a coroutine-compatible type with a `promise_type` member
- `co_await expr` calls `expr.operator co_await()` (or the global version) to get an awaiter
- The coroutine frame is heap-allocated by default; compilers may elide this

**Standard awaitables** — `std::suspend_always`, `std::suspend_never` (in `<coroutine>`)

**See also** → `co_return`, `co_yield`, `std::coroutine_handle`]],

  ["co_return"] = [[
**`co_return`** · Return a value from a coroutine (C++20)

```cpp
Task<int> compute() {
    int x = co_await asyncStep1();
    int y = co_await asyncStep2();
    co_return x + y;             // sets the coroutine result
}

// Void coroutine:
Task<void> fireAndForget() {
    co_await doWork();
    co_return;                   // optional in void coroutines
}
```

**Key facts**
- `co_return` calls `promise.return_value(expr)` (or `promise.return_void()` for no expression)
- After `co_return`, the coroutine reaches its final suspension point and is destroyed
- A coroutine must use `co_return` instead of `return` to produce a value

**See also** → `co_await`, `co_yield`]],

  ["co_yield"] = [[
**`co_yield`** · Suspend a coroutine and produce a value (C++20)

```cpp
Generator<int> fibonacci() {
    int a = 0, b = 1;
    while (true) {
        co_yield a;               // produce a, suspend
        auto next = a + b;
        a = b;
        b = next;
    }
}

// Usage:
for (int n : fibonacci() | std::views::take(10)) {
    std::cout << n << ' ';
}
```

**Key facts**
- `co_yield expr` is equivalent to `co_await promise.yield_value(expr)`
- The coroutine suspends at the `co_yield` point and resumes on the next call to the generator
- Useful for lazy sequences, pipelines, and cooperative multitasking

**See also** → `co_await`, `co_return`, `std::generator` (C++23)]],

  -- ── C++20: consteval / constinit ─────────────────────────────────────────

  ["consteval"] = [[
**`consteval`** · Immediate function — must always evaluate at compile time (C++20)

```cpp
consteval int square(int n) { return n * n; }

constexpr int a = square(5);   // OK — evaluated at compile time
int b = square(5);             // OK — still compile time (no runtime use)

int n = getInput();
int c = square(n);             // Error — n is not a constant expression
```

**`consteval` vs `constexpr`**
- `constexpr` functions *may* run at compile time or runtime
- `consteval` functions *must* always run at compile time — guaranteed, or it's a compile error
- Use `consteval` to enforce compile-time evaluation and get clearer errors

**Common use** — compile-time format string validation, template metaprogramming utilities.

**See also** → `constexpr`, `constinit`, `static_assert`]],

  ["constinit"] = [[
**`constinit`** · Guarantee a variable is initialised at compile time, but allow runtime mutation (C++20)

```cpp
constinit int counter = 0;          // initialised at compile time; can be modified later
constinit thread_local int tls = 0; // thread-local with compile-time init

// The "static initialisation order fiasco" is avoided:
constinit extern int global;        // assertion: this is constant-initialised
```

**`constinit` vs `constexpr`**
- `constexpr` variable: compile-time init AND immutable (implies `const`)
- `constinit` variable: compile-time init AND mutable

**Key facts**
- Does not imply `const` — the variable can be modified at runtime
- Applies to variables with static or thread-local storage duration
- Prevents the "static initialisation order fiasco" by ensuring zero/constant init

**See also** → `constexpr`, `consteval`, `thread_local`]],

  -- ── C++ alternative operator tokens ──────────────────────────────────────

  ["and"] = [[
**`and`** · Alternative token for `&&` (logical AND)

```cpp
if (a > 0 and b > 0) { }   // equivalent to: if (a > 0 && b > 0)
```

Defined in `<iso646.h>` in C; a keyword in C++.
Rarely used in practice — `&&` is almost universal.

**See also** → `or`, `not`, `and_eq`]],

  ["or"] = [[
**`or`** · Alternative token for `||` (logical OR)

```cpp
if (a == 0 or b == 0) { }   // equivalent to: if (a == 0 || b == 0)
```

**See also** → `and`, `not`, `or_eq`]],

  ["not"] = [[
**`not`** · Alternative token for `!` (logical NOT)

```cpp
if (not flag) { }   // equivalent to: if (!flag)
```

**See also** → `and`, `or`, `not_eq`]],

  ["xor"] = [[
**`xor`** · Alternative token for `^` (bitwise XOR)

```cpp
int result = a xor b;   // equivalent to: a ^ b
```

**See also** → `and`, `or`, `xor_eq`, `bitand`, `bitor`]],

  ["bitand"] = "**`bitand`** — alternative token for `&` (bitwise AND). `a bitand b` = `a & b`. See also: `bitor`, `xor`, `compl`.",
  ["bitor"]  = "**`bitor`** — alternative token for `|` (bitwise OR). `a bitor b` = `a | b`. See also: `bitand`, `xor`, `compl`.",
  ["compl"]  = "**`compl`** — alternative token for `~` (bitwise complement). `compl a` = `~a`. See also: `bitand`, `bitor`.",
  ["and_eq"] = "**`and_eq`** — alternative token for `&=` (bitwise AND-assignment). `a and_eq b` = `a &= b`.",
  ["or_eq"]  = "**`or_eq`** — alternative token for `|=` (bitwise OR-assignment). `a or_eq b` = `a |= b`.",
  ["not_eq"] = "**`not_eq`** — alternative token for `!=` (not-equal). `a not_eq b` = `a != b`.",
  ["xor_eq"] = "**`xor_eq`** — alternative token for `^=` (bitwise XOR-assignment). `a xor_eq b` = `a ^= b`.",

  -- ── Misc ─────────────────────────────────────────────────────────────────

  ["asm"] = [[
**`asm`** · Inline assembly (implementation-defined)

```cpp
// GCC/Clang extended asm:
int result;
asm volatile (
    "addl %1, %0"
    : "=r"(result)        // output operand
    : "r"(a), "0"(b)      // input operands
    :                     // clobbered registers
);

// Simple volatile asm (no operands):
asm volatile ("mfence" ::: "memory");   // memory barrier
```

**Key facts**
- Syntax is compiler-specific — GCC/Clang use AT&T syntax by default; MSVC uses Intel syntax
- `volatile` prevents the compiler from reordering or eliding the block
- Use `"memory"` clobber to act as a compiler memory barrier
- Avoid when possible — compiler intrinsics (`_mm_...`, `__builtin_...`) are more portable

**See also** → `volatile`, `constexpr`]],

  ["export"] = [[
**`export`** · Declare module interface exports (C++20 Modules)

```cpp
// mymath.ixx or mymath.cppm — module interface unit:
export module mymath;          // declare module name

export int add(int a, int b) { return a + b; }
export class Vec2 { /* ... */ };

export namespace mymath {
    double pi = 3.14159;
    double sqrt2 = 1.41421;
}

// Consumer:
import mymath;
int n = add(2, 3);
```

**Key facts**
- `export module` declares a module interface unit
- Only `export`ed names are visible to importers
- Modules replace `#include` header guards and avoid ODR violations
- Module support requires build system cooperation (`CMake 3.28+`, `Clang 16+`, `MSVC 2022`)

**See also** → `import` (C++20 modules), `namespace`]],
}

-- Merge C entries underneath (C++ overrides take precedence for shared keywords)
return vim.tbl_extend("keep", cpp, c)
