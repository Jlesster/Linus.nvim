-- linus/keywords/c.lua

return {

  -- ── Control flow ──────────────────────────────────────────────────────────

  ["if"] = [[
**`if`** · Conditional branch

```c
if (condition) {
    // true branch
} else if (other) {
    // alternative
} else {
    // fallback
}
```

Condition is any scalar expression; **zero = false, non-zero = true**.
Applies to integers, pointers, and floats — there is no boolean type in C89/C90.
C99 added `_Bool` (`<stdbool.h>` exposes `bool`, `true`, `false`).

**Common pitfalls**
- `if (x = 0)` assigns instead of comparing — use `if (0 == x)` (Yoda) or enable `-Wparentheses`.
- Dangling `else` attaches to the nearest `if`; always use braces.]],

  ["for"] = [[
**`for`** · General-purpose loop

```c
for (init; condition; step) {
    body;
}

for (;;) { /* infinite */ }          // all clauses optional
for (int i = 0; i < n; i++) { }     // C99: declare loop variable inline
```

All three clauses are optional. `break` exits the loop; `continue` skips to the step.

**Idioms**
```c
// reverse iteration
for (int i = n - 1; i >= 0; i--) { }

// pointer walk
for (char *p = str; *p; p++) { }
```]],

  ["while"] = [[
**`while`** · Condition-first loop

```c
while (condition) {
    body;
}
```

Condition is evaluated before each iteration; if false initially, the body never runs.
Use `do…while` when the body must execute at least once.]],

  ["do"] = [[
**`do…while`** · Body-first loop

```c
do {
    body;
} while (condition);
```

Body executes **at least once** regardless of condition.
Commonly used for input validation loops and retry logic.

**Note:** the trailing semicolon after `while (condition)` is mandatory.]],

  ["switch"] = [[
**`switch`** · Integer multi-branch dispatch

```c
switch (expr) {
    case 1:
        doA();
        break;          // break required — prevents fall-through
    case 2:
    case 3:             // fall-through intentionally groups cases
        doBC();
        break;
    default:
        doElse();
}
```

`expr` must be an integer or enum type.

**Fall-through** is intentional when `break` is omitted — document with `/* fallthrough */`.
`default` is optional but recommended; it may appear anywhere in the case list.

**Pitfalls**
- Missing `break` silently falls through to the next case.
- Cannot declare variables inside `case` without a block `{ }`.]],

  ["break"] = [[
**`break`** · Exit innermost loop or switch

```c
for (...) {
    if (done) break;    // exits the for loop
}

switch (x) {
    case 1: ...; break; // exits the switch
}
```

Only exits **one** level. Use a flag or `goto` for nested loop exit.]],

  ["continue"] = [[
**`continue`** · Skip to next iteration

```c
for (int i = 0; i < n; i++) {
    if (skip[i]) continue;   // jumps to i++
    process(i);
}
```

In a `while` or `do…while`, jumps to the condition check.
In a `for`, jumps to the increment step.]],

  ["goto"] = [[
**`goto`** · Unconditional jump within a function

```c
if (err) goto cleanup;
// ...
cleanup:
    free(buf);
    fclose(f);
    return -1;
```

**Acceptable use:** centralised cleanup in C (the "goto cleanup" pattern) avoids deeply
nested `if` chains when multiple resources must be released on error.

**Avoid:** jumping forward over variable initialisations, or backwards to create loops.
Label scope is the enclosing function; cannot jump between functions.]],

  ["return"] = [[
**`return`** · Exit function with optional value

```c
return value;   // non-void function
return;         // void function

// common pattern: early exit on error
if (!ptr) return NULL;
```

For `main()`, `return 0` signals success to the OS; non-zero signals failure.
Equivalently, `exit(0)` / `exit(EXIT_FAILURE)` from `<stdlib.h>`.]],

  -- ── Types and declarations ─────────────────────────────────────────────────

  ["struct"] = [[
**`struct`** · Compound type grouping named fields

```c
struct Point { float x; float y; };

// typedef for convenience (no "struct" keyword needed at use sites)
typedef struct {
    float x;
    float y;
} Point;

Point p = { .x = 1.0f, .y = 2.0f };   // designated initialiser (C99)
p.x = 3.0f;                            // member access
Point *pp = &p;
pp->y = 4.0f;                          // pointer member access
```

Members are stored in declaration order with padding for alignment.
Use `offsetof` (`<stddef.h>`) to find member offsets.
Use `__attribute__((packed))` (GCC/Clang) to suppress padding.]],

  ["union"] = [[
**`union`** · Overlapping-storage variant type

```c
union Data {
    int   i;
    float f;
    char  bytes[4];
};

union Data d;
d.f = 3.14f;
// d.bytes now holds the raw IEEE-754 representation of 3.14f
```

Size = size of the **largest** member. Only one member is valid at a time.

**Uses**
- Type punning (read a float's bits as an int).
- Memory-efficient tagged variants (pair with an enum discriminant).

**C99 restriction:** writing one member and reading another is technically undefined behaviour
(though compilers widely support it); use `memcpy` for portable type punning.]],

  ["enum"] = [[
**`enum`** · Named integer constants

```c
enum Direction { NORTH, SOUTH, EAST, WEST };   // 0, 1, 2, 3

enum Flags {
    FLAG_A = 1,
    FLAG_B = 2,
    FLAG_C = 4,
    FLAG_D = 8,
};

enum Direction d = NORTH;
```

`enum` values are of type `int`. Underlying representation is implementation-defined.
Names are in the enclosing scope — no `Direction::` prefix needed (and not available).

**Pattern:** use `typedef enum { … } Name;` to avoid repeating `enum`.]],

  ["typedef"] = [[
**`typedef`** · Create a type alias

```c
typedef unsigned long ulong;
typedef struct Node { int val; struct Node *next; } Node;
typedef void (*Callback)(int event);    // function pointer type
typedef int Matrix[4][4];
```

Does **not** create a new type — just an alias. The underlying type is still accessible.

**Convention:** avoid `typedef` for structs in system/kernel code (Linux kernel style);
prefer it in library APIs to hide implementation details.]],

  ["void"] = [[
**`void`** · Absence of type

- **Return type** `void fn(…)` — function returns nothing; `return;` or fall off end.
- **Parameter list** `void fn(void)` — explicitly no parameters (vs `fn()` which in C means unspecified).
- **Generic pointer** `void *` — points to anything; must be cast before dereferencing.

```c
void  nothing(void);
void *memcpy(void *dst, const void *src, size_t n);
```

`void *` arithmetic is undefined behaviour in standard C (gcc extension allows it as `char *`).]],

  -- ── Storage classes and qualifiers ────────────────────────────────────────

  ["const"] = [[
**`const`** · Read-only qualifier

```c
const int SIZE = 128;            // read-only integer
const char *s  = "hello";        // pointer to const chars (string cannot be modified)
char *const p  = buf;            // const pointer (pointer address cannot change)
const char *const cp = "lit";    // const pointer to const chars
```

**Rule of thumb:** read right-to-left — "`p` is a const pointer to char".

`const` objects must be initialised at declaration.
Casting away `const` and then writing is undefined behaviour.

**Function parameters**
```c
void process(const char *input);  // signals: we won't modify what input points to
```]],

  ["static"] = [[
**`static`** · Two distinct meanings

**1. Local variable** — persists across function calls (stored in BSS/data, not stack).
```c
int counter(void) {
    static int count = 0;   // initialised once; survives between calls
    return ++count;
}
```

**2. File scope (function or variable)** — internal linkage; hidden from other translation units.
```c
static void helper(void) { }    // not visible outside this .c file
static int module_state = 0;
```

Use `static` functions aggressively to enforce module encapsulation.
Analogous to `private` in OOP languages.]],

  ["extern"] = [[
**`extern`** · Declare without defining

```c
// In header or .c file — declares that the definition lives elsewhere:
extern int global_count;
extern void helper(void);

// Definition (in exactly one .c file):
int global_count = 0;
```

Without `extern`, a file-scope variable declaration **is** a definition and allocates storage.
With `extern`, it is a declaration only — the linker resolves the reference.

**Common pattern:** declare `extern` variables in a header, define them in one `.c` file.

**`extern "C"`** in C++ headers wraps declarations to suppress name mangling:
```cpp
extern "C" { void c_function(void); }
```]],

  ["volatile"] = [[
**`volatile`** · Suppress optimisation on reads/writes

```c
volatile uint32_t *reg = (volatile uint32_t *)0x40000000;
*reg = 0x01;          // write will not be elided
uint32_t v = *reg;    // read will not be cached in a register
```

Tells the compiler every access to this object has observable side effects.

**Legitimate uses**
- Memory-mapped I/O registers.
- Variables modified by signal handlers (`sig_atomic_t`).
- Shared flags in single-threaded interrupt contexts.

**Not a substitute for atomics or mutexes** — `volatile` provides no memory ordering
guarantees across threads. Use `_Atomic` (C11) or `pthread` primitives instead.]],

  ["register"] = [[
**`register`** · Hint to store in a CPU register (obsolete)

```c
register int i;   // advisory only; compiler may ignore
```

Modern compilers perform register allocation far better than manual hints.
In C, the address of a `register` variable cannot be taken (`&i` is a compile error).
**Effectively deprecated** — removed as a meaningful hint in C++17, still valid in C.]],

  ["auto"] = [[
**`auto`** · Default storage class for local variables (implicit)

```c
auto int x = 5;   // same as `int x = 5;` — almost never written explicitly
```

All local (block-scope) variables are `auto` by default.
**Never written in practice** in C. (In C++11, `auto` was repurposed for type deduction.)]],

  -- ── Operators and expressions ─────────────────────────────────────────────

  ["sizeof"] = [[
**`sizeof`** · Compile-time size of a type or object

```c
sizeof(int)           // typically 4 on 32/64-bit platforms
sizeof(double)        // typically 8
sizeof(arr)           // total bytes of array — NOT pointer size
sizeof(*ptr)          // size of the pointed-to type
sizeof(struct Foo)    // includes padding bytes
```

Returns `size_t` (`<stddef.h>`). **Does not evaluate its operand at runtime.**

**Common mistake:**
```c
void fn(int arr[10]) {
    sizeof(arr);  // = sizeof(int*), NOT sizeof(int)*10 — array decays to pointer!
}
```

Use `sizeof(arr) / sizeof(arr[0])` for stack-allocated arrays in the same scope.]],

  ["inline"] = [[
**`inline`** · Suggest inlining at call sites

```c
static inline int max(int a, int b) {
    return a > b ? a : b;
}
```

Hint to the compiler to expand the function body at the call site to avoid function call overhead.
Modern compilers apply inlining based on their own heuristics regardless of this hint.

**`static inline`** is the idiomatic pattern for header-defined utility functions.
Without `static`, an `inline` function must have an `extern inline` definition in exactly one TU (C99).]],

  ["restrict"] = [[
**`restrict`** · Pointer aliasing assertion (C99)

```c
void add(float *restrict dst,
         const float *restrict a,
         const float *restrict b,
         int n);
```

Asserts that the memory region accessed through this pointer is **not accessed through any other
pointer** for the duration of its scope. Enables the compiler to assume no aliasing and generate
vectorised (SIMD) code.

**Violating `restrict` is undefined behaviour** — if `dst` and `a` overlap, the result is unpredictable.

Standard library uses it: `memcpy(void *restrict dst, const void *restrict src, …)`]],

  -- ── Memory management ─────────────────────────────────────────────────────

  ["malloc"] = [[
**`malloc`** · Allocate uninitialised heap memory (`<stdlib.h>`)

```c
void *ptr = malloc(n * sizeof(Type));
if (!ptr) {
    // allocation failed — ptr is NULL, not an exception
    return -ENOMEM;
}
free(ptr);
ptr = NULL;   // prevent use-after-free
```

Returned memory is **not zero-initialised** — use `calloc` for zeroed memory.
Pair every `malloc`/`calloc`/`realloc` with exactly one `free`.

**Alignment:** `malloc` returns memory aligned to `_Alignof(max_align_t)` (sufficient for any basic type).
For over-aligned types, use `aligned_alloc` (C11).]],

  ["free"] = [[
**`free`** · Release heap memory (`<stdlib.h>`)

```c
free(ptr);
ptr = NULL;   // good practice: makes double-free and use-after-free detectable
```

- `free(NULL)` is a no-op — safe to call unconditionally.
- **Double-free** is undefined behaviour (often causes heap corruption / security vuln).
- **Use-after-free** is undefined behaviour (set pointer to NULL after freeing).

Tools: **Valgrind**, **AddressSanitizer** (`-fsanitize=address`) detect both at runtime.]],

  ["calloc"] = [[
**`calloc`** · Allocate zero-initialised heap memory (`<stdlib.h>`)

```c
int *arr = calloc(n, sizeof(int));   // n elements, each sizeof(int) bytes, all zero
if (!arr) { /* handle */ }
free(arr);
```

Unlike `malloc`, the returned memory is **zero-filled**.
Checks for integer overflow in `n * size` (unlike manual `malloc(n * sizeof(T))`).]],

  ["realloc"] = [[
**`realloc`** · Resize a heap allocation (`<stdlib.h>`)

```c
// WRONG — leaks on failure:
ptr = realloc(ptr, new_size);

// CORRECT — save to temp first:
void *tmp = realloc(ptr, new_size);
if (!tmp) {
    // ptr still valid; handle error
    return -ENOMEM;
}
ptr = tmp;
```

- May return a **new address** — always use the returned pointer.
- `realloc(NULL, n)` is equivalent to `malloc(n)`.
- `realloc(ptr, 0)` behaviour is implementation-defined; use `free` explicitly.]],

  -- ── Preprocessor ─────────────────────────────────────────────────────────

  ["#define"] = [[
**`#define`** · Preprocessor macro definition

```c
// Object-like macro (constant)
#define BUFFER_SIZE 1024
#define PI 3.14159265358979

// Function-like macro (textual substitution — beware!)
#define MAX(a, b)  ((a) > (b) ? (a) : (b))
#define SQ(x)      ((x) * (x))

// Stringification and token pasting
#define STRINGIFY(x)  #x
#define CONCAT(a, b)  a##b
```

**Always parenthesise macro arguments** to avoid precedence bugs:
`MAX(2+1, 3)` → `((2+1) > (3) ? (2+1) : (3))` ✓

**Prefer over macros where possible:**
- `const` or `enum` for constants.
- `static inline` for function-like macros (type-safe, debuggable).]],

  ["#include"] = [[
**`#include`** · Insert file contents at this point

```c
#include <stdio.h>      // system header — searched in system include paths
#include "myheader.h"   // project header — searched relative to source file first
```

**Include guards** prevent multiple inclusion:
```c
#ifndef MY_HEADER_H
#define MY_HEADER_H
// ... header contents ...
#endif
```

Or use the non-standard but widely supported `#pragma once`.]],

  ["#ifdef"] = [[
**`#ifdef`** · Conditional compilation

```c
#ifdef DEBUG
    fprintf(stderr, "debug: val=%d\n", val);
#endif

#ifndef NDEBUG
    assert(ptr != NULL);
#endif

#if defined(__linux__) && defined(__x86_64__)
    // Linux x86-64 only
#endif
```

**Common uses**
- Debug builds (`DEBUG`, `NDEBUG`).
- Platform-specific code (`_WIN32`, `__APPLE__`, `__linux__`).
- Feature flags and header guards.

`#elif`, `#else`, `#endif` complete the conditional block.]],

  -- ── Special values ────────────────────────────────────────────────────────

  ["NULL"] = [[
**`NULL`** · Null pointer constant (`<stddef.h>` or `<stdlib.h>`)

Typically defined as `(void*)0` in C or `0` in C++.

```c
int *p = NULL;
if (p == NULL) { /* handle */ }
```

**Dereferencing NULL is undefined behaviour** — always check before use.
Good habit: set pointers to `NULL` after `free()` and after transferring ownership.

In C11+, prefer `_Null_unspecified` / `_Nonnull` annotations (Clang) to document pointer nullability.]],

  ["true"] = [[
**`true`** · Boolean true constant (`<stdbool.h>`, C99)

```c
#include <stdbool.h>
bool flag = true;   // equivalent to (_Bool)1
```

Without `<stdbool.h>`, use `1` directly. `true` expands to `1`.
Any non-zero integer value is "true" in a condition — `true` is just a named constant.]],

  ["false"] = [[
**`false`** · Boolean false constant (`<stdbool.h>`, C99)

```c
#include <stdbool.h>
bool done = false;   // equivalent to (_Bool)0
```

`false` expands to `0`. In conditions, zero = false for all scalar types.]],
}
