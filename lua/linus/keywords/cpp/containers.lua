-- linus/keywords/cpp/containers.lua
-- STL containers reference entries.

return {

  ["vector"] = [[
**`std::vector`** · Dynamic contiguous array

```cpp
#include <vector>
std::vector<int> v;                    // empty
std::vector<int> v(10, -1);            // 10 elements, all -1
std::vector<int> v = {1, 2, 3};        // initializer list

v.push_back(4);                        // O(1) amortized
v.pop_back();                          // O(1)
v[i];                                  // O(1) — no bounds check
v.at(i);                               // O(1) — throws std::out_of_range
v.size();                              // O(1)
v.capacity();                          // currently allocated storage
v.reserve(100);                        // pre-allocate to avoid reallocation
v.shrink_to_fit();                     // reduce capacity to size (C++11)
```

**Iterator invalidation:** reallocation invalidates all iterators/refs; insertion/removal in the middle shifts elements.

**When to use:** default dynamic container. Contiguous storage = cache-friendly.]],

  ["deque"] = [[
**`std::deque`** · Double-ended queue (`<deque>`)

```cpp
#include <deque>
std::deque<int> d = {1, 2, 3};

d.push_front(0);   // O(1)
d.push_back(4);    // O(1)
d.pop_front();     // O(1)
d.pop_back();      // O(1)
d[i];              // O(1)
```

Non-contiguous storage — segmented into fixed-size blocks. Insertion at ends does not invalidate other elements' references, but invalidates iterators.

**When to use:** need O(1) push/pop at both ends; don't need contiguous memory.]],

  ["list"] = [[
**`std::list`** · Doubly-linked list (`<list>`)

```cpp
#include <list>
std::list<int> l = {1, 2, 3};

l.push_front(0);     // O(1)
l.push_back(4);      // O(1)
l.insert(it, val);   // O(1) at iterator position
l.erase(it);         // O(1)
l.sort();            // O(n log n) — member sort, not std::sort
l.merge(l2);         // merge sorted lists
l.splice(it, l2);    // transfer elements from l2 without copying
```

No `operator[]` — must iterate to access by index. Each element individually allocated.

**When to use:** frequent insertions/removals in the middle; need stable iterators that don't invalidate.]],

  ["forward_list"] = [[
**`std::forward_list`** · Singly-linked list (`<forward_list>`, C++11)

```cpp
#include <forward_list>
std::forward_list<int> fl = {1, 2, 3};

fl.push_front(0);        // O(1)
fl.insert_after(it, v);  // O(1) — insert after given position
fl.erase_after(it);      // O(1)
fl.before_begin();       // iterator before first element (for insert_after)
```

Minimal overhead — no `size()` member (would require O(n) or a counter). No `push_back` — only forward iteration.

**When to use:** memory-constrained environments; need a singly-linked list.]],

  ["array"] = [[
**`std::array`** · Fixed-size array with STL interface (`<array>`, C++11)

```cpp
#include <array>
std::array<int, 5> a = {1, 2, 3, 4, 5};

a[0];               // O(1) — no bounds check
a.at(0);            // O(1) — throws std::out_of_range
a.size();           // compile-time constant
a.front();          // first element
a.back();           // last element
a.data();           // pointer to underlying C array
```

No overhead vs C array `T[N]`. Always stack-allocated (or inline in other types). Cannot be resized.

**When to use:** replacement for C arrays; fixed-size buffers; constexpr-friendly.]],

  ["string"] = [[
**`std::string`** · Dynamically-sized string (`<string>`)

```cpp
#include <string>
std::string s = "hello";
std::string s(10, 'a');        // "aaaaaaaaaa"
std::string s = s1 + s2;       // concatenation
std::string_view v = s;        // borrow view (no copy)

s.size();           // O(1)
s.empty();
s[i];               // O(1) — no bounds check, mutable
s.at(i);            // throws out_of_range
s.c_str();          // null-terminated C string (since C++11, always valid)
s.data();           // mutable char* (C++11)
s.append(" world");
s.substr(0, 5);     // "hello" — O(n) copy
s.find("world");    // O(n*m) naive; returns npos if not found
s.starts_with("h"); // C++20
```

SSO (Small String Optimization) — small strings stored inline, no heap allocation.

**See also →** `std::string_view`, `std::wstring`, `std::to_string`, `std::stoi`]],

  ["string_view"] = [[
**`std::string_view`** · Non-owning view of a string (`<string_view>`, C++17)

```cpp
#include <string_view>
std::string_view sv = "hello";  // no copy
sv.remove_prefix(1);            // "ello"
sv.remove_suffix(1);            // "ell"

void parse(std::string_view input);  // accept any string-like argument
```

**Never** null-terminated — using `.c_str()` or passing to a C API expecting null-terminated is UB. **Never** store a `string_view` to a temporary string — dangling reference.

**See also →** `std::string`, `std::string_view::substr` (returns `string_view`, O(1))]],

  ["map"] = [[
**`std::map`** · Ordered associative array (red-black tree) (`<map>`)

```cpp
#include <map>
std::map<std::string, int> m;

m["key"] = 42;       // insert or assign — O(log n)
m.insert({"k", 1});  // insert if not present — O(log n)
m.at("key");         // access — O(log n), throws out_of_range if missing
m.find("key");       // iterator or end() — O(log n)
m.contains("key");   // bool — C++20, O(log n)
m.erase("key");      // O(log n)
```

Iteration is in **sorted order** by key (default `std::less<Key>`). Iterators invalidate on erase (only the erased element).

**When to use:** need sorted iteration; O(log n) lookups/inserts; tree-based stability.]],

  ["set"] = [[
**`std::set`** · Ordered set of unique keys (`<set>`)

```cpp
#include <set>
std::set<int> s = {3, 1, 4, 1, 2};  // {1, 2, 3, 4}

s.insert(5);        // O(log n)
s.erase(3);         // O(log n)
s.contains(2);      // C++20, O(log n)
s.find(2);          // O(log n)
s.lower_bound(2);   // first element >= 2
s.upper_bound(2);   // first element > 2
```

Values are const — cannot modify an element in place (would break ordering). Implemented as red-black tree.

**See also →** `std::map`, `std::multiset`, `std::unordered_set`]],

  ["multiset"] = [[
**`std::multiset`** · Ordered set allowing duplicate keys (`<set>`)

```cpp
#include <set>
std::multiset<int> ms = {1, 1, 2, 3};

ms.insert(1);           // O(log n) — duplicates allowed
ms.count(1);            // number of 1s
ms.equal_range(1);      // pair of iterators spanning all 1s
ms.erase(1);            // erases ALL elements equal to 1!
ms.erase(ms.find(1));   // erases only one element
```

**See also →** `std::set`, `std::multimap`]],

  ["multimap"] = [[
**`std::multimap`** · Ordered map allowing duplicate keys (`<map>`)

```cpp
#include <map>
std::multimap<std::string, int> mm;
mm.insert({"k", 1});
mm.insert({"k", 2});   // both {"k", 1} and {"k", 2} stored

mm.equal_range("k");    // pair of iterators spanning all entries for "k"
mm.count("k");          // number of entries for key "k"
```

No `operator[]` — ambiguous with duplicate keys. Use `insert` and `equal_range`.

**See also →** `std::map`, `std::multiset`]],

  ["unordered_map"] = [[
**`std::unordered_map`** · Hash map (`<unordered_map>`, C++11)

```cpp
#include <unordered_map>
std::unordered_map<std::string, int> um;

um["key"] = 42;       // O(1) average, O(n) worst
um.insert({"k", 1});
um.find("key");       // O(1) average
um.contains("key");   // C++20
um.erase("key");      // O(1) average
```

Iteration order is **unspecified** (bucket order, not insertion order). Rehashing invalidates all iterators.

**When to use:** O(1) lookups and order doesn't matter. Provide a good hash for custom keys.

**See also →** `std::map`, `std::unordered_set`, `std::unordered_multimap`]],

  ["unordered_set"] = [[
**`std::unordered_set`** · Hash set (`<unordered_set>`, C++11)

```cpp
#include <unordered_set>
std::unordered_set<int> us = {3, 1, 4};

us.insert(2);       // O(1) average
us.contains(2);     // C++20, O(1) average
```

**See also →** `std::set`, `std::unordered_map`, `std::unordered_multiset`]],

  ["stack"] = [[
**`std::stack`** · LIFO container adaptor (`<stack>`)

```cpp
#include <stack>
std::stack<int> st;
st.push(1);      // push onto top
st.top();        // access top element
st.pop();        // remove top element (void — no return value)
st.size();
st.empty();
```

Adapts any sequence container with `back()`, `push_back()`, `pop_back()`. Default: `std::deque`.

**See also →** `std::queue`, `std::priority_queue`, `std::vector`]],

  ["queue"] = [[
**`std::queue`** · FIFO container adaptor (`<queue>`)

```cpp
#include <queue>
std::queue<int> q;
q.push(1);       // enqueue at back
q.front();       // oldest element
q.back();        // newest element
q.pop();         // dequeue from front (void — no return value)
```

Default underlying container: `std::deque`.

**See also →** `std::stack`, `std::priority_queue`]],

  ["priority_queue"] = [[
**`std::priority_queue`** · Max-heap container adaptor (`<queue>`)

```cpp
#include <queue>
std::priority_queue<int> pq;
pq.push(3);      // insert element — O(log n)
pq.push(1);
pq.push(5);
pq.top();        // largest element — 5 (O(1))
pq.pop();        // remove largest — O(log n)
```

Default ordering: `std::less<T>` → max-heap. For min-heap: `std::priority_queue<int, std::vector<int>, std::greater<int>>`.

**See also →** `std::make_heap`, `std::push_heap`, `std::pop_heap`, `std::queue`]],

  ["span"] = [[
**`std::span`** · Non-owning view of a contiguous sequence (`<span>`, C++20)

```cpp
#include <span>
std::span<int> s(vec);                    // from std::vector
std::span<int, 5> fs(arr);                // fixed extent (compile-time size)
std::span<const std::byte> bytes(obj);    // type-erased view

s.subspan(2, 5);     // view of elements [2, 7)
s.first(3);          // first 3 elements
s.last(3);           // last 3 elements
s.size();
s.data();            // pointer to contiguous storage
```

**Never** owns memory — like `string_view` but for any `T[]`. Bounds checking only with `at()` or `subspan(std::dynamic_extent)`.

**When to use:** function parameter type for contiguous sequences (replaces `(T* data, size_t len)` pairs).

**See also →** `std::string_view`, `std::array`, `std::mdspan` (C++23)]],
}
