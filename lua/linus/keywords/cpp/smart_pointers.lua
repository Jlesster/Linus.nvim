-- linus/keywords/cpp/smart_pointers.lua

return {

  ["unique_ptr"] = [[
**`std::unique_ptr`** · Exclusive-ownership smart pointer (`<memory>`)

```cpp
#include <memory>
auto p = std::make_unique<Foo>(args);   // preferred (C++14)
std::unique_ptr<Foo> p(new Foo(args));

p->method();               // dereference
*p;                        // dereference to object
p.get();                   // raw pointer (no ownership transfer)
p.reset();                 // delete owned object
p.reset(new_ptr);          // replace owned object
auto raw = p.release();    // release ownership (caller must delete)
```

**Non-copyable** — only movable. No overhead vs raw pointer. When `p` goes out of scope, owned object is deleted.

**Custom deleter:** `std::unique_ptr<Foo, void(*)(Foo*)>` or `std::unique_ptr<Foo, Deleter>`.

**See also →** `std::make_unique`, `std::shared_ptr`, `std::weak_ptr`, `std::move`]],

  ["make_unique"] = [[
**`std::make_unique`** · Create a unique_ptr (`<memory>`, C++14)

```cpp
auto p = std::make_unique<Foo>(arg1, arg2);
auto arr = std::make_unique<Foo[]>(10);  // array form
```

**Prefer over `new`**: avoids manual `delete`, exception-safe (no leak if constructor throws), and deduplicates allocation.

**See also →** `std::unique_ptr`, `std::make_shared`, `std::allocate_shared`]],

  ["shared_ptr"] = [[
**`std::shared_ptr`** · Shared-ownership smart pointer (`<memory>`)

```cpp
#include <memory>
auto p = std::make_shared<Foo>(args);
std::shared_ptr<Foo> p(new Foo(args));

long count = p.use_count();      // reference count
p.unique();                      // use_count() == 1 (deprecated in C++17)
p.get();                         // raw pointer
p.reset();                       // decrement ref count, delete if last
```

Control block (ref count) is heap-allocated even by `make_shared`. Cyclic references never free — use `weak_ptr` to break cycles.

**See also →** `std::make_shared`, `std::weak_ptr`, `std::unique_ptr`, `std::enable_shared_from_this`]],

  ["make_shared"] = [[
**`std::make_shared`** · Create a shared_ptr (`<memory>`)

```cpp
auto p = std::make_shared<Foo>(arg1, arg2);
```

Single allocation for both the object and control block — more efficient than `shared_ptr<T>(new T(...))`. Exception-safe.

**See also →** `std::shared_ptr`, `std::make_unique`, `std::allocate_shared`]],

  ["weak_ptr"] = [[
**`std::weak_ptr`** · Non-owning observer of shared_ptr (`<memory>`)

```cpp
std::weak_ptr<Foo> wp = sp;       // observe a shared_ptr without owning

if (auto p = wp.lock()) {         // atomically check + get shared_ptr
    p->method();                  // object still alive
} else {
    // object was deleted
}

wp.expired();   // use_count() == 0 (not thread-safe by itself)
```

Breaks circular references. Does **not** affect reference count.

**See also →** `std::shared_ptr`, `std::enable_shared_from_this`]],

  ["enable_shared_from_this"] = [[
**`std::enable_shared_from_this`** · Safely create shared_ptr from `this` (`<memory>`)

```cpp
class Foo : public std::enable_shared_from_this<Foo> {
    std::shared_ptr<Foo> get_shared() {
        return shared_from_this();   // requires *this already managed by shared_ptr
    }
};
```

**Must** be used with `std::make_shared<Foo>` or `std::shared_ptr<Foo>(...)` — calling `shared_from_this()` on a raw `Foo*` or `std::unique_ptr` is undefined behaviour.

**See also →** `std::shared_ptr`, `std::weak_ptr`]],
}
