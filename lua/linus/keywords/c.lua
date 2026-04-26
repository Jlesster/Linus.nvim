-- jlesster/keywords/c.lua

return {
  ["if"] = [[
**`if`** — conditional branch.
```c
if (condition) {
    // true branch
} else if (other) {
    // alternative
} else {
    // fallback
}
```
Condition is any scalar expression; zero = false, non-zero = true.]],

  ["for"] = [[
**`for`** — general-purpose loop.
```c
for (init; condition; step) { body; }
for (;;) { /* infinite */ }
```
All three clauses are optional.]],

  ["while"] = [[
**`while`** — loop while condition is non-zero.
```c
while (condition) { body; }
```]],

  ["do"] = [[
**`do...while`** — body executes at least once; condition checked after.
```c
do { body; } while (condition);
```]],

  ["switch"] = [[
**`switch`** — integer/enum multi-branch dispatch.
```c
switch (expr) {
    case 1:
        doA();
        break;      // break required to prevent fall-through
    case 2:
        doB();
        break;
    default:
        doC();
}
```
Fall-through is intentional when `break` is omitted.]],

  ["struct"] = [[
**`struct`** — aggregates named members into a compound type.
```c
struct Point { float x; float y; };

// typedef for convenience
typedef struct { float x; float y; } Point;

Point p = { .x = 1.0f, .y = 2.0f };  // designated initialiser
p.x = 3.0f;
```
Members accessed with `.` (direct) or `->` (through pointer).]],

  ["union"] = [[
**`union`** — all members share the same memory location.
```c
union Data { int i; float f; char bytes[4]; };
```
Size = size of the largest member. Only one member is valid at a time.
Used for type punning and memory-efficient tagged variants.]],

  ["enum"] = [[
**`enum`** — named integer constants.
```c
enum Direction { NORTH, SOUTH, EAST, WEST };     // 0,1,2,3
enum Flags { A = 1, B = 2, C = 4, D = 8 };       // manual values
```
`enum` values are of type `int`.]],

  ["typedef"] = [[
**`typedef`** — creates an alias for a type.
```c
typedef unsigned long ulong;
typedef struct Node { int val; struct Node* next; } Node;
typedef void (*Callback)(int event);
```]],

  ["void"] = [[
**`void`** — absence of a type.
- Return type: function returns nothing.
- Parameter list: `void` means no parameters (vs empty `()` which is unspecified in C).
- `void*`: generic pointer; must be cast before dereferencing.]],

  ["const"] = [[
**`const`** — marks an object as read-only after initialisation.
```c
const int SIZE = 128;
const char* s = "hello";   // pointer to const char
char* const p = buf;       // const pointer to char
const char* const cp = s;  // const pointer to const char
```]],

  ["static"] = [[
**`static`** — has two distinct meanings:
- **Local variable**: persists across function calls (stored in BSS/data segment, not stack).
- **File scope (function/variable)**: limits linkage to the current translation unit (internal linkage).
```c
static int count = 0;   // survives across calls / hidden from other TUs
```]],

  ["extern"] = [[
**`extern`** — declares a variable or function defined in another translation unit.
```c
extern int global_count;   // declaration only; definition is elsewhere
extern void helper(void);
```
The linker resolves the reference at link time.]],

  ["volatile"] = [[
**`volatile`** — tells the compiler not to optimise away reads/writes.
Used for:
- Memory-mapped I/O registers.
- Variables modified by signal handlers or other threads (though not a substitute for atomics).
```c
volatile uint32_t* reg = (volatile uint32_t*)0x40000000;
```]],

  ["register"] = [[
**`register`** — hint (advisory only) to store a variable in a CPU register.
Modern compilers ignore this; the address of a `register` variable cannot be taken.
Effectively deprecated.]],

  ["auto"] = [[
**`auto`** — default storage class for local variables (stack-allocated).
Implicit; almost never written explicitly in modern C.]],

  ["sizeof"] = [[
**`sizeof`** — compile-time operator returning the size in bytes of a type or expression.
```c
sizeof(int)         // typically 4
sizeof(arr)         // total bytes of array (not pointer size!)
sizeof(*ptr)        // size of the pointed-to type
```
Returns `size_t`. Does not evaluate its operand at runtime.]],

  ["malloc"] = [[
**`malloc`** — allocates `n` bytes of uninitialised heap memory.
```c
void* ptr = malloc(n * sizeof(Type));
if (!ptr) { /* allocation failed */ }
free(ptr);
```
Pair every `malloc` / `calloc` / `realloc` with a `free`.]],

  ["free"] = [[
**`free`** — releases heap memory previously allocated by `malloc`/`calloc`/`realloc`.
```c
free(ptr);
ptr = NULL;  // good practice: prevents use-after-free
```
Double-free and use-after-free are undefined behaviour.]],

  ["calloc"] = [[
**`calloc`** — allocates `n * size` bytes of zero-initialised heap memory.
```c
int* arr = calloc(n, sizeof(int));
```]],

  ["realloc"] = [[
**`realloc`** — resizes a heap allocation.
```c
ptr = realloc(ptr, new_size);
// always assign to a temp first to avoid leaking on failure:
void* tmp = realloc(ptr, new_size);
if (tmp) ptr = tmp;
```]],

  ["NULL"] = [[
**`NULL`** — null pointer constant (typically `(void*)0` or `0`).
Dereferencing a null pointer is undefined behaviour.
Always initialise pointers to `NULL` and check before dereferencing.]],

  ["goto"] = [[
**`goto`** — unconditional jump to a label within the same function.
```c
if (err) goto cleanup;
// ...
cleanup:
    free(buf);
    return -1;
```
Acceptable use: centralised error-handling / cleanup in C (the "goto cleanup" pattern).]],

  ["inline"] = [[
**`inline`** — hint to the compiler to inline the function call site.
```c
static inline int max(int a, int b) { return a > b ? a : b; }
```
In C99+: `inline` function definitions in headers should be paired with `extern inline` in one TU.]],

  ["restrict"] = [[
**`restrict`** — pointer qualifier asserting no other pointer aliases the same memory (C99).
```c
void add(float* restrict dst, const float* restrict a, const float* restrict b, int n);
```
Enables vectorisation optimisations. Violating the contract is undefined behaviour.]],

  ["#define"] = [[
**`#define`** — preprocessor macro definition.
```c
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define BUFFER_SIZE 1024
```
Macros are textual substitution; always parenthesise arguments to avoid precedence bugs.
Prefer `const` / `static inline` / `enum` where possible.]],

  ["#include"] = [[
**`#include`** — inserts the contents of a file at this point.
```c
#include <stdio.h>     // system header (searched in system paths)
#include "myheader.h"  // project header (searched relative to source file first)
```]],

  ["#ifdef"] = [[
**`#ifdef`** — conditional compilation: includes code if macro is defined.
```c
#ifdef DEBUG
    printf("debug: %d\n", val);
#endif
```
Pair with `#ifndef`, `#else`, `#elif`, `#endif`.]],

  ["return"] = [[
**`return`** — exits the current function, optionally with a value.
```c
return value;   // for non-void functions
return;         // for void functions
```]],

  ["break"] = "**`break`** — exits the innermost `for`, `while`, `do`, or `switch`.",
  ["continue"] = "**`continue`** — skips to the next iteration of the innermost loop.",
}
