-- linus/keywords/cpp/numeric.lua
-- Numeric libraries: complex, numeric_limits, bit, valarray, execution.

return {

  ["complex"] = [[
**`std::complex`** · Complex number (`<complex>`)

```cpp
#include <complex>
std::complex<double> z(1.0, 2.0);   // 1 + 2i
z.real();                            // 1.0
z.imag();                            // 2.0

z = std::polar(1.0, M_PI / 4);       // from magnitude and phase
auto mag = std::abs(z);              // magnitude
auto phase = std::arg(z);            // phase angle
auto conj = std::conj(z);            // conjugate
auto proj = std::proj(z);            // Riemann sphere projection

// Arithmetic works as expected:
z = z + std::complex<double>(1, 1);
z += 2.0;                            // real += 2
```

Literals: `3.14i` (C++14) — `using namespace std::complex_literals`.

**See also →** `std::valarray`, `std::polar`, `std::norm`, `std::real`, `std::imag`]],

  ["numeric_limits"] = [[
**`std::numeric_limits`** · Properties of arithmetic types (`<limits>`)

```cpp
#include <limits>
std::numeric_limits<int>::max();              // INT_MAX
std::numeric_limits<int>::min();              // INT_MIN (for signed)
std::numeric_limits<double>::epsilon();       // machine epsilon
std::numeric_limits<float>::digits;           // number of mantissa bits
std::numeric_limits<double>::quiet_NaN();     // NaN value (float/double only)
std::numeric_limits<float>::infinity();       // +inf
std::numeric_limits<double>::has_infinity;    // true (IEEE 754)
```

**Prefer over C macros** (`INT_MAX`, etc.) in template code. Specialized for all fundamental types.

**See also →** `<cfloat>` / `<climits>`, `std::numeric_limits::lowest`, `std::numeric_limits::round_style`, `std::numeric_limits::is_iec559`]],

  ["bit_cast"] = [[
**`std::bit_cast`** · Reinterpret object representation (`<bit>`, C++20)

```cpp
#include <bit>
float f = 3.14f;                                 // no
uint32_t u = std::bit_cast<uint32_t>(f);         // get IEEE 754 bits

struct A { int x; };
struct B { int y; };                             // same layout as A
B b = std::bit_cast<B>(A{42});                   // b.y == 42
```

**Undefined behaviour with `reinterpret_cast`** — `bit_cast` is the safe, constexpr-friendly alternative. Requires trivial copyability and equal sizes.

**See also →** `std::memcpy`, `std::bit_ceil`, `std::bit_floor`, `std::popcount`, `std::has_single_bit`]],

  ["popcount"] = [[
**`std::popcount`** · Count set bits (`<bit>`, C++20)

```cpp
#include <bit>
int bits = std::popcount(0b10101010u);   // 4
```

**See also →** `std::has_single_bit`, `std::countl_zero`, `std::countr_zero`, `std::countl_one`, `std::countr_one`, `std::bit_width`]],

  ["bit_width"] = [[
**`std::bit_width`** · Minimum number of bits to represent value (`<bit>`, C++20)

```cpp
int w = std::bit_width(42u);      // 6 (binary: 101010)
int w2 = std::bit_width(0u);      // 0
```

**See also →** `std::bit_ceil`, `std::bit_floor`, `std::popcount`, `std::has_single_bit`]],

  ["bit_ceil"] = [[
**`std::bit_ceil`** · Smallest power of 2 ≥ value (`<bit>`, C++20)

```cpp
auto c = std::bit_ceil(42u);       // 64
auto c2 = std::bit_ceil(0u);       // 1
```

**See also →** `std::bit_floor`, `std::bit_width`, `std::has_single_bit`]],

  ["bit_floor"] = [[
**`std::bit_floor`** · Largest power of 2 ≤ value (`<bit>`, C++20)

```cpp
auto f = std::bit_floor(42u);      // 32
auto f2 = std::bit_floor(0u);      // 0
```

**See also →** `std::bit_ceil`, `std::bit_width`, `std::has_single_bit`]],

  ["has_single_bit"] = [[
**`std::has_single_bit`** · Check if value is a power of 2 (`<bit>`, C++20)

```cpp
bool is_pow2 = std::has_single_bit(32u);   // true
```

Returns `true` iff exactly one bit is set (including `1`). Returns `false` for `0`.

**See also →** `std::popcount`, `std::bit_ceil`, `std::bit_floor`]],

  ["endian"] = [[
**`std::endian`** · Endianness detection (`<bit>`, C++20)

```cpp
#include <bit>
if constexpr (std::endian::native == std::endian::little) {
    // x86, x64, most ARM
} else if (std::endian::native == std::endian::big) {
    // some embedded / network order
}
```

Values: `std::endian::little`, `std::endian::big`, `std::endian::native`.

**See also →** `std::byteswap` (C++23), `htonl`, `ntohl` (POSIX)]],

  ["valarray"] = [[
**`std::valarray`** · Numeric array for vectorised operations (`<valarray>`)

```cpp
std::valarray<int> a = {1, 2, 3};
std::valarray<int> b = {4, 5, 6};

auto sum = a + b;                // element-wise: {5, 7, 9}
auto prod = a * b;               // element-wise: {4, 10, 18}
auto sq = a * a;                 // {1, 4, 9}
sum = a.sum();                   // 6 (reduce)

std::valarray<int> v = {1,2,3,4,5};
auto slice = v[std::slice(0, 3, 2)];  // {1, 3, 5} from {start, count, stride}
```

Niche — used for high-performance numeric code (BLAS-like). Less common than `std::vector`; `std::mdspan` (C++23) is the modern alternative for multi-dimensional.

**See also →** `std::slice`, `std::gslice`, `std::slice_array`, `std::mask_array`, `std::complex`]],

  ["execution_policy"] = [[
**`std::execution`** · Execution policies for parallel algorithms (`<execution>`, C++17)

```cpp
#include <execution>
std::vector<int> v = ...;

std::sort(std::execution::par, v.begin(), v.end());          // parallel
std::sort(std::execution::seq, v.begin(), v.end());          // sequential
std::sort(std::execution::par_unseq, v.begin(), v.end());    // parallel + vectorised
```

Tags in `std::execution` namespace: `seq`, `par`, `par_unseq`. Available when the standard library and hardware support parallel execution. `par_unseq` may interleave (vectorise or multithread).

**See also →** `std::is_execution_policy`, `std::reduce`, `std::transform_reduce`]],

  ["reduce"] = [[
**`std::reduce`** · Parallel-friendly fold/reduce (`<numeric>`, C++17)

```cpp
#include <numeric>
#include <execution>

std::vector<int> v = {1, 2, 3, 4};
int sum = std::reduce(std::execution::par, v.begin(), v.end());       // 10
int sum5 = std::reduce(std::execution::par, v.begin(), v.end(), 5);    // 15

// Non-deterministic ordering — use std::accumulate for guaranteed left-to-right
int fast = std::reduce(std::execution::par, v.begin(), v.end(),
                       std::plus<int>{});
```

**See also →** `std::accumulate`, `std::transform_reduce`, `std::inner_product`, `std::partial_sum`]],

  ["transform_reduce"] = [[
**`std::transform_reduce`** · Transform + reduce in one pass (`<numeric>`, C++17)

```cpp
#include <numeric>
std::vector<double> v = {1.0, 2.0, 3.0};
// Map: x → x*x, then sum
double ss = std::transform_reduce(v.begin(), v.end(), 0.0,
    std::plus{}, std::multiplies{});
```

Also supports two-range form (like inner product but parallel-friendly).

**See also →** `std::reduce`, `std::accumulate`, `std::inner_product`, `std::transform`]],

  ["exclusive_scan"] = [[
**`std::exclusive_scan`** · Exclusive prefix sum (`<numeric>`, C++17)

```cpp
std::vector<int> in = {1, 2, 3, 4};
std::vector<int> out(4);
std::exclusive_scan(in.begin(), in.end(), out.begin(), 0);
// out = {0, 1, 3, 6} (excludes current element)
```

`out[i] = init + sum(in[0..i-1])`. Get `out[n]` = total sum.

**See also →** `std::inclusive_scan`, `std::reduce`, `std::partial_sum`, `std::transform_exclusive_scan`]],

  ["inclusive_scan"] = [[
**`std::inclusive_scan`** · Inclusive prefix sum (`<numeric>`, C++17)

```cpp
std::vector<int> in = {1, 2, 3, 4};
std::vector<int> out(4);
std::inclusive_scan(in.begin(), in.end(), out.begin());
// out = {1, 3, 6, 10} (includes current element)
```

**See also →** `std::exclusive_scan`, `std::reduce`, `std::partial_sum`, `std::transform_inclusive_scan`]],

  ["partial_sum"] = [[
**`std::partial_sum`** · Cumulative sums (left-to-right, deterministic) (`<numeric>`)

```cpp
std::vector<int> in = {1, 2, 3, 4};
std::vector<int> out(4);
std::partial_sum(in.begin(), in.end(), out.begin());
// out = {1, 3, 6, 10}
```

**Deterministic order** — always left-to-right, unlike `std::reduce`. Use `std::inclusive_scan` when parallel execution is desired.

**See also →** `std::inclusive_scan`, `std::reduce`, `std::accumulate`, `std::adjacent_difference`]],

  ["iota"] = [[
**`std::iota`** · Fill range with sequentially increasing values (`<numeric>`)

```cpp
#include <numeric>
std::vector<int> v(10);
std::iota(v.begin(), v.end(), 0);    // v = {0, 1, 2, ..., 9}
std::iota(v.begin(), v.end(), 5);    // v = {5, 6, 7, ..., 14}
```

Assigns `*first = value`, `*(first+1) = ++value`, etc. Simple but useful for generating indices.

**See also →** `std::ranges::iota` (C++23), `std::fill`, `std::generate`, `std::sequence` (generator, C++23)]],

  ["midpoint"] = [[
**`std::midpoint`** · Safe midpoint calculation (`<numeric>`, C++20)

```cpp
#include <numeric>
int mid = std::midpoint(0, 10);           // 5
int mid2 = std::midpoint(INT_MAX, INT_MAX - 10);  // no overflow!
```

Avoids overflow of `(a + b) / 2`. Works for integers and pointers (C++20).

**See also →** `std::lerp`, `std::ranges::iota`, `std::abs`]],

  ["lerp"] = [[
**`std::lerp`** · Linear interpolation (`<numeric>`, C++20)

```cpp
#include <numeric>
double t = 0.5;
double v = std::lerp(0.0, 10.0, t);        // 5.0
// Formula: a + t * (b - a)

// Extrapolation still works:
double v2 = std::lerp(0.0, 10.0, 2.0);     // 20.0
```

**See also →** `std::midpoint`, `std::fma`, `std::lerp` guarantees monotonic interpolation even with floating-point imprecision.]],
}
