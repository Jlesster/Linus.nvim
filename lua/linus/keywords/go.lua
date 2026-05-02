-- jlesster/keywords/go.lua

return {
  ["func"] = [[
**`func`** — declares a function or method.
```go
func Add(a, b int) int { return a + b }

// method
func (r Receiver) Method() ReturnType { }

// multiple return values
func divide(a, b float64) (float64, error) { }

// named returns
func minmax(a, b int) (min, max int) { }
```]],

  ["go"] = [[
**`go`** — launches a goroutine: a lightweight concurrent function.
```go
go func() {
    doWork()
}()

go someFunction(args)
```
Goroutines are multiplexed onto OS threads by the Go runtime scheduler.
Synchronise with channels or `sync.WaitGroup`.]],

  ["chan"] = [[
**`chan`** — channel type for communicating between goroutines.
```go
ch := make(chan int)        // unbuffered
ch := make(chan int, 10)    // buffered, capacity 10

ch <- value   // send (blocks if full/no receiver)
v := <-ch     // receive (blocks if empty/no sender)
close(ch)     // signal no more values will be sent
```
Directional: `chan<- int` (send-only), `<-chan int` (receive-only).]],

  ["select"] = [[
**`select`** — multiplex channel operations; picks a ready case at random.
```go
select {
case v := <-ch1:
    use(v)
case ch2 <- val:
    sent()
case <-time.After(1 * time.Second):
    timeout()
default:
    // non-blocking: runs if no case is ready
}
```]],

  ["defer"] = [[
**`defer`** — schedules a function call to run when the surrounding function returns.
```go
defer file.Close()
defer func() { recover() }()
```
Multiple defers execute in LIFO order.
Arguments to deferred calls are evaluated immediately at the defer statement.]],

  ["interface"] = [[
**`interface`** — defines a set of method signatures. Implemented implicitly.
```go
type Stringer interface {
    String() string
}

// embedding
type ReadWriter interface {
    io.Reader
    io.Writer
}
```
The empty interface `interface{}` (or `any` since Go 1.18) accepts any type.]],

  ["struct"] = [[
**`struct`** — composite type grouping named fields.
```go
type Point struct {
    X, Y float64
    Label string `json:"label"`  // struct tag
}
p := Point{X: 1.0, Y: 2.0}
p.X = 3.0
```
Methods are defined outside the struct body, on a receiver.]],

  ["map"] = [[
**`map`** — hash map (reference type).
```go
m := make(map[string]int)
m["key"] = 42
v, ok := m["key"]  // ok = false if key absent
delete(m, "key")
```
Map literals: `map[string]int{"a": 1, "b": 2}`
Not safe for concurrent access — use `sync.Map` or a mutex.]],

  ["range"] = [[
**`range`** — iterates over arrays, slices, maps, strings, or channels.
```go
for i, v := range slice { }       // index, value
for k, v := range myMap { }       // key, value
for i, c := range "héllo" { }     // rune index, rune (Unicode-aware)
for v := range ch { }             // receive from channel until closed
```
Use `_` to discard index or value.]],

  ["type"] = [[
**`type`** — declares a new named type or type alias.
```go
type Celsius float64           // new type (not interchangeable with float64)
type Alias = float64           // alias (interchangeable)
type Handler func(http.ResponseWriter, *http.Request)
```]],

  ["var"] = [[
**`var`** — declares a variable with explicit type or initializer.
```go
var x int          // zero value: 0
var s = "hello"    // type inferred
var a, b int = 1, 2
```
Short declaration `:=` is preferred inside functions.]],

  ["const"] = [[
**`const`** — compile-time constant. Cannot be addressed.
```go
const Pi = 3.14159
const (
    KB = 1024
    MB = 1024 * KB
)
// iota: auto-incrementing counter in const blocks
const (
    A = iota  // 0
    B         // 1
    C         // 2
)
```]],

  ["make"] = [[
**`make`** — allocates and initialises slices, maps, and channels.
```go
s := make([]int, len, cap)   // slice
m := make(map[K]V)           // map
ch := make(chan T, bufsize)  // channel
```
Returns the initialised (non-nil) value, not a pointer.]],

  ["new"] = [[
**`new`** — allocates zeroed storage for a type and returns a pointer.
```go
p := new(int)    // *int pointing to a zero int
```
Rarely used; prefer composite literals `&T{}` for structs.]],

  ["panic"] = [[
**`panic`** — stops normal execution and begins unwinding the stack.
Deferred functions still run during a panic unwind.
```go
panic("something went wrong")
panic(err)
```
Recover with `recover()` inside a deferred function.]],

  ["recover"] = [[
**`recover`** — stops a panic and returns the value passed to `panic`.
Must be called directly inside a deferred function.
```go
defer func() {
    if r := recover(); r != nil {
        log.Println("recovered:", r)
    }
}()
```]],

  ["goroutine"] = [[
**goroutine** — a lightweight thread managed by the Go runtime.
Created with the `go` keyword. Stack starts small (~2KB) and grows as needed.
Scheduled cooperatively by the Go scheduler (GOMAXPROCS controls parallelism).
Communicate via channels; share memory via synchronisation primitives in `sync`.]],

  ["nil"] = [[
**`nil`** — the zero value for pointers, interfaces, slices, maps, channels, and functions.
```go
var p *int        // nil pointer
var s []int       // nil slice (len=0, cap=0; append works)
var m map[K]V     // nil map (read ok; write panics)
var err error     // nil interface (no error)
```]],

  ["error"] = [[
**`error`** — built-in interface for representing errors.
```go
type error interface { Error() string }
```
Convention: return `nil` for no error, a non-nil `error` otherwise.
Create with: `errors.New("msg")`, `fmt.Errorf("ctx: %w", err)` (wrapping).
Check with: `err != nil`, `errors.Is(err, target)`, `errors.As(err, &target)`.]],

  ["append"] = [[
**`append`** — adds elements to a slice, growing it if necessary.
```go
s = append(s, elem)
s = append(s, a, b, c)
s = append(s, otherSlice...)
```
May allocate a new backing array; always use the returned slice.]],

  ["copy"] = [[
**`copy`** — copies elements between slices (or bytes from a string).
```go
n := copy(dst, src)  // copies min(len(dst), len(src)) elements, returns n
```]],

  ["close"] = [[
**`close`** — closes a channel, signalling no more values will be sent.
```go
close(ch)
```
Receiving from a closed channel returns remaining buffered values then the zero value.
Only the sender should close a channel. Closing a nil or already-closed channel panics.]],

  ["iota"] = [[
**`iota`** · Auto-incrementing const counter

Resets to 0 at each `const` block; increments by 1 for each spec in the block.
```go
const (
    Read   = 1 << iota  // 1
    Write               // 2
    Exec                // 4
)

// Skip values with blank identifier:
const (
    _  = iota   // 0 — discarded
    KB = 1 << (10 * iota)  // 1024
    MB                     // 1048576
    GB                     // 1073741824
)
```

**See also** → `const`]],

  -- ── Control flow ──────────────────────────────────────────────────────────

  ["if"] = [[
**`if`** · Conditional branch

```go
if condition {
    // true branch
} else if other {
    // alternative
} else {
    // fallback
}
```

Condition must be a boolean expression — unlike C, integers do **not** implicitly convert to `bool`.

**Init statement** — scopes a variable to the `if`/`else` block:
```go
if n, err := strconv.Atoi(s); err != nil {
    log.Printf("bad number: %v", err)
} else {
    use(n)   // n is in scope in the else block too
}
```

Prefer early `return` ("guard clause" pattern) to deep `else` nesting.

**See also** → `switch`, `for`, `else`]],

  ["else"] = [[
**`else`** · Alternative branch of an `if` statement

```go
if condition {
    // true
} else if other {
    // alternative
} else {
    // fallback
}
```

Variables declared in the `if` init statement are in scope in the `else` block:
```go
if f, err := os.Open(name); err != nil {
    log.Fatal(err)
} else {
    defer f.Close()   // f is accessible here
    use(f)
}
```

**See also** → `if`, `switch`]],

  ["for"] = [[
**`for`** · Go's only loop construct — covers all looping patterns

```go
// Classic three-clause (C-style):
for i := 0; i < n; i++ { }

// Condition-only (while equivalent):
for condition { }

// Infinite loop:
for { }

// Range over slice or array:
for i, v := range slice { }   // index, value
for i := range slice { }      // index only
for _, v := range slice { }   // value only

// Range over map:
for k, v := range myMap { }

// Range over string (Unicode-aware):
for i, r := range "héllo" { }   // i = byte index, r = rune (code point)

// Range over channel until closed:
for v := range ch { }

// Count-only range (Go 1.22+):
for range n { }   // iterates n times, no variable
```

**Key facts**
- No `while` keyword — the condition-only form fills that role
- `range` on a string yields `(byte index, rune)` — indices may skip (multibyte UTF-8)
- `break` and `continue` accept labels to target outer loops

**See also** → `range`, `break`, `continue`, `go`]],

  ["switch"] = [[
**`switch`** · Multi-way dispatch

```go
// Expression switch — no fall-through by default:
switch x {
case 1, 2:
    doAB()
case 3:
    doC()
default:
    doElse()
}

// Condition-less switch (structured if-else chain):
switch {
case score >= 90:
    grade = "A"
case score >= 80:
    grade = "B"
default:
    grade = "F"
}

// Init statement:
switch os := runtime.GOOS; os {
case "linux":
    fmt.Println("Linux")
default:
    fmt.Printf("Other: %s\n", os)
}

// Type switch:
switch v := i.(type) {
case int:
    fmt.Printf("int: %d\n", v)
case string:
    fmt.Printf("string: %s\n", v)
default:
    fmt.Printf("other: %T\n", v)
}
```

**Key facts**
- Cases do NOT fall through by default — no `break` needed
- Multiple values per case: `case 1, 2, 3:`
- Use `fallthrough` to explicitly continue to the next case body (condition not re-evaluated)
- Type switch uses `.(type)` and requires a short assignment

**See also** → `fallthrough`, `case`, `default`, `if`, `select`]],

  ["case"] = [[
**`case`** · Branch label in a `switch` or `select` statement

```go
// switch case — multiple values allowed:
switch x {
case 0:
    fmt.Println("zero")
case 1, 2, 3:
    fmt.Println("small positive")
default:
    fmt.Println("other")
}

// select case (channel operations):
select {
case v := <-ch:
    use(v)
case ch2 <- val:
    fmt.Println("sent")
default:
    // runs immediately if no channel is ready
}
```

In `switch`, cases do not fall through by default (unlike C).
In `select`, Go picks one ready case at random if multiple are ready simultaneously.

**See also** → `switch`, `select`, `default`, `fallthrough`]],

  ["default"] = [[
**`default`** · Fallback branch in `switch` or non-blocking clause in `select`

```go
// switch default:
switch x {
case 1:
    doOne()
default:
    doElse()   // runs when no other case matches
}

// select default — makes select non-blocking:
select {
case v := <-ch:
    use(v)
default:
    // runs immediately if ch has no queued message
}
```

**Key facts**
- In `switch`, `default` can appear anywhere in the case list (not required to be last)
- In `select`, adding `default` turns the statement from a blocking wait into a poll
- `switch` without a `default` silently does nothing if no case matches

**See also** → `switch`, `select`, `case`]],

  ["break"] = [[
**`break`** · Exit the innermost `for`, `switch`, or `select` statement

```go
for i := 0; i < 10; i++ {
    if found(i) { break }
}

switch x {
case 1:
    process()
    // implicit break — no explicit break needed in Go switch
}
```

**Labeled break** — exit a specific outer statement:
```go
outer:
    for i := range rows {
        for j := range cols {
            if grid[i][j] == target {
                break outer   // exits the outer for loop
            }
        }
    }
```

**See also** → `continue`, `goto`, `for`, `switch`, `select`]],

  ["continue"] = [[
**`continue`** · Skip the rest of the current loop body; jump to the next iteration

```go
for _, v := range items {
    if v < 0 {
        continue   // skip negatives
    }
    process(v)
}
```

In a `for` loop with a post-statement (`i++`), `continue` runs the post-statement before rechecking the condition.

**Labeled continue** — skip to the next iteration of an outer loop:
```go
outer:
    for i := range rows {
        for j := range cols {
            if skip(i, j) { continue outer }
            process(i, j)
        }
    }
```

**See also** → `break`, `for`, `goto`]],

  ["return"] = [[
**`return`** · Exit a function, optionally with one or more values

```go
// Single return value:
func double(x int) int {
    return x * 2
}

// Multiple return values (idiomatic Go):
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

// Named return values + bare return:
func minmax(s []int) (min, max int) {
    min, max = s[0], s[0]
    for _, v := range s[1:] {
        if v < min { min = v }
        if v > max { max = v }
    }
    return   // returns named min and max
}
```

**Key facts**
- Multiple return values are a core Go idiom — the `(value, error)` pair is ubiquitous
- `defer` runs after `return` executes but before the function physically returns; deferred functions can read/modify named return values
- A bare `return` in a function with named results returns the current values of those names

**See also** → `defer`, `func`, `error`]],

  ["fallthrough"] = [[
**`fallthrough`** · Transfer control to the first statement of the next `switch` case

```go
switch n {
case 0:
    fmt.Println("zero")
    fallthrough   // unconditionally executes next case body
case 1:
    fmt.Println("zero or one")   // runs for both case 0 and case 1
}
```

**Key facts**
- Unlike C, Go `switch` does **not** fall through by default — `fallthrough` is an explicit opt-in
- The next case condition is NOT evaluated — control goes directly to the body
- Cannot be used as the last statement in the last case of a `switch`
- Not allowed in type switches

**See also** → `switch`, `break`]],

  ["goto"] = [[
**`goto`** · Unconditional jump to a label within the same function

```go
for i := 0; i < 10; i++ {
    if err := process(i); err != nil {
        goto cleanup
    }
}
cleanup:
    release()
    return
```

**Key facts**
- Rarely needed in Go — prefer labeled `break`/`continue`, `defer`, or early `return`
- Cannot jump over variable declarations (causes a compile error)
- Labels are scoped to the enclosing function body
- Cannot jump between functions

**See also** → `break`, `continue`, `defer`]],

  -- ── Package management ────────────────────────────────────────────────────

  ["import"] = [[
**`import`** · Bring packages into scope

```go
import "fmt"         // single import

import (             // grouped import (gofmt convention)
    "fmt"
    "os"
    "path/filepath"

    "github.com/some/pkg"   // external module dependency
)

// Rename at the import site:
import myfmt "fmt"
myfmt.Println("hello")

// Blank import — run init() side-effects, expose no names:
import _ "image/png"    // registers PNG decoder

// Dot import — inject names into current scope (avoid):
import . "fmt"
Println("hello")   // no "fmt." prefix needed
```

**Key facts**
- An imported package that is never used is a **compile error**
- Blank import (`_`) is common for codec/driver registration
- Circular imports are a compile error
- The package identifier at call sites is the last element of the import path (e.g., `http` for `"net/http"`)
- `go.mod` and `go.sum` manage module dependencies

**See also** → `package`]],

  ["package"] = [[
**`package`** · Declare which package this file belongs to

```go
package main     // executable — must define func main()
package mylib    // library package
package mylib_test  // external test package (black-box testing)
```

**Key facts**
- Must be the first non-comment statement in every `.go` file
- All `.go` files in the same directory must share the same package name
- `package main` is special — the toolchain produces an executable
- The package name is the identifier used at call sites (`fmt.Println`), not the full import path
- `init()` functions in the package run automatically before `main()`

**Naming conventions**
- Short, lowercase, single word: `http`, `json`, `sync`
- Avoid underscores or mixed case
- Don't repeat the package name in exported identifiers: `http.Client` not `http.HTTPClient`

**See also** → `import`, `func`]],

  -- ── Predeclared types ─────────────────────────────────────────────────────

  ["string"] = [[
**`string`** · Immutable sequence of bytes (UTF-8 encoded text)

| Property | Value |
|----------|-------|
| Zero value | `""` |
| Encoding | UTF-8 by convention; any bytes allowed |
| Mutability | Immutable — no in-place modification |
| `s[i]` | Returns the i-th **byte** (not rune) |

```go
s := "Hello, 世界"
fmt.Println(len(s))          // 13 (bytes, not characters)
fmt.Println(len([]rune(s)))  // 9  (Unicode code points)

// Range over string gives (byte-index, rune):
for i, r := range s {
    fmt.Printf("%d: %c\n", i, r)
}

// Concatenation:
greeting := "Hello" + ", " + name + "!"

// Raw string literal — no escape processing:
path := `C:\Users\name\file.txt`
re   := `\d+\.\d+`

// Multi-line:
msg := `line one
line two`
```

**Conversions**
- `[]byte(s)` — bytes (copies); useful for I/O
- `string(b)` — from byte slice (copies)
- `[]rune(s)` — for character-level operations
- `string(r)` — single rune to string

**See also** → `byte`, `rune`, `strings` package, `fmt.Sprintf`]],

  ["bool"] = [[
**`bool`** · Boolean type

| Property | Value |
|----------|-------|
| Values | `true`, `false` |
| Zero value | `false` |
| Operators | `&&` (and), `\|\|` (or), `!` (not) |

```go
var flag bool         // false
flag = true
ok    := flag && other   // short-circuit AND
either := a || b         // short-circuit OR
neg   := !flag

// Comparison operators produce bool:
eq := x == y
lt := x < y
```

**Key facts**
- Unlike C, integers do **not** implicitly convert to `bool` — `if 1 { }` is a compile error
- Short-circuit evaluation: right side of `&&`/`||` is not evaluated if result is already determined
- `bool` cannot be cast to an integer type

**See also** → `true`, `false`, `if`]],

  ["int"] = [[
**`int`** · Platform-sized signed integer (the default integer type)

| Type | Bits | Range |
|------|------|-------|
| `int` | 32 or 64 (platform) | −2³¹..2³¹−1 or −2⁶³..2⁶³−1 |
| `int8` | 8 | −128..127 |
| `int16` | 16 | −32,768..32,767 |
| `int32` | 32 | −2,147,483,648..2,147,483,647 |
| `int64` | 64 | −2⁶³..2⁶³−1 |

```go
var n int = 42
n := 42              // inferred as int

var big int64 = 1 << 62

// Explicit conversion required between distinct types:
var i int = 10
var j int64 = int64(i) + big
```

**Key facts**
- `int` size matches the platform word size (32-bit on 32-bit, 64-bit on 64-bit)
- Different integer types are **not** implicitly convertible — explicit cast required
- Integer overflow wraps silently (no panic, no undefined behaviour — unlike C)
- Use `int` for slice indices, loop variables, and general counting
- `math/bits` provides bit-manipulation utilities

**See also** → `uint`, `byte`, `rune`, `float64`, `math/big`]],

  ["float64"] = [[
**`float64`** · 64-bit IEEE 754 floating-point number (the default float type)

| Type | Bits | Precision |
|------|------|-----------|
| `float32` | 32 | ~7 decimal digits |
| `float64` | 64 | ~15–16 decimal digits |

```go
var f float64 = 3.14
pi := 3.14159265358979   // inferred as float64

import "math"
fmt.Println(math.Sqrt(2.0))
fmt.Println(math.IsNaN(f))
fmt.Println(math.IsInf(f, 1))  // +Inf?

// Special values:
posInf := math.Inf(1)
negInf := math.Inf(-1)
nan    := math.NaN()
```

**Key facts**
- Untyped floating-point literals default to `float64`
- All `math` package functions use `float64`
- Not suitable for monetary calculations — use `math/big.Float` or integer cents
- `float32` is mainly useful for graphics, audio, or large float arrays where memory matters

**See also** → `float32`, `int`, `complex128`, `math`]],

  ["byte"] = [[
**`byte`** · Alias for `uint8` — an 8-bit unsigned integer

| Property | Value |
|----------|-------|
| Range | 0..255 |
| Zero value | `0` |
| Identical to | `uint8` |

```go
var b byte = 'A'     // 65
b = 0xFF             // 255

// Slice of bytes — the standard for I/O and binary data:
data := []byte("hello")
data[0] = 'H'
fmt.Println(string(data))  // "Hello"

// String ↔ []byte:
s := string(data)
b2 := []byte(s)
```

**Key facts**
- `byte` and `uint8` are identical and interchangeable
- Most I/O operations (`io.Reader`, `os.File.Write`) use `[]byte`
- `s[i]` on a string yields a `byte` — use `range s` to iterate runes (Unicode code points)
- Character literals like `'A'` are untyped rune constants; assign to `byte` if ≤ 255

**See also** → `rune`, `string`, `uint8`]],

  ["rune"] = [[
**`rune`** · Alias for `int32` — a Unicode code point

| Property | Value |
|----------|-------|
| Range | 0..1,114,111 (full Unicode) |
| Identical to | `int32` |
| Zero value | `0` (null character) |

```go
var r rune = '世'        // U+4E16 — value 19990
r = '\n'                // newline — 10
r = '😀'               // emoji — 128512

// String → rune slice for character-level access:
s := "Hello, 世界"
runes := []rune(s)
fmt.Println(len(s))       // 13 (bytes)
fmt.Println(len(runes))   // 9  (characters)
fmt.Println(string(runes[7]))  // "世"

// Range over string yields (byte-index, rune):
for i, r := range s {
    fmt.Printf("index %d: %c (U+%04X)\n", i, r, r)
}
```

**Key facts**
- `rune` and `int32` are identical types
- Characters outside the BMP (e.g. emoji) take up to 4 bytes in UTF-8 but are a single `rune`
- `unicode/utf8` package: `utf8.RuneCountInString(s)`, `utf8.DecodeRuneInString(s)`

**See also** → `byte`, `string`, `unicode/utf8`]],

  ["any"] = [[
**`any`** · Alias for `interface{}` — accepts a value of any type  *(Go 1.18+)*

```go
var v any = 42
v = "hello"
v = []int{1, 2, 3}

// Type assertion to recover concrete type:
s, ok := v.(string)
if !ok { /* v is not a string */ }

// Type switch:
switch val := v.(type) {
case int:     fmt.Println("int:", val)
case string:  fmt.Println("string:", val)
default:      fmt.Printf("other: %T\n", val)
}

// Generic constraint — any type allowed:
func Identity[T any](v T) T { return v }

// Common in JSON decoding:
var m map[string]any
json.Unmarshal(data, &m)
```

**Key facts**
- `any` = `interface{}` — they are identical
- Using `any` loses static type safety — prefer specific types or interface contracts
- A type assertion `v.(T)` panics if the dynamic type doesn't match; use the comma-ok form to be safe

**See also** → `interface`, `error`]],

  -- ── Built-in functions ────────────────────────────────────────────────────

  ["len"] = [[
**`len`** · Built-in: number of elements or bytes

```go
len(array)     // fixed: number of elements (compile-time constant)
len(slice)     // elements currently in use
len(map)       // number of key-value pairs
len(string)    // number of bytes (not runes/characters!)
len(channel)   // number of elements queued in the buffer
```

**Key facts**
- `len(nil)` returns 0 for slices, maps, and channels
- For Unicode character count: `len([]rune(s))` or `utf8.RuneCountInString(s)`
- For arrays, `len` is a compile-time constant
- Return type is `int`

**See also** → `cap`, `append`, `make`, `unicode/utf8`]],

  ["cap"] = [[
**`cap`** · Built-in: capacity of a slice or channel buffer

```go
s := make([]int, 3, 10)   // len=3, cap=10
fmt.Println(cap(s))        // 10

ch := make(chan int, 5)
fmt.Println(cap(ch))        // 5

// After reslicing — cap counts from the slice start to end of backing array:
s2 := s[1:3]
fmt.Println(len(s2), cap(s2))   // 2, 9
```

**Key facts**
- For arrays, `cap(a) == len(a)` always
- For slices, `cap >= len` always
- When `append` exceeds capacity, Go allocates a new, larger backing array (amortised O(1))
- Pre-allocate to avoid repeated copying: `make([]T, 0, estimatedSize)`

**See also** → `len`, `make`, `append`]],

  ["delete"] = [[
**`delete`** · Built-in: remove a key-value pair from a map

```go
m := map[string]int{"a": 1, "b": 2, "c": 3}

delete(m, "b")          // removes key "b"
delete(m, "missing")    // no-op — safe, no error or panic

// Clear all entries (Go 1.21+):
clear(m)
// Or reassign:
m = make(map[string]int)
```

**Key facts**
- `delete` on a nil map **panics**
- `delete` on an absent key is a no-op
- Concurrent map access (including `delete`) requires synchronisation — use `sync.Mutex` or `sync.Map`

**See also** → `map`, `make`, `clear`]],

  -- ── Boolean literals ──────────────────────────────────────────────────────

  ["true"] = "**`true`** — untyped boolean constant. In Go there is no implicit integer-to-bool conversion: `if 1 { }` is a compile error. Use `true` and `false` explicitly.",

  ["false"] = "**`false`** — untyped boolean constant. Zero value of the `bool` type. All boolean fields and array elements default to `false`. Conditions require an actual `bool` expression.",

  -- ── Complex numbers ───────────────────────────────────────────────────────

  ["complex"] = [[
**`complex`** · Built-in: construct a complex number from real and imaginary parts

```go
c := complex(3.0, 4.0)    // 3+4i  — type: complex128
c2 := 2 + 3i              // imaginary literal — complex128

var c32 complex64 = complex(float32(1), float32(2))

import "math/cmplx"
fmt.Println(cmplx.Abs(c))     // 5.0 (magnitude √(3²+4²))
fmt.Println(cmplx.Phase(c))   // angle in radians
```

| Type | Real/Imag component |
|------|---------------------|
| `complex64` | `float32` |
| `complex128` | `float64` |

**See also** → `real`, `imag`, `math/cmplx`]],

  ["real"] = [[
**`real`** · Built-in: extract the real part of a complex number

```go
c := 3 + 4i
r := real(c)   // 3.0  — float64 (from complex128)
```

Returns `float64` for `complex128`, `float32` for `complex64`.

**See also** → `imag`, `complex`]],

  ["imag"] = [[
**`imag`** · Built-in: extract the imaginary part of a complex number

```go
c := 3 + 4i
i := imag(c)   // 4.0  — float64 (from complex128)
```

Returns `float64` for `complex128`, `float32` for `complex64`.

**See also** → `real`, `complex`]],
}
