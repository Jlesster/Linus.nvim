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

  -- ── C Standard Library: I/O ────────────────────────────────────────────────

  ["printf"] = [[
**`printf`** · Print formatted output to stdout (`<stdio.h>`)

```c
int printf(const char *restrict format, ...);
```

Returns number of characters printed, or negative on error.

**Format specifiers:** `%d` (int), `%f` (double), `%s` (string), `%c` (char),
`%p` (pointer), `%zu` (size_t), `%x` (hex), `%e` (scientific).

**Pitfalls**
- Mismatched format/arg type is **undefined behaviour** — enable `-Wformat`.
- `%f` expects `double` (float is promoted to double in variadic args).
- `%s` expects a null-terminated string — passing a non-null-terminated char* is UB.
- `%n` writes to an `int*` — security risk; avoid.

**See also →** `fprintf`, `sprintf`, `snprintf`, `scanf`]],

  ["fprintf"] = [[
**`fprintf`** · Print formatted output to a file stream (`<stdio.h>`)

```c
int fprintf(FILE *restrict stream, const char *restrict format, ...);
```

Like `printf` but writes to `stream` (`stdout`, `stderr`, or a file opened with `fopen`).

```c
fprintf(stderr, "error: %s at line %d\n", msg, line);
```

Returns number of chars written, or negative on error.

**See also →** `printf`, `sprintf`, `snprintf`, `fscanf`]],

  ["sprintf"] = [[
**`sprintf`** · Print formatted output to a char buffer (`<stdio.h>`)

```c
int sprintf(char *restrict buf, const char *restrict format, ...);
```

Writes to `buf` (must be large enough). **Does not check buffer size** — the #1 source of buffer overflows in C. **Prefer `snprintf`.**

Returns number of chars written (excluding the null terminator).

**See also →** `snprintf`, `printf`, `fprintf`]],

  ["snprintf"] = [[
**`snprintf`** · Print formatted output with size limit (`<stdio.h>`)

```c
int snprintf(char *restrict buf, size_t n, const char *restrict format, ...);
```

Writes at most `n-1` chars to `buf`, always null-terminates. Returns the number of chars that **would have** been written if `n` were unlimited (excluding null terminator).

```c
char buf[64];
int n = snprintf(buf, sizeof buf, "%s x %d", name, count);
if (n >= (int)sizeof buf) { /* truncated */ }
```

**Always use `snprintf` over `sprintf`.** The return value ≥ `n` means truncation.

**See also →** `sprintf`, `printf`, `fprintf`]],

  ["scanf"] = [[
**`scanf`** · Read formatted input from stdin (`<stdio.h>`)

```c
int scanf(const char *restrict format, ...);
```

Returns number of input items successfully matched and assigned, or `EOF` on failure.

**Must pass pointers**, not values: `scanf("%d", &x)`.

**Format specifiers:** `%d` (int*), `%f` (float*), `%lf` (double*), `%s` (char*, skips leading whitespace), `%c` (char*, reads next char including whitespace).

**Pitfalls**
- `%s` has no bounds check — use `%Ns` (C99) or `fgets` to prevent buffer overflow.
- Mixing `%s`/`%d` with `%c` — `%c` reads the leftover newline. Add a space: `" %c"`.
- Input mismatch leaves the offending character in the stream; subsequent calls will fail too.
- Return value should **always** be checked.

**See also →** `fscanf`, `sscanf`, `fgets`]],

  ["fscanf"] = [[
**`fscanf`** · Read formatted input from a file stream (`<stdio.h>`)

```c
int fscanf(FILE *restrict stream, const char *restrict format, ...);
```

Like `scanf` but reads from `stream`. Returns number of items matched, or `EOF`.

**See also →** `scanf`, `sscanf`, `fgets`]],

  ["sscanf"] = [[
**`sscanf`** · Read formatted input from a string (`<stdio.h>`)

```c
int sscanf(const char *restrict s, const char *restrict format, ...);
```

Parses string `s` according to `format`. Returns number of items matched, or `EOF`.

Useful for parsing log lines, config files, etc. Be careful with `%s` — no bounds checking without field width.

**See also →** `scanf`, `fscanf`, `strtol`]],

  ["fopen"] = [[
**`fopen`** · Open a file (`<stdio.h>`)

```c
FILE *fopen(const char *restrict filename, const char *restrict mode);
```

Returns a `FILE*` or `NULL` on error (check `errno`).

**Modes:** `"r"` (read), `"w"` (write, truncate), `"a"` (append), `"rb"`/`"wb"` (binary). Add `+` for read+write: `"w+"`, `"r+"`, `"a+"`.

```c
FILE *f = fopen("data.txt", "r");
if (!f) { perror("fopen"); return -1; }
/* ... */
fclose(f);
```

**Always check the return value** and `fclose` the file when done. Unclosed files leak resources.

**See also →** `fclose`, `freopen`, `fread`, `fwrite`, `fseek`, `perror`]],

  ["fclose"] = [[
**`fclose`** · Close a file stream (`<stdio.h>`)

```c
int fclose(FILE *stream);
```

Flushes unwritten data and releases the file handle. Returns 0 on success, `EOF` on error.

Closing a `NULL` pointer is undefined behaviour — guard with `if (f)`. Double-close is UB.

**See also →** `fopen`, `freopen`, `fflush`]],

  ["fread"] = [[
**`fread`** · Read binary data from a file (`<stdio.h>`)

```c
size_t fread(void *restrict ptr, size_t size, size_t nmemb,
             FILE *restrict stream);
```

Reads `nmemb` elements of `size` bytes each into `ptr`. Returns the number of elements **successfully read** (may be less than `nmemb` — check with `feof`/`ferror`).

```c
size_t n = fread(buf, sizeof(int), 10, f);
if (n < 10) {
    if (feof(f)) /* hit EOF early */;
    if (ferror(f)) /* I/O error */;
}
```

**See also →** `fwrite`, `fopen`, `fclose`, `feof`, `ferror`]],

  ["fwrite"] = [[
**`fwrite`** · Write binary data to a file (`<stdio.h>`)

```c
size_t fwrite(const void *restrict ptr, size_t size, size_t nmemb,
              FILE *restrict stream);
```

Writes `nmemb` elements of `size` bytes from `ptr`. Returns number of elements written (may be less than `nmemb` on error).

```c
fwrite(arr, sizeof(int), n, f);
```

**See also →** `fread`, `fopen`, `fclose`, `fflush`]],

  ["fseek"] = [[
**`fseek`** · Set file position indicator (`<stdio.h>`)

```c
int fseek(FILE *stream, long offset, int whence);
```

`whence`: `SEEK_SET` (beginning), `SEEK_CUR` (current), `SEEK_END` (end). Returns 0 on success, non-zero on error.

```c
fseek(f, 0, SEEK_SET);   // rewind to beginning
fseek(f, -10, SEEK_END); // 10 bytes before end
```

For large files (>2GB), use `fseeko` (POSIX) or `_fseeki64` (Windows).

**See also →** `ftell`, `rewind`, `fgetpos`, `fsetpos`]],

  ["ftell"] = [[
**`ftell`** · Get current file position (`<stdio.h>`)

```c
long ftell(FILE *stream);
```

Returns the current byte offset from the beginning, or `-1L` on error. For large files, use `ftello` (POSIX).

**See also →** `fseek`, `rewind`, `fgetpos`]],

  ["rewind"] = [[
**`rewind`** · Reset file position to beginning (`<stdio.h>`)

```c
void rewind(FILE *stream);
```

Equivalent to `fseek(stream, 0, SEEK_SET); clearerr(stream);`. Clears both the EOF and error indicators.

**See also →** `fseek`, `ftell`, `clearerr`]],

  ["fgets"] = [[
**`fgets`** · Read a line from a file stream (`<stdio.h>`)

```c
char *fgets(char *restrict s, int n, FILE *restrict stream);
```

Reads at most `n-1` characters until newline or EOF. **Always null-terminates.** Returns `s` on success, `NULL` on error or EOF (with no chars read).

```c
char buf[256];
while (fgets(buf, sizeof buf, stdin)) {
    buf[strcspn(buf, "\n")] = '\0';  // trim trailing newline
    process(buf);
}
```

**Preferred over `gets`** (which was removed in C11) — `fgets` is bounds-safe.

**See also →** `fputs`, `getchar`, `scanf`]],

  ["fputs"] = [[
**`fputs`** · Write a string to a file stream (`<stdio.h>`)

```c
int fputs(const char *restrict s, FILE *restrict stream);
```

Writes the null-terminated string `s` (without the null terminator). Does **not** append a newline. Returns non-negative on success, `EOF` on error.

**See also →** `fgets`, `puts`, `printf`]],

  ["getchar"] = [[
**`getchar`** · Read a single character from stdin (`<stdio.h>`)

```c
int getchar(void);
```

Returns the character as an `unsigned char` cast to `int`, or `EOF` on error/end-of-file.

```c
int c;
while ((c = getchar()) != EOF) {
    putchar(c);
}
```

Note: `c` must be `int`, not `char`, to distinguish `EOF` from valid character values.

**See also →** `putchar`, `fgets`, `getc`, `ungetc`]],

  ["putchar"] = [[
**`putchar`** · Write a single character to stdout (`<stdio.h>`)

```c
int putchar(int c);
```

Writes `c` (converted to `unsigned char`). Returns the character written or `EOF` on error.

**See also →** `getchar`, `puts`, `fputc`, `printf`]],

  ["feof"] = [[
**`feof`** · Test end-of-file indicator (`<stdio.h>`)

```c
int feof(FILE *stream);
```

Returns non-zero if the EOF indicator is set on `stream`. Only becomes true **after** a read operation reaches the end — not before.

```c
while (!feof(f)) {     // WRONG — loops one extra time
    fgets(buf, sizeof buf, f);
}

while (fgets(buf, sizeof buf, f)) { }  // CORRECT
```

**See also →** `ferror`, `clearerr`, `fread`]],

  ["ferror"] = [[
**`ferror`** · Test file error indicator (`<stdio.h>`)

```c
int ferror(FILE *stream);
```

Returns non-zero if an error occurred on `stream`. Once set, persists until `clearerr` or `rewind` is called.

**See also →** `feof`, `clearerr`, `perror`]],

  ["perror"] = [[
**`perror`** · Print `errno`-based error message to stderr (`<stdio.h>`)

```c
void perror(const char *s);
```

Prints `s: error message\n` to stderr using the current value of `errno`. Should be called **immediately** after the failed call, before any other operation changes `errno`.

```c
FILE *f = fopen("file", "r");
if (!f) { perror("fopen"); return; }
```

**See also →** `ferror`, `strerror`, `errno`]],

  ["FILE"] = [[
**`FILE`** · Stream type representing an open file (`<stdio.h>`)

Opaque type. Never copy a `FILE*` — use the pointer returned by `fopen`. All I/O functions take a `FILE*`.

**Pre-defined streams:** `stdin`, `stdout`, `stderr` (available without `fopen`).

**See also →** `fopen`, `fclose`, `stdin`, `stdout`, `stderr`]],

  ["stdin"] = [[
**`stdin`** · Standard input stream (`<stdio.h>`)

A `FILE*` connected to the process's standard input (typically keyboard or pipe). Used by `scanf`, `fgets`, `getchar`, etc.

**See also →** `stdout`, `stderr`, `FILE`, `fopen`]],  -- note: "stderr" is intentionally last here

  ["stdout"] = [[
**`stdout`** · Standard output stream (`<stdio.h>`)

A `FILE*` connected to the process's standard output (typically terminal or pipe). Used by `printf`, `fputs`, `putchar`, etc. Usually line-buffered.

**See also →** `stdin`, `stderr`, `FILE`]],

  ["stderr"] = [[
**`stderr`** · Standard error stream (`<stdio.h>`)

A `FILE*` connected to the process's standard error output. **Unbuffered** by default — output appears immediately. Used for error messages and diagnostics.

```c
fprintf(stderr, "error at line %d\n", line);
```

**See also →** `stdin`, `stdout`, `perror`, `FILE`]],

  ["EOF"] = [[
**`EOF`** · End-of-file / error indicator (`<stdio.h>`)

A negative integer constant (typically -1) returned by I/O functions to indicate end-of-file or error. Its value is distinct from any valid `unsigned char`.

```c
int c;  // must be int, not char
while ((c = getchar()) != EOF) { }
```

**See also →** `feof`, `ferror`, `getchar`]],

  ["ungetc"] = [[
**`ungetc`** · Push a character back onto a stream (`<stdio.h>`)

```c
int ungetc(int c, FILE *stream);
```

Pushes `c` (converted to `unsigned char`) back so the next read returns it. Only **one** character of pushback is guaranteed. Returns `c` on success, `EOF` on failure.

Useful for look-ahead parsing: read the next char, check if it's valid, push it back if not.

**See also →** `getchar`, `fgetc`, `fread`]],

  -- ── C Standard Library: General Utility ─────────────────────────────────────

  ["exit"] = [[
**`exit`** · Terminate the program normally (`<stdlib.h>`)

```c
void exit(int status);
```

Calls all functions registered via `atexit`, flushes all `stdio` streams, closes all files, then terminates the process. Returns `status` to the operating system: `0` / `EXIT_SUCCESS` for success, `EXIT_FAILURE` for failure. `exit` does **not** call destructors of local objects (C++).

**Does not return.** Use `return` from `main` instead when possible (equivalent).

**See also →** `atexit`, `abort`, `quick_exit`, `_Exit`, `EXIT_SUCCESS`, `EXIT_FAILURE`]],

  ["atexit"] = [[
**`atexit`** · Register a function to be called on normal termination (`<stdlib.h>`)

```c
int atexit(void (*func)(void));
```

Registers `func` to be called (in reverse registration order) when `exit` is called or `main` returns. Returns 0 on success, non-zero on failure. At least 32 registrations are guaranteed.

**See also →** `exit`, `abort`, `at_quick_exit`]],

  ["abort"] = [[
**`abort`** · Terminate the program abnormally (`<stdlib.h>`)

```c
void abort(void);
```

Sends `SIGABRT` to the calling process. If the signal is caught and the handler returns, `abort` still terminates the process (via `_Exit`). Flushes `stdio` streams but does **not** call `atexit` handlers. Raises `SIGABRT` which typically produces a core dump.

**See also →** `exit`, `atexit`, `raise`, `signal`]],

  ["getenv"] = [[
**`getenv`** · Get an environment variable (`<stdlib.h>`)

```c
char *getenv(const char *name);
```

Returns a pointer to the value of the environment variable `name`, or `NULL` if not found. The returned string should **not** be modified by the caller.

```c
char *home = getenv("HOME");
if (!home) { /* no HOME set */ }
```

**Not thread-safe** — the environment can be modified by `setenv`/`putenv` concurrently.

**See also →** `system`, `exit`]],

  ["system"] = [[
**`system`** · Execute a shell command (`<stdlib.h>`)

```c
int system(const char *command);
```

Passes `command` to the host environment's command processor (`/bin/sh` on POSIX, `cmd.exe` on Windows). Returns the command's exit status (implementation-defined). If `command` is `NULL`, returns non-zero if a command processor is available.

```c
system("ls -la > listing.txt");
```

**Security:** Never pass unsanitized user input to `system` — shell injection risk. Use `fork`/`exec` (POSIX) or `popen` for more control.

**See also →** `getenv`, `exit`, `popen`]],

  ["rand"] = [[
**`rand`** · Pseudo-random integer (`<stdlib.h>`)

```c
int rand(void);
```

Returns a pseudo-random integer in the range [0, `RAND_MAX`] (at least 32767). The sequence is deterministic based on the seed set by `srand`.

```c
srand((unsigned)time(NULL));
int r = rand() % 100;   // 0-99 (slightly biased — ok for casual use)
```

**Not for cryptography, simulation, or anything security-sensitive.** The quality is implementation-defined (often a simple LCG). Use OS-provided randomness or `<stdint.h>`-based generators for serious work.

**See also →** `srand`, `random` (POSIX), `rand48` family]],

  ["srand"] = [[
**`srand`** · Seed the pseudo-random number generator (`<stdlib.h>`)

```c
void srand(unsigned seed);
```

Initializes the `rand()` PRNG with `seed`. Same seed = same sequence — useful for reproducible tests.

```c
srand((unsigned)time(NULL));   // typical — but predictable if attacker knows the time
```

**See also →** `rand`, `time`]],

  ["atoi"] = [[
**`atoi`** · Convert string to integer (`<stdlib.h>`)

```c
int atoi(const char *str);
```

Parses `str` as a decimal integer. Returns 0 on error (but 0 is also a valid result — **cannot distinguish**). No error reporting. **Prefer `strtol`** which detects errors.

```c
// Fragile:
int val = atoi("42abc");  // returns 42 (silently ignores trailing "abc")

// Robust:
char *end;
long val = strtol("42abc", &end, 10);
if (*end != '\0') { /* parse error or trailing chars */ }
```

**See also →** `atol`, `atoll`, `strtol`, `strtoul`, `strtod`]],

  ["strtol"] = [[
**`strtol`** · Convert string to long integer with error detection (`<stdlib.h>`)

```c
long strtol(const char *restrict str, char **restrict endptr, int base);
```

`base`: 0 (auto-detect: octal `0`, hex `0x`, decimal), 2–36. Sets `*endptr` to the first unparsed character. Sets `errno` to `ERANGE` on overflow/underflow.

```c
char *end;
errno = 0;
long val = strtol(s, &end, 10);
if (errno == ERANGE) { /* overflow */ }
if (end == s) { /* no digits found */ }
if (*end != '\0') { /* trailing characters */ }
```

**See also →** `strtoul`, `strtoll`, `strtod`, `atoi`]],

  ["strtod"] = [[
**`strtod`** · Convert string to double (`<stdlib.h>`)

```c
double strtod(const char *restrict str, char **restrict endptr);
```

Parses decimal, hex (0x), infinity, NaN. Same error detection pattern as `strtol` via `errno` and `endptr`.

```c
char *end;
errno = 0;
double val = strtod("3.14e0", &end);
```

**See also →** `strtof`, `strtold`, `strtol`, `atoi`]],

  ["qsort"] = [[
**`qsort`** · Sort an array (`<stdlib.h>`)

```c
void qsort(void *base, size_t nmemb, size_t size,
           int (*compar)(const void *, const void *));
```

Sorts `nmemb` elements of `size` bytes each using quicksort (not guaranteed to be stable).

```c
int cmp(const void *a, const void *b) {
    return *(int*)a - *(int*)b;            // ascending
    // return (*(int*)a > *(int)*b) - (*(int*)a < *(int*)b);  // overflow-safe
}

qsort(arr, n, sizeof(int), cmp);
```

**Comparator must return** negative (a < b), zero (a == b), or positive (a > b). **Do not** use subtraction for `int` values — overflow risk; use explicit comparisons instead.

**See also →** `bsearch`, `qsort_s` (C11, Annex K)]],

  ["bsearch"] = [[
**`bsearch`** · Binary search on a sorted array (`<stdlib.h>`)

```c
void *bsearch(const void *key, const void *base, size_t nmemb, size_t size,
              int (*compar)(const void *, const void *));
```

Returns pointer to a matching element, or `NULL`. The array **must** be sorted in ascending order per `compar`. If multiple elements match, which one is returned is unspecified.

**See also →** `qsort`, `lfind`, `lsearch` (POSIX)]],

  ["abs"] = [[
**`abs`** · Absolute value of an integer (`<stdlib.h>`)

```c
int abs(int n);
```

Returns the absolute value. **Pitfall:** `abs(INT_MIN)` is undefined behaviour on two's complement systems (`INT_MIN = -2147483648` but `2147483648 > INT_MAX`). Use a safe wrapper or check for `INT_MIN` before calling.

**See also →** `labs`, `llabs`, `fabs` (for `double`)]],

  ["div"] = [[
**`div`** · Integer division with remainder (`<stdlib.h>`)

```c
div_t div(int numer, int denom);
```

Returns a struct with `quot` (quotient) and `rem` (remainder). The quotient is truncated toward zero (same as `/` in C99+). `div_t`, `ldiv_t`, `lldiv_t` for `long`/`long long`.

```c
div_t r = div(10, 3);
// r.quot = 3, r.rem = 1
```

**See also →** `ldiv`, `lldiv`, `abs`]],

  -- ── C Standard Library: String Manipulation ─────────────────────────────────

  ["memcpy"] = [[
**`memcpy`** · Copy memory (`<string.h>`)

```c
void *memcpy(void *restrict dest, const void *restrict src, size_t n);
```

Copies `n` bytes from `src` to `dest`. **Undefined if source and destination overlap** — use `memmove` for overlapping regions. `restrict` means the compiler can assume no overlap and generate faster code.

```c
memcpy(buf, data, sizeof(data));
```

Returns `dest`. Often the fastest copy — may use SIMD/`rep movsb`.

**See also →** `memmove`, `memset`, `memcmp`, `strcpy`, `strncpy`]],

  ["memmove"] = [[
**`memmove`** · Copy memory, safe for overlapping regions (`<string.h>`)

```c
void *memmove(void *dest, const void *src, size_t n);
```

Like `memcpy` but guarantees correct behaviour even when `dest` and `src` overlap. May be slightly slower than `memcpy`.

```c
memmove(dst, src, 1024);   // safe even if dst and src overlap
```

**See also →** `memcpy`, `memset`, `memcmp`]],

  ["memset"] = [[
**`memset`** · Fill memory with a byte value (`<string.h>`)

```c
void *memset(void *s, int c, size_t n);
```

Sets the first `n` bytes of `s` to `c` (converted to `unsigned char`). Returns `s`.

```c
memset(buf, 0, sizeof buf);           // zero a buffer
memset(arr, 0, n * sizeof(int));      // zero an array
```

**Pitfall:** Passing `1` instead of `0` does **not** set each byte to `1` — it sets each byte to `0x01`, not `0x01010101`. For non-byte types, use explicit loops.

**See also →** `memcpy`, `memmove`, `bzero` (deprecated), `explicit_bzero` (secure zero)]],

  ["memcmp"] = [[
**`memcmp`** · Compare memory (`<string.h>`)

```c
int memcmp(const void *s1, const void *s2, size_t n);
```

Compares the first `n` bytes. Returns negative if `s1 < s2`, zero if equal, positive if `s1 > s2` (byte-by-byte as `unsigned char`).

**Timing side-channel:** Not constant-time — **do not use** for cryptographic comparison. Use a constant-time comparison for secrets.

**See also →** `memcpy`, `memset`, `strcmp`, `strncmp`]],

  ["memchr"] = [[
**`memchr`** · Find a byte in memory (`<string.h>`)

```c
void *memchr(const void *s, int c, size_t n);
```

Returns a pointer to the first occurrence of `c` (as `unsigned char`) in the first `n` bytes of `s`, or `NULL` if not found.

**See also →** `strchr`, `strrchr`, `strstr`, `memcmp`]],

  ["strcpy"] = [[
**`strcpy`** · Copy string (`<string.h>`)

```c
char *strcpy(char *restrict dest, const char *restrict src);
```

Copies `src` (including null terminator) to `dest`. **No bounds check** — buffer overflow if `dest` is too small. **Prefer `strncpy` or `snprintf`.**

Returns `dest`.

**See also →** `strncpy`, `memcpy`, `snprintf`, `strcat`]],

  ["strncpy"] = [[
**`strncpy`** · Bounded string copy (`<string.h>`)

```c
char *strncpy(char *restrict dest, const char *restrict src, size_t n);
```

Copies at most `n` characters from `src` to `dest`. **If `src` is shorter than `n`**, pads the remainder with null bytes. **If `src` is ≥ `n`**, does **not** null-terminate `dest`.

```c
char buf[64];
strncpy(buf, src, sizeof buf);
buf[sizeof buf - 1] = '\0';  // force null-termination — essential
```

**Not a safe version of `strcpy`** — the no-null-termination edge case is a common source of bugs. Consider `snprintf(dest, n, "%s", src)` as an alternative.

**See also →** `strcpy`, `memcpy`, `snprintf`]],

  ["strcat"] = [[
**`strcat`** · Concatenate strings (`<string.h>`)

```c
char *strcat(char *restrict dest, const char *restrict src);
```

Appends a copy of `src` to the end of `dest`, overwriting `dest`'s null terminator. **No bounds check** — buffer overflow risk. Returns `dest`.

**Prefer** `snprintf(dest + strlen(dest), n - strlen(dest), "%s", src)` or `strlcat` (BSD/POSIX).

**See also →** `strncat`, `strcpy`, `snprintf`]],

  ["strncat"] = [[
**`strncat`** · Bounded string concatenation (`<string.h>`)

```c
char *strncat(char *restrict dest, const char *restrict src, size_t n);
```

Appends at most `n` characters from `src` to `dest`. **Always null-terminates** (unlike `strncpy`). The `n` parameter is the max number of characters to *copy*, not the buffer size.

```c
strncat(buf, src, sizeof buf - strlen(buf) - 1);
```

**See also →** `strcat`, `strncpy`, `snprintf`]],

  ["strcmp"] = [[
**`strcmp`** · Compare strings (`<string.h>`)

```c
int strcmp(const char *s1, const char *s2);
```

Lexicographic comparison using `unsigned char` values. Returns negative if `s1 < s2`, zero if equal, positive if `s1 > s2`.

```c
if (strcmp(input, "quit") == 0) { /* exact match */ }
```

**See also →** `strncmp`, `strcoll`, `memcmp`, `strcasecmp` (POSIX)]],

  ["strncmp"] = [[
**`strncmp`** · Bounded string comparison (`<string.h>`)

```c
int strncmp(const char *s1, const char *s2, size_t n);
```

Like `strcmp` but compares at most `n` characters. Useful for prefix checks:

```c
if (strncmp(str, "https://", 8) == 0) { /* starts with https */ }
```

**See also →** `strcmp`, `memcmp`, `strcoll`]],

  ["strchr"] = [[
**`strchr`** · Find first occurrence of character in string (`<string.h>`)

```c
char *strchr(const char *s, int c);
```

Returns pointer to the first occurrence of `c` (as `char`) in `s`, or `NULL`. The null terminator is considered part of the string — `strchr(s, '\0')` returns a pointer to the end.

```c
char *p = strchr(line, ':');
if (p) { *p = '\0'; /* split at colon */ }
```

**See also →** `strrchr`, `strstr`, `memchr`, `strpbrk`]],

  ["strrchr"] = [[
**`strrchr`** · Find last occurrence of character in string (`<string.h>`)

```c
char *strrchr(const char *s, int c);
```

Like `strchr` but returns a pointer to the **last** occurrence. Useful for extracting file extensions:

```c
char *dot = strrchr(filename, '.');
if (dot) { /* extension: dot + 1 */ }
```

**See also →** `strchr`, `strstr`, `memchr`]],

  ["strstr"] = [[
**`strstr`** · Find substring (`<string.h>`)

```c
char *strstr(const char *haystack, const char *needle);
```

Returns pointer to the first occurrence of `needle` in `haystack`, or `NULL`. Does **not** search the null terminator.

```c
char *found = strstr(log_line, "ERROR");
if (found) { /* error found at position: found - log_line */ }
```

**See also →** `strchr`, `strrchr`, `memmem` (GNU/BSD), `strpbrk`]],

  ["strtok"] = [[
**`strtok`** · Tokenise a string (`<string.h>`)

```c
char *strtok(char *restrict str, const char *restrict delim);
```

Splits `str` into tokens separated by characters in `delim`. **Modifies the input string** (overwrites delimiters with `\0`). **Not thread-safe** — uses internal static state. Use `strtok_r` (POSIX) for reentrancy.

```c
char s[] = "a,b,c";
char *tok = strtok(s, ",");
while (tok) {
    printf("%s\n", tok);
    tok = strtok(NULL, ",");
}
```

First call: pass the string. Subsequent calls: pass `NULL`. Returning `NULL` means no more tokens.

**See also →** `strtok_r` (POSIX), `strspn`, `strcspn`, `strpbrk`]],

  ["strlen"] = [[
**`strlen`** · Get string length (`<string.h>`)

```c
size_t strlen(const char *s);
```

Returns the number of characters before the null terminator. **O(n)** — scans the string. **Never call on a non-null-terminated string** (undefined behaviour).

```c
size_t len = strlen(str);
if (len >= sizeof buf) { /* buffer would be too small */ }
```

Returns `size_t` — be careful with signed/unsigned comparisons: `strlen(s) > (size_t)-1` is always true.

**See also →** `strnlen` (POSIX), `sizeof`, `memcpy`]],

  ["strerror"] = [[
**`strerror`** · Get error message string for errno value (`<string.h>`)

```c
char *strerror(int errnum);
```

Returns a string describing the error code `errnum`. The string should not be modified.

```c
FILE *f = fopen("file", "r");
if (!f) {
    fprintf(stderr, "fopen: %s\n", strerror(errno));
}
```

**Not thread-safe** in C99 (uses internal static buffer). The POSIX `strerror_r` or C11 `strerror_s` are thread-safe alternatives.

**See also →** `perror`, `errno`]],

  -- ── C Standard Library: Character Handling ─────────────────────────────────

  ["isalpha"] = [[
**`isalpha`** · Check if character is alphabetic (`<ctype.h>`)

```c
int isalpha(int c);
```

Returns non-zero if `c` is an alphabetic letter (`A-Z`, `a-z`). `c` must be representable as `unsigned char` or `EOF` — passing a negative value other than `EOF` is undefined behaviour.

**See also →** `isdigit`, `isalnum`, `islower`, `isupper`, `tolower`]],

  ["isdigit"] = [[
**`isdigit`** · Check if character is a decimal digit (`<ctype.h>`)

```c
int isdigit(int c);
```

Returns non-zero for `0`–`9`. Unlike `isxdigit`, only matches decimal digits.

**See also →** `isalpha`, `isalnum`, `isxdigit`]],

  ["isalnum"] = [[
**`isalnum`** · Check if character is alphanumeric (`<ctype.h>`)

```c
int isalnum(int c);
```

Returns non-zero for `A-Z`, `a-z`, `0-9`. Equivalent to `isalpha(c) || isdigit(c)`.

**See also →** `isalpha`, `isdigit`, `isxdigit`, `ispunct`]],

  ["isspace"] = [[
**`isspace`** · Check if character is whitespace (`<ctype.h>`)

```c
int isspace(int c);
```

Returns non-zero for: `' '` (space), `'\f'` (form feed), `'\n'` (newline), `'\r'` (carriage return), `'\t'` (horizontal tab), `'\v'` (vertical tab).

**Notable non-whitespace:** `'\b'` (backspace) is not whitespace per the C standard.

**See also →** `isblank`, `isalpha`, `isdigit`]],

  ["tolower"] = [[
**`tolower`** · Convert character to lowercase (`<ctype.h>`)

```c
int tolower(int c);
```

If `c` is an uppercase letter, returns the corresponding lowercase letter. Otherwise returns `c` unchanged.

```c
tolower('A')  // 'a'
tolower('z')  // 'z' (already lowercase)
tolower('3')  // '3' (not a letter)
```

**See also →** `toupper`, `isalpha`, `islower`, `isupper`]],

  ["toupper"] = [[
**`toupper`** · Convert character to uppercase (`<ctype.h>`)

```c
int toupper(int c);
```

If `c` is a lowercase letter, returns the corresponding uppercase letter. Otherwise returns `c` unchanged.

**See also →** `tolower`, `isalpha`, `isupper`]],

  -- ── C Standard Library: Math ────────────────────────────────────────────────

  ["sqrt"] = [[
**`sqrt`** · Compute square root (`<math.h>`)

```c
double sqrt(double x);
```

Returns the square root of `x`. If `x` is negative, a domain error occurs (`errno = EDOM`, returns `NaN`).

```c
double len = sqrt(x*x + y*y);  // prefer hypot(x, y) for large values
```

**See also →** `cbrt`, `hypot`, `pow`, `fabs`]],

  ["pow"] = [[
**`pow`** · Compute power (`<math.h>`)

```c
double pow(double x, double y);
```

Returns `x` raised to the power `y`. Domain error if `x` is finite negative and `y` is not an integer.

```c
pow(2.0, 10.0)    // 1024.0
pow(4.0, 0.5)     // 2.0  (sqrt via pow)
```

**Prefer integer arithmetic** for small integer powers — `x * x` is faster and more precise than `pow(x, 2)`.

**See also →** `sqrt`, `exp`, `log`, `fabs`]],

  ["exp"] = [[
**`exp`** · Compute exponential (`<math.h>`)

```c
double exp(double x);
```

Returns Euler's number *e* raised to `x`. Sets `errno = ERANGE` on overflow.

```c
double e1 = exp(1.0);   // 2.71828...
double e2 = exp(2.0);   // 7.389...
```

**See also →** `exp2`, `expm1`, `log`, `pow`]],

  ["log"] = [[
**`log`** · Compute natural logarithm (`<math.h>`)

```c
double log(double x);
```

Returns the natural (base *e*) logarithm of `x`. Domain error if `x < 0`. Pole error if `x = 0`.

```c
double ln = log(10.0);     // ~2.30258
```

**See also →** `log2`, `log10`, `log1p`, `exp`, `pow`]],

  ["log2"] = [[
**`log2`** · Compute base-2 logarithm (`<math.h>`)

```c
double log2(double x);
```

Returns the binary logarithm. Useful for bit calculations and algorithm analysis.

**See also →** `log`, `log10`, `exp2`]],

  ["log10"] = [[
**`log10`** · Compute base-10 logarithm (`<math.h>`)

```c
double log10(double x);
```

**See also →** `log`, `log2`, `pow`]],

  ["floor"] = [[
**`floor`** · Round down to nearest integer (`<math.h>`)

```c
double floor(double x);
```

Returns the largest integer value ≤ `x`. `floor(2.7)` = 2.0, `floor(-2.7)` = -3.0.

**See also →** `ceil`, `round`, `trunc`, `fmod`]],

  ["ceil"] = [[
**`ceil`** · Round up to nearest integer (`<math.h>`)

```c
double ceil(double x);
```

Returns the smallest integer value ≥ `x`. `ceil(2.3)` = 3.0, `ceil(-2.3)` = -2.0.

**See also →** `floor`, `round`, `trunc`, `fmod`]],

  ["round"] = [[
**`round`** · Round to nearest integer, halfway away from zero (`<math.h>`)

```c
double round(double x);
```

`round(2.5)` = 3.0, `round(2.4)` = 2.0, `round(-2.5)` = -3.0. Unlike `floor`/`ceil`, rounds to the nearest integer with .5 rounding away from zero.

**See also →** `floor`, `ceil`, `trunc`, `lround`, `llround`]],

  ["trunc"] = [[
**`trunc`** · Truncate toward zero (`<math.h>`)

```c
double trunc(double x);
```

Removes the fractional part. `trunc(2.7)` = 2.0, `trunc(-2.7)` = -2.0.

**See also →** `floor`, `ceil`, `round`]],

  ["fabs"] = [[
**`fabs`** · Absolute value of a floating-point number (`<math.h>`)

```c
double fabs(double x);
```

Returns `|x|`. Always well-defined for floating-point (unlike integer `abs()` for `INT_MIN`).

```c
fabs(-3.14)   // 3.14
fabs(INFINITY) // INFINITY
```

**See also →** `abs`, `fmax`, `fmin`, `copysign`]],

  ["fmod"] = [[
**`fmod`** · Floating-point remainder (`<math.h>`)

```c
double fmod(double x, double y);
```

Returns `x - n*y` where `n = trunc(x / y)`. Result has the same sign as `x`.

```c
fmod(5.3, 2.0)   // 1.3
```

Not the same as `%` remainder — `remainder` rounds toward the nearest integer.

**See also →** `remainder`, `fabs`, `modf`]],

  ["fmax"] = [[
**`fmax`** · Maximum of two floating-point values (`<math.h>`)

```c
double fmax(double x, double y);
```

Returns the larger value. If one argument is `NaN`, returns the other.

**See also →** `fmin`, `fabs`, `fdim`]],

  ["fmin"] = [[
**`fmin`** · Minimum of two floating-point values (`<math.h>`)

```c
double fmin(double x, double y);
```

Returns the smaller value. If one argument is `NaN`, returns the other.

**See also →** `fmax`, `fabs`, `fdim`]],

  ["hypot"] = [[
**`hypot`** · Compute Euclidean distance (`<math.h>`)

```c
double hypot(double x, double y);
```

Returns `sqrt(x*x + y*y)` without unnecessary overflow or underflow. **Prefer over `sqrt(x*x + y*y)`** for large values that may overflow intermediate computation.

**See also →** `sqrt`, `fabs`, `pow`]],

  ["sin"] = [[
**`sin`** · Compute sine (`<math.h>`)

```c
double sin(double x);
```

Returns the sine of `x` (radians). Domain: all real numbers (valid result for any finite `x`).

```c
double s = sin(3.14159265 / 2.0);   // ~1.0
```

**See also →** `cos`, `tan`, `asin`, `acos`, `atan2`]],

  ["cos"] = [[
**`cos`** · Compute cosine (`<math.h>`)

```c
double cos(double x);
```

Returns the cosine of `x` (radians).

**See also →** `sin`, `tan`, `acos`]],

  ["tan"] = [[
**`tan`** · Compute tangent (`<math.h>`)

```c
double tan(double x);
```

Returns the tangent of `x` (radians). Poles at π/2 + nπ.

**See also →** `sin`, `cos`, `atan`, `atan2`]],

  ["atan2"] = [[
**`atan2`** · Compute arc tangent with quadrant awareness (`<math.h>`)

```c
double atan2(double y, double x);
```

Returns the angle from the positive x-axis to the point `(x, y)` in radians `[-π, π]`. Handles all four quadrants correctly — unlike `atan(y/x)` which loses quadrant information.

```c
double angle = atan2(y, x);   // convert (x,y) to polar coordinates
```

**See also →** `atan`, `asin`, `acos`, `sin`, `cos`]],

  -- ── C Standard Library: Date and Time ───────────────────────────────────────

  ["time"] = [[
**`time`** · Get current calendar time (`<time.h>`)

```c
time_t time(time_t *t);
```

Returns the current calendar time as a `time_t` (typically seconds since epoch). If `t` is not `NULL`, also writes the result to `*t`. Returns `(time_t)-1` on error.

```c
time_t now = time(NULL);
```

**See also →** `clock`, `difftime`, `localtime`, `gmtime`, `strftime`, `ctime`]],

  ["clock"] = [[
**`clock`** · Get processor time consumed (`<time.h>`)

```c
clock_t clock(void);
```

Returns an approximation of processor time used by the program. To convert to seconds, divide by `CLOCKS_PER_SEC`.

```c
clock_t start = clock();
// ... work ...
double elapsed = (double)(clock() - start) / CLOCKS_PER_SEC;
```

**Not a wall-clock timer** — measures CPU time. Use `time()` or platform-specific APIs for wall-clock timing. May wrap around on 32-bit systems.

**See also →** `time`, `difftime`, `CLOCKS_PER_SEC`]],

  ["difftime"] = [[
**`difftime`** · Compute difference between two calendar times (`<time.h>`)

```c
double difftime(time_t end, time_t beginning);
```

Returns `end - beginning` in seconds as a `double`. Necessary because `time_t` is not guaranteed to be arithmetic (though it almost always is).

**See also →** `time`, `clock`]],

  ["localtime"] = [[
**`localtime`** · Convert time_t to local time (`<time.h>`)

```c
struct tm *localtime(const time_t *t);
```

Returns a pointer to a static `struct tm` representing the local time corresponding to `*t`. **Not thread-safe** — use `localtime_r` (POSIX) for reentrancy.

```c
time_t now = time(NULL);
struct tm *tm = localtime(&now);
printf("%d-%02d-%02d\n", tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday);
```

**struct tm fields:** `tm_sec`, `tm_min`, `tm_hour`, `tm_mday`, `tm_mon` (0–11), `tm_year` (years since 1900), `tm_wday`, `tm_yday`, `tm_isdst`.

**See also →** `gmtime`, `mktime`, `strftime`, `asctime`, `time`]],

  ["gmtime"] = [[
**`gmtime`** · Convert time_t to UTC (`<time.h>`)

```c
struct tm *gmtime(const time_t *t);
```

Like `localtime` but returns UTC / GMT time. **Not thread-safe** (uses static buffer).

**See also →** `localtime`, `mktime`, `time`]],

  ["mktime"] = [[
**`mktime`** · Convert local time struct to time_t (`<time.h>`)

```c
time_t mktime(struct tm *t);
```

Normalizes `t` (handles overflow of fields) and returns the corresponding `time_t`. Also sets `tm_wday` and `tm_yday`. Returns `(time_t)-1` if the time cannot be represented.

**See also →** `localtime`, `time`, `difftime`]],

  ["strftime"] = [[
**`strftime`** · Format date and time as string (`<time.h>`)

```c
size_t strftime(char *restrict s, size_t max,
                const char *restrict fmt, const struct tm *restrict tm);
```

Format specifiers: `%Y` (year), `%m` (month 01–12), `%d` (day 01–31), `%H` (hour 00–23), `%M` (minute), `%S` (second), `%A` (weekday name), `%B` (month name), `%c` (date+time), `%s` (unix timestamp, not portable). Returns number of chars written (excluding null), or 0 if `max` was too small.

```c
char buf[64];
strftime(buf, sizeof buf, "%Y-%m-%d", localtime(&(time_t){time(NULL)}));
```

**See also →** `asctime`, `ctime`, `localtime`]],

  ["ctime"] = [[
**`ctime`** · Convert time_t to string (`<time.h>`)

```c
char *ctime(const time_t *t);
```

Equivalent to `asctime(localtime(t))`. Returns a 26-character string like `"Wed Jun 30 21:49:08 2027\n"`. **Not thread-safe.**

**Prefer `strftime`** for controlled formatting.

**See also →** `asctime`, `strftime`, `localtime`]],

  -- ── C Standard Library: Types and Limits ────────────────────────────────────

  ["size_t"] = [[
**`size_t`** · Unsigned integer type for object sizes (`<stddef.h>`)

Unsigned result of `sizeof` operator. At least 16 bits; typically 32-bit on 32-bit systems, 64-bit on 64-bit systems. Used throughout the standard library (function parameters, array indexing).

```c
size_t n = sizeof(arr) / sizeof(arr[0]);
```

**Pitfalls:**
- Signed/unsigned mismatch: `(int)size_t_val` may overflow; `size_t_val < 0` is always false.
- `size_t` is unsigned — `for (size_t i = n - 1; i >= 0; i--)` is an infinite loop.
- `printf` format: `%zu` (C99+, use `%lu` and cast to `unsigned long` for older).

**See also →** `ptrdiff_t`, `ssize_t` (POSIX), `intptr_t`]],

  ["ptrdiff_t"] = [[
**`ptrdiff_t`** · Signed integer type for pointer difference (`<stddef.h>`)

The type of the result of subtracting two pointers. Signed. May be negative.

`printf` format: `%td` (C99+).

**See also →** `size_t`, `intptr_t`]],

  ["offsetof"] = [[
**`offsetof`** · Byte offset of a struct member (`<stddef.h>`)

```c
offsetof(type, member)
```

Returns the byte offset of `member` within a struct type `type` as a `size_t`. Useful for serialization, reflection, and container_of (Linux kernel pattern).

```c
struct Point { float x, y; };
size_t off = offsetof(struct Point, y);   // typically 4
```

**See also →** `sizeof`, `alignof` (C11)]],

  ["NULL"] = [[
**`NULL`** · Null pointer constant (`<stddef.h>` / `<stdlib.h>`)

Typically `((void*)0)` in C, `0` or `__null` in C++. Expands to an implementation-defined null pointer constant.

```c
int *p = NULL;
if (p == NULL) { /* handle */ }
```

**Dereferencing NULL is undefined behaviour** — always check before use. Set pointers to `NULL` after `free()` to make use-after-free detectable.

**See also →** `nullptr` (C23), `offsetof`]],

  ["int8_t"] = [[
**`int8_t`** · Signed 8-bit integer (`<stdint.h>`)

```c
int8_t  i;   // exactly 8 bits, signed, two's complement
uint8_t u;   // exactly 8 bits, unsigned
```

Available if the implementation supports it (practically always). Range: -128 to 127 (`INT8_MIN`, `INT8_MAX`).

`printf` format: `PRIi8` / `PRIu8` from `<inttypes.h>` — e.g., `printf("%" PRId8 "\n", val)`.

**See also →** `int16_t`, `int32_t`, `int64_t`, `uint8_t`, `<inttypes.h>`]],

  ["int16_t"] = [[
**`int16_t`** · Signed 16-bit integer (`<stdint.h>`)

Range: -32,768 to 32,767.

**See also →** `int8_t`, `int32_t`, `int64_t`, `int_least16_t`, `int_fast16_t`]],

  ["int32_t"] = [[
**`int32_t`** · Signed 32-bit integer (`<stdint.h>`)

Range: -2,147,483,648 to 2,147,483,647. The most common fixed-width type for structures, protocols, and file formats.

**See also →** `int8_t`, `int16_t`, `int64_t`, `uint32_t`]],

  ["int64_t"] = [[
**`int64_t`** · Signed 64-bit integer (`<stdint.h>`)

Range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807. `printf` format: `PRIi64` (often `"lld"` or `"ld"`). Literal suffix: `INT64_C(val)`.

**See also →** `int32_t`, `uint64_t`, `INT64_MAX`]],

  ["uint64_t"] = [[
**`uint64_t`** · Unsigned 64-bit integer (`<stdint.h>`)

Range: 0 to 18,446,744,073,709,551,615. `printf` format: `PRIu64`. Literal: `UINT64_C(val)`.

**See also →** `int64_t`, `uint32_t`, `uintmax_t`]],

  ["INT_MAX"] = [[
**`INT_MAX`** · Maximum value of `int` (`<limits.h>`)

Typically 2,147,483,647 (2³¹ − 1) on 32/64-bit systems. `INT_MIN` = −2,147,483,648 (−2³¹).

**See also →** `LONG_MAX`, `SHRT_MAX`, `UINT_MAX`, `CHAR_BIT`]],

  ["CHAR_BIT"] = [[
**`CHAR_BIT`** · Number of bits in a char (`<limits.h>`)

Always 8 in practice (POSIX requires 8). In theory, C allows larger values. `sizeof` returns bytes, not bits — use `CHAR_BIT * sizeof(T)` for bits.

**See also →** `INT_MAX`, `SIZE_MAX`]],

  ["errno"] = [[
**`errno`** · Thread-local error code variable (`<errno.h>`)

```c
#include <errno.h>

errno = 0;
long val = strtol(s, &end, 10);
if (errno == ERANGE) { /* overflow */ }
```

Set by library functions on error. **Must be set to 0 before the call** (no function clears it). In C11, `errno` is a thread-local macro (expands to a function call or `__thread` variable).

**Common values:** `EDOM` (domain error), `ERANGE` (range error), `EILSEQ` (illegal byte sequence).

**See also →** `perror`, `strerror`, `EDOM`, `ERANGE`]],

  ["assert"] = [[
**`assert`** · Runtime assertion (`<assert.h>`)

```c
#include <assert.h>

assert(ptr != NULL);
```

If the expression is false (zero), prints a diagnostic message and calls `abort()`. Disabled by defining `NDEBUG` before including `<assert.h>`:

```c
#define NDEBUG   // assert becomes a no-op
#include <assert.h>
```

Use for **internal invariants** and "this should never happen" checks, not for error handling.

**See also →** `static_assert` (C11), `abort`, `errno`]],

  ["static_assert"] = [[
**`static_assert`** · Compile-time assertion (C11)

```c
#include <assert.h>

static_assert(sizeof(int) == 4, "int must be 4 bytes");
```

Available as a keyword `_Static_assert` (C11) or the macro `static_assert` from `<assert.h>` (C11). The message string is required in C11 (optional in C23/C++17).

**See also →** `assert`, `_Alignof`, `_Generic`]],

  ["signal"] = [[
**`signal`** · Set a signal handler (`<signal.h>`)

```c
void (*signal(int sig, void (*handler)(int)))(int);
```

Sets the handling function for signal `sig`. `handler` can be a function pointer, `SIG_IGN` (ignore), or `SIG_DFL` (default). Returns the previous handler or `SIG_ERR` on error.

```c
signal(SIGINT, SIG_IGN);             // ignore Ctrl-C
signal(SIGSEGV, my_segv_handler);    // custom handler
```

**Signal handlers are severely restricted** — only can call signal-safe functions (`write`, not `printf`), access `volatile sig_atomic_t` variables, and modify `errno`. Signal handling is platform-dependent and hard to get right — **prefer `sigaction`** (POSIX) for portability.

**See also →** `raise`, `sigaction` (POSIX), `SIGINT`, `SIGTERM`, `SIGSEGV`]],

  ["raise"] = [[
**`raise`** · Send a signal to the calling process (`<signal.h>`)

```c
int raise(int sig);
```

Sends signal `sig` to the calling process. Returns 0 on success, non-zero on failure.

```c
raise(SIGABRT);  // trigger abort
```

**See also →** `signal`, `abort`, `kill` (POSIX)]],

  ["setjmp"] = [[
**`setjmp`** · Save stack context for non-local goto (`<setjmp.h>`)

```c
#include <setjmp.h>

jmp_buf env;
if (setjmp(env) == 0) {
    // initial return — save context
    risky_operation();
} else {
    // longjmp returned — handle error
    cleanup();
}
```

Saves the stack environment (registers, stack pointer) into `env`. Returns 0 on first call, non-zero (the value passed to `longjmp`) when reached via `longjmp`.

**Restrictions:** `setjmp` must appear directly in a controlling expression of `if`/`switch`/loop. Cannot be used in a nested function. Variables may have indeterminate values after `longjmp` if they are `volatile` (or in C, if local variables are not marked `volatile`).

**See also →** `longjmp`, `signal`]],

  ["longjmp"] = [[
**`longjmp`** · Perform non-local goto (`<setjmp.h>`)

```c
void longjmp(jmp_buf env, int val);
```

Restores the stack environment saved by `setjmp(env)`, causing execution to resume at the `setjmp` call with return value `val` (if `val` is 0, it becomes 1). **Does not call destructors** — objects with automatic storage duration between `setjmp` and `longjmp` may have indeterminate values.

**See also →** `setjmp`]],
}
