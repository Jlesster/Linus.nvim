-- linus/keywords/cpp/algorithms.lua
-- STL algorithms reference entries.

return {

  ["sort"] = [[
**`std::sort`** · Sort a range (`<algorithm>`)

```cpp
#include <algorithm>
std::vector<int> v = {3, 1, 4, 1, 5};

std::sort(v.begin(), v.end());                // ascending: {1, 1, 3, 4, 5}
std::sort(v.begin(), v.end(), std::greater{}); // descending
std::ranges::sort(v);                          // C++20
```

O(n log n). **Not stable** — equal elements may be reordered. Uses introsort (quicksort + heapsort + insertion sort).

**Requires random-access iterators** — does not work on `std::list` (use `list::sort()`).

**See also →** `std::stable_sort`, `std::partial_sort`, `std::nth_element`, `std::sort_heap`]],

  ["stable_sort"] = [[
**`std::stable_sort`** · Stable sort (`<algorithm>`)

```cpp
std::stable_sort(v.begin(), v.end());
```

O(n log² n) if extra memory is insufficient, O(n log n) otherwise. Preserves relative order of equivalent elements.

**See also →** `std::sort`, `std::partial_sort`]],

  ["partial_sort"] = [[
**`std::partial_sort`** · Partially sort a range (`<algorithm>`)

```cpp
std::partial_sort(v.begin(), v.begin() + 3, v.end());
// First 3 elements are the smallest, in order; rest are unsorted
```

O(n log k) where k is the number of sorted elements.

**See also →** `std::sort`, `std::nth_element`, `std::partial_sort_copy`]],

  ["nth_element"] = [[
**`std::nth_element`** · Partially sort so nth element is in final position (`<algorithm>`)

```cpp
std::nth_element(v.begin(), v.begin() + 5, v.end());
// Element at position 5 is what would be there if fully sorted
// Elements before are ≤ it; elements after are ≥ it
```

O(n) average — does **not** fully sort. Useful for median, percentile, selection.

**See also →** `std::partial_sort`, `std::sort`, `std::stable_sort`]],

  ["lower_bound"] = [[
**`std::lower_bound`** · First element not less than value (`<algorithm>`)

```cpp
auto it = std::lower_bound(v.begin(), v.end(), 42);
```

Requires **sorted** range. O(log n). Returns iterator to first element ≥ 42, or `end()` if none.

**See also →** `std::upper_bound`, `std::equal_range`, `std::binary_search`, `std::partition_point`]],

  ["upper_bound"] = [[
**`std::upper_bound`** · First element greater than value (`<algorithm>`)

```cpp
auto it = std::upper_bound(v.begin(), v.end(), 42);
```

Requires **sorted** range. O(log n). Returns iterator to first element > 42, or `end()` if none.

**See also →** `std::lower_bound`, `std::equal_range`, `std::binary_search`]],

  ["binary_search"] = [[
**`std::binary_search`** · Test if value exists in sorted range (`<algorithm>`)

```cpp
if (std::binary_search(v.begin(), v.end(), 42)) { /* found */ }
```

Requires **sorted** range. O(log n). Returns `bool`.

**See also →** `std::lower_bound`, `std::equal_range`, `std::find`]],

  ["equal_range"] = [[
**`std::equal_range`** · Range of elements equal to value (`<algorithm>`)

```cpp
auto [lo, hi] = std::equal_range(v.begin(), v.end(), 42);
// [lo, hi) spans all elements == 42
```

Combines `lower_bound` and `upper_bound` in a single binary search. Returns `std::pair` of iterators.

**See also →** `std::lower_bound`, `std::upper_bound`, `std::binary_search`]],

  ["find"] = [[
**`std::find`** · Find first occurrence of value (`<algorithm>`)

```cpp
auto it = std::find(v.begin(), v.end(), 42);
if (it != v.end()) { /* found at index: it - v.begin() */ }
```

O(n) linear search. Returns iterator or `end()`.

**See also →** `std::find_if`, `std::find_if_not`, `std::binary_search`, `std::lower_bound`]],

  ["find_if"] = [[
**`std::find_if`** · Find first element satisfying a predicate (`<algorithm>`)

```cpp
auto it = std::find_if(v.begin(), v.end(), [](int x) { return x > 10; });
```

O(n). Returns iterator or `end()`.

**See also →** `std::find`, `std::find_if_not`, `std::find_first_of`, `std::find_end`]],

  ["find_if_not"] = [[
**`std::find_if_not`** · Find first element not satisfying a predicate (`<algorithm>`, C++11)

```cpp
auto it = std::find_if_not(v.begin(), v.end(), pred);
```

Inverse of `find_if`. Returns iterator to first element where `pred` is false.

**See also →** `std::find`, `std::find_if`]],

  ["count"] = [[
**`std::count`** · Count occurrences of a value (`<algorithm>`)

```cpp
auto n = std::count(v.begin(), v.end(), 42);
```

O(n). Returns `iterator_traits::difference_type` (aka `ptrdiff_t`).

**See also →** `std::count_if`, `std::find`]],

  ["count_if"] = [[
**`std::count_if`** · Count elements satisfying a predicate (`<algorithm>`)

```cpp
auto n = std::count_if(v.begin(), v.end(), [](int x) { return x > 0; });
```

O(n).

**See also →** `std::count`, `std::find_if`]],

  ["for_each"] = [[
**`std::for_each`** · Apply function to each element (`<algorithm>`)

```cpp
std::for_each(v.begin(), v.end(), [](int& x) { x *= 2; });
```

O(n). Returns the function (or `std::move(f)` since C++11). Unlike range-for, works with iterator pairs and function objects with state.

**See also →** `std::transform`, `std::for_each_n` (C++17)]],

  ["transform"] = [[
**`std::transform`** · Apply function to range and store result (`<algorithm>`)

```cpp
std::transform(v.begin(), v.end(), out.begin(), [](int x) { return x * 2; });

// Binary version — combines two ranges:
std::transform(a.begin(), a.end(), b.begin(), out.begin(),
               [](int x, int y) { return x + y; });
```

O(n). Source and destination can be the same range (in-place transform).

**See also →** `std::for_each`, `std::copy`, `std::generate`]],

  ["copy"] = [[
**`std::copy`** · Copy elements from one range to another (`<algorithm>`)

```cpp
std::copy(src.begin(), src.end(), dst.begin());
```

`dst` must be large enough to hold all elements. Returns iterator to `dst` past the last copied element. For overlapping ranges, use `std::copy_backward` (copies right-to-left).

**See also →** `std::copy_if`, `std::copy_n`, `std::copy_backward`, `std::move`]],

  ["copy_if"] = [[
**`std::copy_if`** · Copy elements satisfying a predicate (`<algorithm>`, C++11)

```cpp
std::copy_if(v.begin(), v.end(), std::back_inserter(result),
             [](int x) { return x > 0; });
```

**See also →** `std::copy`, `std::copy_n`, `std::remove_copy_if`, `std::partition_copy`]],

  ["move"] = [[
**`std::move`** · Move elements from one range to another (`<algorithm>`)

```cpp
std::move(src.begin(), src.end(), dst.begin());
```

Uses move-assignment (`operator=`). Leaves source elements in a "valid but unspecified" state. Often combined with `std::move_iterator`.

**See also →** `std::copy`, `std::move_backward`, `std::move` (cast in `<utility>`)]],

  ["fill"] = [[
**`std::fill`** · Assign the same value to every element (`<algorithm>`)

```cpp
std::fill(v.begin(), v.end(), 0);
std::fill_n(v.begin(), n, 0);   // first n elements
```

**See also →** `std::fill_n`, `std::generate`, `std::memset` (for PODs)]],

  ["generate"] = [[
**`std::generate`** · Assign result of callable to each element (`<algorithm>`)

```cpp
std::generate(v.begin(), v.end(), []() { return rand() % 100; });
std::generate_n(v.begin(), n, generator);
```

**See also →** `std::fill`, `std::iota`, `std::transform`]],

  ["replace"] = [[
**`std::replace`** · Replace occurrences of a value in-place (`<algorithm>`)

```cpp
std::replace(v.begin(), v.end(), 42, 0);  // replace all 42 with 0
std::replace_if(v.begin(), v.end(), pred, new_val);
```

**See also →** `std::replace_copy`, `std::replace_copy_if`, `std::remove`]],

  ["remove"] = [[
**`std::remove`** · Remove elements equal to value (by shifting) (`<algorithm>`)

```cpp
auto it = std::remove(v.begin(), v.end(), 42);
v.erase(it, v.end());   // erase-remove idiom
```

**Does not erase** — returns new logical end. The erase-remove idiom: `v.erase(std::remove(...), v.end())`.

**See also →** `std::remove_if`, `std::erase` (C++20 container extension), `std::unique`]],

  ["unique"] = [[
**`std::unique`** · Remove consecutive duplicates (`<algorithm>`)

```cpp
auto it = std::unique(v.begin(), v.end());
v.erase(it, v.end());

// With predicate:
std::unique(v.begin(), v.end(), [](int a, int b) { return a == b; });
```

**See also →** `std::unique_copy`, `std::remove`, `std::adjacent_find`]],

  ["reverse"] = [[
**`std::reverse`** · Reverse the order of elements (`<algorithm>`)

```cpp
std::reverse(v.begin(), v.end());
```

O(n). Bidirectional iterators required.

**See also →** `std::reverse_copy`, `std::rotate`]],

  ["rotate"] = [[
**`std::rotate`** · Rotate elements around a pivot (`<algorithm>`)

```cpp
// Make middle element the new first:
std::rotate(v.begin(), v.begin() + 3, v.end());
// {1,2,3,4,5} → {4,5,1,2,3}
```

O(n). Useful for cyclic shifts.

**See also →** `std::rotate_copy`, `std::reverse`, `std::shift_left` (C++20)]],

  ["shuffle"] = [[
**`std::shuffle`** · Randomly reorder elements (`<algorithm>`, C++11)

```cpp
std::shuffle(v.begin(), v.end(), std::mt19937{std::random_device{}()});
```

Replaces `std::random_shuffle` (removed in C++17). Uses a URBG (uniform random bit generator).

**See also →** `std::sample`, `std::random_shuffle` (deprecated/removed)]],

  ["sample"] = [[
**`std::sample`** · Select n random elements from a range (`<algorithm>`, C++17)

```cpp
std::sample(v.begin(), v.end(), std::back_inserter(sample), 5,
            std::mt19937{std::random_device{}()});
```

Selects 5 uniformly random elements. Does not modify source.

**See also →** `std::shuffle`, `std::partition`]],

  ["iota"] = [[
**`std::iota`** · Fill with incrementing values (`<numeric>`)

```cpp
std::iota(v.begin(), v.end(), 0);   // {0, 1, 2, 3, ...}
```

**See also →** `std::fill`, `std::generate`, `std::accumulate`]],

  ["accumulate"] = [[
**`std::accumulate`** · Sum (or fold) over a range (`<numeric>`)

```cpp
int sum = std::accumulate(v.begin(), v.end(), 0);               // sum
int prod = std::accumulate(v.begin(), v.end(), 1, std::multiplies{});  // product
```

Initial value determines result type. Left fold.

**See also →** `std::reduce` (C++17, parallel), `std::partial_sum`, `std::inner_product`]],

  ["min"] = [[
**`std::min`** · Smaller of two values (`<algorithm>`)

```cpp
int m = std::min(a, b);
int m = std::min({a, b, c});           // initializer list (C++11)
```

Returns `const T&` — dangling reference risk if one argument is a temporary.

**See also →** `std::max`, `std::minmax`, `std::min_element`, `std::clamp`]],

  ["max"] = [[
**`std::max`** · Larger of two values (`<algorithm>`)

```cpp
int m = std::max(a, b);
```

Same return-by-const-ref caveat as `std::min`.

**See also →** `std::min`, `std::minmax`, `std::max_element`]],

  ["minmax"] = [[
**`std::minmax`** · Both smallest and largest (`<algorithm>`, C++11)

```cpp
auto [lo, hi] = std::minmax({3, 1, 4, 1, 5});  // lo=1, hi=5
```

Returns `std::pair<const T&, const T&>`.

**See also →** `std::min`, `std::max`, `std::minmax_element`]],

  ["clamp"] = [[
**`std::clamp`** · Constrain value to a range (`<algorithm>`, C++17)

```cpp
int x = std::clamp(val, lo, hi);  // if val < lo → lo; val > hi → hi; else val
```

Returns `const T&`. `lo` must be ≤ `hi`.

**See also →** `std::min`, `std::max`]],

  ["all_of"] = [[
**`std::all_of`** · Test if predicate holds for all elements (`<algorithm>`, C++11)

```cpp
bool all_positive = std::all_of(v.begin(), v.end(), [](int x) { return x > 0; });
```

Returns true for empty range.

**See also →** `std::any_of`, `std::none_of`, `std::find_if`]],

  ["any_of"] = [[
**`std::any_of`** · Test if predicate holds for any element (`<algorithm>`, C++11)

```cpp
bool any_even = std::any_of(v.begin(), v.end(), [](int x) { return x % 2 == 0; });
```

Returns false for empty range.

**See also →** `std::all_of`, `std::none_of`]],

  ["none_of"] = [[
**`std::none_of`** · Test if predicate holds for no elements (`<algorithm>`, C++11)

```cpp
bool none_negative = std::none_of(v.begin(), v.end(), [](int x) { return x < 0; });
```

Returns true for empty range.

**See also →** `std::all_of`, `std::any_of`]],

  ["merge"] = [[
**`std::merge`** · Merge two sorted ranges into one (`<algorithm>`)

```cpp
std::merge(a.begin(), a.end(), b.begin(), b.end(), out.begin());
```

Both inputs must be sorted. Output also sorted. O(n + m).

**See also →** `std::inplace_merge`, `std::sort`, `std::set_union`]],

  ["inplace_merge"] = [[
**`std::inplace_merge`** · Merge two consecutive sorted ranges in-place (`<algorithm>`)

```cpp
std::inplace_merge(v.begin(), v.begin() + 5, v.end());
```

Useful for merge sort implementations. O(n) if extra memory is available, O(n log n) otherwise.

**See also →** `std::merge`, `std::sort`]],

  ["set_union"] = [[
**`std::set_union`** · Union of two sorted ranges (`<algorithm>`)

```cpp
auto it = std::set_union(a.begin(), a.end(), b.begin(), b.end(), out.begin());
```

Elements that appear in both ranges appear once in the output.

**See also →** `std::set_intersection`, `std::set_difference`, `std::set_symmetric_difference`, `std::merge`]],

  ["set_intersection"] = [[
**`std::set_intersection`** · Intersection of two sorted ranges (`<algorithm>`)

```cpp
auto it = std::set_intersection(a.begin(), a.end(), b.begin(), b.end(), out.begin());
```

Output contains elements present in both ranges.

**See also →** `std::set_union`, `std::set_difference`, `std::includes`]],

  ["set_difference"] = [[
**`std::set_difference`** · Elements in first but not second sorted range (`<algorithm>`)

```cpp
auto it = std::set_difference(a.begin(), a.end(), b.begin(), b.end(), out.begin());
```

**See also →** `std::set_intersection`, `std::set_symmetric_difference`, `std::includes`]],

  ["includes"] = [[
**`std::includes`** · Check if one sorted range is a subset of another (`<algorithm>`)

```cpp
if (std::includes(v.begin(), v.end(), sub.begin(), sub.end())) { /* sub ⊆ v */ }
```

**See also →** `std::set_union`, `std::set_intersection`, `std::is_permutation`]],

  ["equal"] = [[
**`std::equal`** · Test if two ranges are element-wise equal (`<algorithm>`)

```cpp
if (std::equal(a.begin(), a.end(), b.begin())) { /* same contents */ }
```

C++14: four-iterator overload checks length mismatch. For predicate: `std::equal(a, b, pred)`.

**See also →** `std::mismatch`, `std::lexicographical_compare`, `std::search`]],

  ["mismatch"] = [[
**`std::mismatch`** · Find first position where two ranges differ (`<algorithm>`)

```cpp
auto [a_it, b_it] = std::mismatch(a.begin(), a.end(), b.begin());
if (a_it != a.end()) { /* first difference at a_it, b_it */ }
```

**See also →** `std::equal`, `std::search`, `std::adjacent_find`]],

  ["lexicographical_compare"] = [[
**`std::lexicographical_compare`** · Dictionary-order comparison (`<algorithm>`)

```cpp
if (std::lexicographical_compare(a.begin(), a.end(), b.begin(), b.end())) {
    // a < b in dictionary order
}
```

**See also →** `std::equal`, `std::mismatch`, `std::sort`]],

  ["partition"] = [[
**`std::partition`** · Partition a range by a predicate (`<algorithm>`)

```cpp
auto mid = std::partition(v.begin(), v.end(), [](int x) { return x < 10; });
// [begin, mid) → true; [mid, end) → false
```

O(n). **Not stable** — order within groups is unspecified.

**See also →** `std::stable_partition`, `std::partition_copy`, `std::partition_point`, `std::nth_element`]],

  ["stable_partition"] = [[
**`std::stable_partition`** · Stable partition (`<algorithm>`)

```cpp
auto mid = std::stable_partition(v.begin(), v.end(), pred);
```

Preserves relative order within each group. May allocate a temporary buffer.

**See also →** `std::partition`, `std::partition_copy`]],

  ["partition_point"] = [[
**`std::partition_point`** · Find partition point in a partitioned range (`<algorithm>`, C++11)

```cpp
auto it = std::partition_point(v.begin(), v.end(), pred);
// First element where pred is false — requires partitioned input
```

O(log n).

**See also →** `std::lower_bound`, `std::partition`]],

  ["next_permutation"] = [[
**`std::next_permutation`** · Generate next lexicographic permutation (`<algorithm>`)

```cpp
do {
    // process current permutation
} while (std::next_permutation(v.begin(), v.end()));
```

O(n). Returns false when the range is in descending order (last permutation). Starts from sorted ascending.

**See also →** `std::prev_permutation`, `std::is_permutation`, `std::rotate`]],

  ["is_permutation"] = [[
**`std::is_permutation`** · Test if range is a permutation of another (`<algorithm>`, C++11)

```cpp
if (std::is_permutation(a.begin(), a.end(), b.begin())) { /* a is a permutation of b */ }
```

O(n²) worst case.

**See also →** `std::next_permutation`, `std::sort`, `std::equal`]],

  ["min_element"] = [[
**`std::min_element`** · Iterator to smallest element (`<algorithm>`)

```cpp
auto it = std::min_element(v.begin(), v.end());
```

O(n). Returns `end()` if range is empty.

**See also →** `std::max_element`, `std::minmax_element`, `std::min`]],

  ["max_element"] = [[
**`std::max_element`** · Iterator to largest element (`<algorithm>`)

```cpp
auto it = std::max_element(v.begin(), v.end());
```

**See also →** `std::min_element`, `std::minmax_element`, `std::max`]],

  ["minmax_element"] = [[
**`std::minmax_element`** · Iterators to both smallest and largest (`<algorithm>`, C++11)

```cpp
auto [lo, hi] = std::minmax_element(v.begin(), v.end());
```

Returns `std::pair<iterator, iterator>`. At most max(floor(3n/2), 0) comparisons.

**See also →** `std::min_element`, `std::max_element`, `std::minmax`]],

  ["adjacent_find"] = [[
**`std::adjacent_find`** · Find first pair of equal adjacent elements (`<algorithm>`)

```cpp
auto it = std::adjacent_find(v.begin(), v.end());
// it = first of the pair; it+1 = second
```

O(n). Returns `end()` if no adjacent equal elements.

**See also →** `std::unique`, `std::equal`, `std::search`]],

  ["search"] = [[
**`std::search`** · Find subsequence in range (`<algorithm>`)

```cpp
auto it = std::search(haystack.begin(), haystack.end(),
                      needle.begin(), needle.end());
```

O(n*m) naive. For Boyer-Moore: `std::boyer_moore_searcher` (C++17).

**See also →** `std::find`, `std::find_end`, `std::search_n`, `std::mismatch`]],

  ["is_sorted"] = [[
**`std::is_sorted`** · Check if range is sorted (`<algorithm>`, C++11)

```cpp
if (std::is_sorted(v.begin(), v.end())) { /* ascending */ }
```

O(n).

**See also →** `std::is_sorted_until`, `std::is_heap`, `std::sort`]],

  ["is_heap"] = [[
**`std::is_heap`** · Check if range forms a max-heap (`<algorithm>`, C++11)

```cpp
if (std::is_heap(v.begin(), v.end())) { }
```

**See also →** `std::make_heap`, `std::push_heap`, `std::pop_heap`, `std::sort_heap`, `std::priority_queue`]],
}
