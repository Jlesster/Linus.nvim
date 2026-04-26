-- jlesster/keywords/cpp.lua
-- C++ keywords. Inherits all C entries and adds/overrides C++-specific ones.

local c = require("linus.keywords.c")

local cpp = {
  ["class"] = [[
**`class`** — declares a class type. Default member access is `private` (vs `struct` which defaults to `public`).
```cpp
class Foo : public Bar, private Baz {
public:
    Foo(int x);
    virtual ~Foo();
    virtual void method() = 0;   // pure virtual
private:
    int x_;
};
```]],

  ["struct"] = [[
**`struct`** — same as `class` but default member access is `public`.
Preferred for simple aggregates / POD types.
```cpp
struct Point { float x, y; };
Point p{1.0f, 2.0f};       // aggregate init
auto [x, y] = p;            // structured binding (C++17)
```]],

  ["template"] = [[
**`template`** — parameterises a class, function, or variable by type or value.
```cpp
template<typename T>
T max(T a, T b) { return a > b ? a : b; }

template<typename T, int N>
struct Array { T data[N]; };

// Explicit specialisation
template<>
int max<int>(int a, int b) { return a > b ? a : b; }
```]],

  ["auto"] = [[
**`auto`** — type deduction for variables, return types, and template parameters.
```cpp
auto x = 42;                // int
auto& ref = vec[0];         // reference to element type
auto fn = [](int a) { return a * 2; };  // lambda

// trailing return type
auto add(int a, int b) -> int { return a + b; }
```
C++14: `auto` return type deduction. C++20: `auto` function parameters (abbreviated templates).]],

  ["namespace"] = [[
**`namespace`** — groups names to avoid conflicts.
```cpp
namespace mylib {
    void helper();
    namespace detail { /* ... */ }
}
mylib::helper();

using namespace mylib;   // imports all names (avoid in headers)
using mylib::helper;     // imports specific name
namespace ml = mylib;    // alias
```]],

  ["virtual"] = [[
**`virtual`** — enables dynamic dispatch (runtime polymorphism).
```cpp
struct Base {
    virtual void draw() { }   // overridable
    virtual void pure() = 0;  // pure virtual — makes Base abstract
    virtual ~Base() = default; // always virtualise destructor in base
};

struct Derived : Base {
    void draw() override { }  // override keyword catches typos
};
```]],

  ["override"] = [[
**`override`** — asserts this method overrides a virtual base method (C++11).
Compile error if no matching virtual method exists in a base class.
```cpp
void draw() override;
```]],

  ["final"] = [[
**`final`** — prevents a class from being subclassed, or a virtual method from being overridden (C++11).
```cpp
class Concrete final : public Base { };
virtual void method() final;
```]],

  ["constexpr"] = [[
**`constexpr`** — evaluated at compile time when arguments are constant.
```cpp
constexpr int square(int x) { return x * x; }
constexpr int N = square(8);  // 64, compile-time constant

constexpr double PI = 3.14159265358979;
```
`constexpr` implies `const` for variables. C++20: `consteval` (always compile-time), `constinit` (compile-time init, runtime mutable).]],

  ["explicit"] = [[
**`explicit`** — prevents implicit conversions via single-argument constructors or conversion operators.
```cpp
explicit Foo(int x);   // must be constructed as Foo{x}, not foo = x
explicit operator bool() const;
```]],

  ["nullptr"] = [[
**`nullptr`** — type-safe null pointer constant (C++11). Type: `std::nullptr_t`.
```cpp
int* p = nullptr;
void* vp = nullptr;
```
Prefer over `NULL` or `0` — avoids ambiguity in overload resolution.]],

  ["new"] = [[
**`new`** — allocates on the heap and calls the constructor.
```cpp
Foo* p = new Foo(args);    // heap allocation
Foo* arr = new Foo[n];     // array
delete p;                   // destructor + deallocate
delete[] arr;               // array delete

// placement new (construct in pre-allocated memory)
new(ptr) Foo(args);
```
Prefer smart pointers (`std::unique_ptr`, `std::shared_ptr`) over raw `new`/`delete`.]],

  ["delete"] = [[
**`delete`** — calls destructor and deallocates heap memory.
```cpp
delete ptr;      // single object
delete[] arr;    // array (must match new[])
```
`delete nullptr` is a no-op. Never delete the same pointer twice.]],

  ["lambda"] = [[
**Lambda expression** (C++11) — anonymous function object.
```cpp
auto fn = [capture](params) -> RetType { body; };

// captures
[=]        // capture all by value
[&]        // capture all by reference
[x, &y]    // x by value, y by reference
[this]     // capture this pointer

// examples
auto sq = [](int x) { return x * x; };
std::sort(v.begin(), v.end(), [](int a, int b) { return a < b; });
```]],

  ["move"] = [[
**`std::move`** — casts to an rvalue reference, enabling move semantics.
```cpp
std::vector<int> b = std::move(a);   // a is now in a valid but unspecified state
```
Move constructors and move assignment operators transfer ownership without copying.]],

  ["using"] = [[
**`using`** — type alias, namespace import, or base member promotion.
```cpp
using Bytes = std::vector<uint8_t>;   // type alias (preferred over typedef)
using namespace std;                   // import namespace (avoid in headers)
using Base::method;                    // bring base method into derived scope
```]],

  ["enum"] = [[
**`enum class`** (scoped enum, C++11) — strongly-typed, scoped enumeration.
```cpp
enum class Color { Red, Green, Blue };
Color c = Color::Red;      // must qualify with scope
// does not implicitly convert to int

// specify underlying type
enum class Flags : uint8_t { A = 1, B = 2, C = 4 };
```
Prefer `enum class` over plain `enum` to avoid name collisions and implicit int conversions.]],

  ["noexcept"] = [[
**`noexcept`** — specifies that a function does not throw exceptions (C++11).
```cpp
void swap(T& a, T& b) noexcept { /* ... */ }
```
Enables optimisations (e.g. `std::vector` uses move constructors only if `noexcept`).
`noexcept(expr)`: conditional, based on a compile-time boolean.]],

  ["static_assert"] = [[
**`static_assert`** — compile-time assertion (C++11).
```cpp
static_assert(sizeof(int) == 4, "int must be 4 bytes");
static_assert(std::is_trivially_copyable_v<T>);
```
Fails with a compile error if the condition is false.]],

  ["decltype"] = [[
**`decltype`** — deduces the type of an expression without evaluating it.
```cpp
decltype(x + y) result;          // type of x+y
decltype(auto) fn() { return x; } // preserves reference/const
```]],

  ["try"] = [[
**`try`** — exception handling block.
```cpp
try {
    riskyOp();
} catch (const std::runtime_error& e) {
    std::cerr << e.what();
} catch (...) {
    // catch all
}
```
RAII-managed resources are automatically cleaned up during stack unwinding.]],
}

-- Merge C entries underneath (C++ overrides take precedence)
return vim.tbl_extend("keep", cpp, c)
