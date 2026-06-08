-- linus/keywords/cpp/type_traits.lua
-- Type traits and metaprogramming helpers (<type_traits>).

return {

  ["is_same"] = [[
**`std::is_same`** · Check if two types are identical (`<type_traits>`, C++11)

```cpp
static_assert(std::is_same_v<int, int>);              // true
static_assert(std::is_same_v<int, const int>);         // false (qualifiers matter)
static_assert(std::is_same_v<int, std::remove_cv_t<const int>>);  // true
```

**See also →** `std::is_same_v` (C++17), `std::remove_cv`, `std::decay`, `std::conditional`]],

  ["is_void"] = [[
**`std::is_void`** · Check if type is `void` (`<type_traits>`, C++11)

```cpp
static_assert(std::is_void_v<void>);
static_assert(std::is_void_v<const void>);  // qualifiers stripped before check
```

**See also →** `std::is_null_pointer`, `std::is_integral`, `std::is_floating_point`, `std::is_arithmetic`]],

  ["is_integral"] = [[
**`std::is_integral`** · Check if type is an integral type (`<type_traits>`, C++11)

```cpp
static_assert(std::is_integral_v<int>);
static_assert(!std::is_integral_v<float>);
// true for: bool, char, char8_t, char16_t, char32_t, wchar_t, short, int, long, long long, signed/unsigned variants
```

**See also →** `std::is_floating_point`, `std::is_arithmetic`, `std::is_signed`, `std::is_unsigned`]],

  ["is_floating_point"] = [[
**`std::is_floating_point`** · Check if type is a floating-point type (`<type_traits>`, C++11)

```cpp
static_assert(std::is_floating_point_v<float>);
static_assert(std::is_floating_point_v<double>);
static_assert(std::is_floating_point_v<long double>);
```

**See also →** `std::is_integral`, `std::is_arithmetic`, `std::is_fundamental`]],

  ["is_arithmetic"] = [[
**`std::is_arithmetic`** · Check if type is integral or floating-point (`<type_traits>`, C++11)

```cpp
static_assert(std::is_arithmetic_v<int>);       // integral → true
static_assert(std::is_arithmetic_v<double>);    // floating → true
static_assert(!std::is_arithmetic_v<void>);      // not arithmetic
```

**See also →** `std::is_integral`, `std::is_floating_point`, `std::is_fundamental`]],

  ["is_class"] = [[
**`std::is_class`** · Check if type is a non-union class type (`<type_traits>`, C++11)

```cpp
static_assert(std::is_class_v<std::string>);
static_assert(!std::is_class_v<int>);
static_assert(!std::is_class_v<union U>);  // unions are not classes
```

**See also →** `std::is_union`, `std::is_enum`, `std::is_fundamental`]],

  ["is_enum"] = [[
**`std::is_enum`** · Check if type is an enumeration (`<type_traits>`, C++11)

```cpp
enum Color { Red, Green, Blue };
static_assert(std::is_enum_v<Color>);
```

**See also →** `std::is_class`, `std::is_union`, `std::underlying_type`, `std::is_scoped_enum` (C++23)]],

  ["is_trivially_copyable"] = [[
**`std::is_trivially_copyable`** · Check if type is safe to `memcpy` (`<type_traits>`, C++11)

```cpp
struct Point { int x, y; };
static_assert(std::is_trivially_copyable_v<Point>);   // OK for memcpy

struct Foo {
    std::string s;  // not trivially copyable
};
```

**See also →** `std::memcpy`, `std::is_trivial`, `std::is_trivially_destructible`, `std::is_trivially_copy_constructible`]],

  ["conditional"] = [[
**`std::conditional`** · Compile-time type selection (`<type_traits>`, C++11)

```cpp
using BigType = std::conditional_t<(sizeof(int) < sizeof(long)), long, int>;
```

Ternary for types. Equivalent to `cond ? T : F` at compile time. Result is the type directly (not a `value`).

**See also →** `std::conditional_t` (C++14), `std::enable_if`, `std::conjunction` (C++17), `std::disjunction` (C++17)]],

  ["enable_if"] = [[
**`std::enable_if`** · SFINAE-based conditional (`<type_traits>`, C++11)

```cpp
template<typename T>
std::enable_if_t<std::is_integral_v<T>, T> inc(T val) { return val + 1; }

// With C++20 concepts, prefer:
std::integral auto inc(std::integral auto val) { return val + 1; }
```

`enable_if<B, T>::type` = `T` if `B` is true, else substitution failure (SFINAE). Since C++17/20, concepts are preferred over `enable_if` for most use cases.

**See also →** `std::conditional`, `std::conjunction` (C++17), `std::void_t` (C++17), `std::enable_if_t` (C++14)]],

  ["remove_cv"] = [[
**`std::remove_cv`** · Strip top-level const/volatile (`<type_traits>`, C++11)

```cpp
using T = std::remove_cv_t<const volatile int>;  // int
```

Related: `remove_const`, `remove_volatile`. Does **not** strip pointer/reference cv-qualifiers (e.g. `const int*` → `const int*` unchanged).

**See also →** `std::remove_cvref` (C++20), `std::decay`, `std::add_const`]],

  ["remove_reference"] = [[
**`std::remove_reference`** · Strip reference (`<type_traits>`, C++11)

```cpp
using T = std::remove_reference_t<int&>;   // int
using U = std::remove_reference_t<int&&>;  // int
```

**See also →** `std::remove_cvref` (C++20), `std::add_lvalue_reference`, `std::add_rvalue_reference`]],

  ["decay"] = [[
**`std::decay`** · Map to the type used in value semantics (`<type_traits>`, C++11)

```cpp
using T = std::decay_t<int&>;           // int  (lref → value)
using U = std::decay_t<const int[10]>;  // const int*  (array → pointer)
using V = std::decay_t<void()>;         // void(*)()  (function → pointer)
```

Simulates the type transformations that happen when passing by value. Combination of: `remove_reference` + `remove_cv` + array-to-pointer + function-to-pointer.

**See also →** `std::remove_cvref`, `std::remove_reference`, `std::type_identity` (C++20)]],

  ["invoke_result"] = [[
**`std::invoke_result`** · Deduce return type of callable (`<type_traits>`, C++17)

```cpp
using R = std::invoke_result_t<Fn, int, float>;  // return type of Fn(int, float)
```

Replaces `std::result_of` (removed in C++20). Works with all callables (functors, lambdas, member pointers).

**See also →** `std::is_invocable`, `std::is_nothrow_invocable`, `std::invoke`]],

  ["is_convertible"] = [[
**`std::is_convertible`** · Check if implicit conversion exists (`<type_traits>`, C++11)

```cpp
static_assert(std::is_convertible_v<int, double>);          // int → double
static_assert(std::is_convertible_v<Derived*, Base*>);      // upcast
static_assert(!std::is_convertible_v<Base*, Derived*>);     // downcast: not implicit
```

**See also →** `std::is_nothrow_convertible`, `std::is_constructible`, `std::is_assignable`]],

  ["is_base_of"] = [[
**`std::is_base_of`** · Check if one type is a base of another (`<type_traits>`, C++11)

```cpp
class Base {};
class Derived : Base {};
static_assert(std::is_base_of_v<Base, Derived>);     // true
static_assert(std::is_base_of_v<Base, Base>);         // true (considered base of itself)
```

**See also →** `std::is_convertible`, `std::derived_from` (concept, C++20), `std::is_empty`]],

  ["aligned_storage"] = [[
**`std::aligned_storage`** · Uninitialised memory block with alignment (`<type_traits>`, C++11)

```cpp
using Storage = std::aligned_storage_t<sizeof(T), alignof(T)>;
alignas(T) unsigned char buf[sizeof(T)];  // equivalent since C++11
```

**Deprecated in C++23.** Prefer manual `alignas` arrays or `std::byte`.

**See also →** `std::max_align_t`, `std::align`, `std::launder` (C++17)]],

  ["aligned_union"] = [[
**`std::aligned_union`** · Aligned union storage (`<type_traits>`, C++11)

```cpp
using Storage = std::aligned_union_t<0, int, float, double>;
```

Result is a POD type suitably aligned for any listed type.

**Deprecated in C++23.**

**See also →** `std::aligned_storage`, `std::variant`, `std::align`]],

  ["underlying_type"] = [[
**`std::underlying_type`** · Get the underlying integer type of an enum (`<type_traits>`, C++11)

```cpp
enum class Color : uint8_t { Red, Green, Blue };
using U = std::underlying_type_t<Color>;  // uint8_t
```

**See also →** `std::is_enum`, `std::to_underlying` (C++23)]],

  ["conjunction"] = [[
**`std::conjunction`** · Compile-time logical AND (`<type_traits>`, C++17)

```cpp
template<typename... Ts>
using all_integral = std::conjunction<std::is_integral<Ts>...>;

static_assert(all_integral<int, long, short>::value);
```

Short-circuits — stops after first `false`. Derives from the first failing trait (or the last trait).

**See also →** `std::disjunction` (OR), `std::negation` (NOT), fold expressions]],

  ["disjunction"] = [[
**`std::disjunction`** · Compile-time logical OR (`<type_traits>`, C++17)

```cpp
static_assert(std::disjunction_v<std::is_integral<int>, std::is_floating_point<int>>);
```

Short-circuits at first `true`.

**See also →** `std::conjunction`, `std::negation`, fold expressions]],

  ["negation"] = [[
**`std::negation`** · Compile-time logical NOT (`<type_traits>`, C++17)

```cpp
static_assert(std::negation_v<std::is_integral<float>>);
```

**See also →** `std::conjunction`, `std::disjunction`, `std::bool_constant`]],

  ["void_t"] = [[
**`std::void_t`** · Map any type sequence to `void` (`<type_traits>`, C++17)

```cpp
template<typename T, typename = void>
struct has_foo : std::false_type {};

template<typename T>
struct has_foo<T, std::void_t<decltype(&T::foo)>> : std::true_type {};
```

A key SFINAE helper — enables writing detection idioms by making a substitution failure when a type doesn't have a member, etc.

**See also →** `std::detected_or` (proposed, Library Fundamentals TS v2), `std::experimental::is_detected]],

  ["type_identity"] = [[
**`std::type_identity`** · Simple type wrapper (C++20)

```cpp
template<typename T>
void foo(T, std::type_identity_t<T>);  // prevents deduction for second parameter
```

Used to disable template argument deduction for specific parameters (makes them non-deduced contexts).

**See also →** `std::add_pointer`, `std::remove_cvref`, `std::common_type`]],

  ["common_type"] = [[
**`std::common_type`** · Find common type for multiple types (`<type_traits>`, C++11)

```cpp
using T = std::common_type_t<int, double>;  // double
using U = std::common_type_t<Derived&, Base&>;  // Base
```

Used by `std::chrono::duration` arithmetic, `std::conditional_t`, `std::visit` return type deduction.

**See also →** `std::common_reference` (C++20), `std::type_identity`, `std::conditional`]],
}
