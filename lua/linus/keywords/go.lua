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
**`iota`** — predeclared identifier representing the index of the current const spec.
Resets to 0 at each `const` block.
```go
const (
    Read   = 1 << iota  // 1
    Write               // 2
    Exec                // 4
)
```]],
}
