-- linus/keywords/java.lua
-- Java keyword and built-in reference table.
-- Each value is a markdown string (or string[]) shown when LSP hover returns nothing.
-- Format: brief headline → syntax fence → description → key points → see also.

return {

  -- ── Type declarations ──────────────────────────────────────────────────────

  ["class"] = [[
**`class`** · Type declaration

```java
[modifiers] class Name [extends SuperClass] [implements I1, I2] {
    // fields, constructors, methods, nested types
}
```

Declares a **reference type** — the fundamental unit of OOP in Java.

**Modifiers**
- `public` — visible everywhere; filename must match
- `abstract` — cannot be instantiated; may contain abstract methods
- `final` — cannot be subclassed (e.g. `String`, `Integer`)
- `sealed` — restricts which classes may extend it (Java 17+)
- `static` — valid only for nested classes; no reference to outer instance

**Inheritance**
- Single class inheritance via `extends` (default parent: `Object`)
- Multiple interface fulfilment via `implements`
- All objects are `instanceof Object`

**Variants** → `enum`, `record`, `interface`, `abstract class`]],

  ["interface"] = [[
**`interface`** · Type declaration

```java
[modifiers] interface Name [extends I1, I2] {
    ReturnType method();                       // abstract (default)
    default ReturnType method() { ... }        // default impl (Java 8+)
    static ReturnType helper() { ... }         // static method (Java 8+)
    private ReturnType shared() { ... }        // private helper (Java 9+)
    TYPE CONSTANT = value;                     // public static final
}
```

Declares a **pure contract** — a named set of capabilities a class can promise.

**Key facts**
- A class may `implement` any number of interfaces
- Default method conflicts are resolved by the implementing class (or won't compile)
- An interface with exactly one abstract method is a **functional interface** — usable as a lambda target
- Annotate with `@FunctionalInterface` to enforce the single-method constraint

**Functional interface pattern**
```java
@FunctionalInterface
interface Transformer<A, B> { B transform(A input); }
Transformer<String, Integer> len = String::length;
```

**See also** → `abstract`, `default`, `sealed`, `@FunctionalInterface`]],

  ["enum"] = [[
**`enum`** · Type declaration

```java
[modifiers] enum Name [implements I1, I2] {
    CONSTANT_A, CONSTANT_B;        // simple constants
    CONSTANT(arg1, arg2);          // with constructor args

    // fields, constructor, methods (optional)
}
```

Declares a **fixed, closed set of named constants** with full class capabilities.

**All enums automatically get**
- `values()` — ordered array of all constants
- `valueOf(String)` — constant by name (throws `IllegalArgumentException`)
- `name()` — declared name as String
- `ordinal()` — 0-based declaration order
- `toString()`, `equals()`, `hashCode()`, `compareTo()` (Comparable)
- Thread-safe singleton semantics; JVM guarantees one instance per constant

**Enum with state**
```java
public enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH  (5.976e+24, 6.37814e6);

    private final double mass;    // kg
    private final double radius;  // metres
    Planet(double mass, double radius) {
        this.mass = mass; this.radius = radius;
    }
    double surfaceGravity() { return 6.67300E-11 * mass / (radius * radius); }
}
```

**Exhaustive switch (Java 14+)**
```java
String symbol = switch (planet) {
    case MERCURY -> "☿";
    case EARTH   -> "♁";
    // compiler enforces all cases are covered
};
```

**Useful companion types** — `EnumSet.of(A, B)`, `EnumMap<MyEnum, V>`

**See also** → `switch`, `sealed`]],

  ["record"] = [[
**`record`** · Type declaration  *(Java 16+)*

```java
[modifiers] record Name(ComponentType comp1, ComponentType comp2, ...) [implements I] {
    // optional: compact constructor, extra methods, static members
}
```

An **immutable data carrier** — a class whose identity is entirely defined by its components.

**Auto-generated for every record**
- Canonical constructor (`new Name(comp1, comp2)`)
- Accessor methods with the same name as each component (`comp1()`, `comp2()`)
- `equals()` — true iff all components are equal
- `hashCode()` — derived from all components
- `toString()` — `Name[comp1=…, comp2=…]`

**Compact constructor** — validates without repeating assignments
```java
record Range(int lo, int hi) {
    Range {   // no parameter list — components are in scope
        if (lo > hi) throw new IllegalArgumentException(lo + " > " + hi);
    }
}
```

**Pattern matching (Java 21+)**
```java
if (shape instanceof Circle(double r)) {
    System.out.println("radius " + r);
}
```

**Limitations**
- Implicitly `final`; cannot be extended (implicitly extends `java.lang.Record`)
- Can implement interfaces
- Components are implicitly `private final`; cannot add instance fields

**See also** → `sealed`, `instanceof`, `class`]],

  ["abstract"] = [[
**`abstract`** · Modifier

**On a class** — the class cannot be instantiated directly:
```java
abstract class Shape {
    abstract double area();           // subclass must implement
    void describe() {                 // concrete method — inherited as-is
        System.out.println("Area: " + area());
    }
}
```

**On a method** — declares intent without a body; forces subclasses to implement:
```java
abstract ReturnType methodName(Params);   // no body, no braces
```

**Rules**
- A class containing any `abstract` method must itself be declared `abstract`
- An `abstract` class may contain both abstract and concrete members
- Abstract classes may have constructors (called via `super()` from subclass)
- Cannot be `final` or `private` (impossible to implement if you can't see or extend it)

**Template method pattern**
```java
abstract class DataProcessor {
    final void process() { open(); doWork(); close(); }  // fixed skeleton
    abstract void doWork();                               // customisable step
    void open()  { }   // optional hooks
    void close() { }
}
```

**See also** → `class`, `interface`, `extends`, `sealed`]],

  ["sealed"] = [[
**`sealed`** · Modifier  *(Java 17+)*

```java
public sealed interface Shape permits Circle, Rectangle, Triangle {}
public sealed class Expr permits Num, Add, Mul {}
```

Restricts which classes or interfaces may **directly** extend or implement this type.

**Permitted subtypes must be one of**
- `final` — no further extension
- `sealed` — further restricted extension
- `non-sealed` — reopens the hierarchy (opt-out)

**Why it matters — exhaustive switch**
```java
// Compiler can verify all cases without a default:
double area = switch (shape) {
    case Circle c    -> Math.PI * c.radius() * c.radius();
    case Rectangle r -> r.width() * r.height();
    case Triangle t  -> t.base() * t.height() / 2;
};
```

**Useful for**
- Algebraic data types / discriminated unions
- Making `instanceof` chains compile-time exhaustive
- Replacing unsafe open inheritance with explicit contracts

**See also** → `permits`, `non-sealed`, `record`, `enum`, `switch`]],

  ["permits"] = [[
**`permits`** · Clause  *(Java 17+)*

```java
sealed interface Result<T> permits Success, Failure {}
```

Names the **exhaustive list** of direct subtypes allowed for a `sealed` type.

**Rules**
- All named types must be in the same package (or same module)
- Can be omitted if all permitted subtypes are defined in the same source file — compiler infers the list

**See also** → `sealed`, `non-sealed`]],

  ["non-sealed"] = [[
**`non-sealed`** · Modifier  *(Java 17+)*

```java
public non-sealed class PluginShape extends Shape {}
```

Opts a permitted subtype **back out** of the sealed hierarchy — reopening it for arbitrary extension.

Useful when a sealed base type needs to allow third-party extension at one specific point without giving up exhaustiveness elsewhere.

**See also** → `sealed`, `permits`]],

  -- ── Inheritance & type relationships ──────────────────────────────────────

  ["extends"] = [[
**`extends`** · Inheritance / bound

**Class inheritance** (single only):
```java
class Dog extends Animal { }
```

**Interface inheritance** (multiple allowed):
```java
interface ReadWriteList<E> extends List<E>, Deque<E> { }
```

**Upper-bounded wildcard**:
```java
void printAll(List<? extends Number> nums) { }
// accepts List<Integer>, List<Double>, etc.
```

**Rules**
- A class may extend at most one other class
- An interface may extend multiple interfaces
- Every class that doesn't explicitly extend something extends `Object`
- Cannot extend a `final` class or another `enum`

**See also** → `implements`, `super`, `sealed`]],

  ["implements"] = [[
**`implements`** · Interface fulfilment

```java
class LinkedList<E> implements List<E>, Deque<E>, Cloneable, Serializable {
    // must provide all abstract methods from List and Deque
    // (or be declared abstract)
}
```

**Rules**
- A class may implement any number of interfaces
- All abstract methods must be implemented (or the class declared `abstract`)
- `default` method conflicts between interfaces must be resolved by the class
- Records and enums may also implement interfaces

**Default conflict resolution**
```java
interface A { default void hello() { System.out.println("A"); } }
interface B { default void hello() { System.out.println("B"); } }
class C implements A, B {
    @Override public void hello() { A.super.hello(); }  // explicit resolution required
}
```

**See also** → `interface`, `extends`, `default`, `abstract`]],

  ["instanceof"] = [[
**`instanceof`** · Type test operator

**Classic form**:
```java
if (obj instanceof String) {
    String s = (String) obj;
    System.out.println(s.length());
}
```

**Pattern matching form** *(Java 16+)* — tests and binds in one step:
```java
if (obj instanceof String s && s.length() > 3) {
    System.out.println(s.toUpperCase());  // s is in scope here
}
```

**Switch pattern** *(Java 21+)*:
```java
String desc = switch (obj) {
    case Integer i -> "int " + i;
    case String  s -> "str " + s;
    case null      -> "null";
    default        -> "other";
};
```

**Key facts**
- Always returns `false` for `null`
- Works on interfaces, abstract classes, arrays
- The binding variable is effectively final in the matched block

**See also** → `switch`, `record`, `sealed`]],

  -- ── Access modifiers ───────────────────────────────────────────────────────

  ["public"] = [[
**`public`** · Access modifier — widest visibility

| Context | Effect |
|---------|--------|
| Top-level class/interface | Accessible from any package; filename **must** match |
| Member | Accessible from any code that can see the containing type |

**Encapsulation guideline** — expose the minimum necessary. Prefer package-private (no modifier) for implementation helpers; `public` only for the deliberate API surface.

**See also** → `private`, `protected`]],

  ["private"] = [[
**`private`** · Access modifier — narrowest visibility

Accessible **only within the declaring class** — not from subclasses, not from other classes in the same package.

```java
public class BankAccount {
    private double balance;           // hidden from outside
    public void deposit(double amt) { // controlled access point
        if (amt > 0) balance += amt;
    }
}
```

**Key facts**
- Private members are **not inherited** (though subclasses can call inherited public/protected methods that access them)
- Private nested class: useful for implementation details
- `private` methods in interfaces allowed since Java 9

**See also** → `public`, `protected`]],

  ["protected"] = [[
**`protected`** · Access modifier

Accessible from:
1. The **same package**
2. **Subclasses** (even in different packages) — but only through a reference of the subclass type or its subtypes

```java
class Animal {
    protected String name;
    protected void breathe() { }  // subclasses can call and override
}
class Dog extends Animal {
    void bark() { breathe(); }    // fine — inherited access
}
```

**Subtlety** — a subclass in a different package can access `protected` members through `this` or its own type, but not through a reference of the parent type directly.

**See also** → `public`, `private`, `extends`]],

  -- ── Member modifiers ───────────────────────────────────────────────────────

  ["static"] = [[
**`static`** · Member modifier — belongs to the class, not the instance

| On | Meaning |
|----|---------|
| Field | One copy shared across all instances; initialized when class is loaded |
| Method | Callable without an instance; cannot access `this` or instance members |
| Nested class | No implicit reference to the enclosing instance |
| Initializer block | `static { }` — runs once when the class is first loaded |
| Import | `import static pkg.Class.MEMBER;` — import a static member by name |

```java
public class Counter {
    private static int count = 0;          // shared
    public static int getCount() { return count; }
    public Counter() { count++; }          // each new instance increments
}
```

**Common uses** — factory methods (`List.of()`), utility classes (`Math`, `Collections`), constants (`static final`), singleton pattern.

**See also** → `final`, `class`]],

  ["final"] = [[
**`final`** · Modifier — prevents modification / extension

| On | Effect |
|----|--------|
| Class | Cannot be subclassed (`String`, `Integer`, all primitive wrappers) |
| Method | Cannot be overridden (can still be called polymorphically) |
| Field | Must be assigned exactly once — at declaration **or** in every constructor path |
| Local variable / parameter | Cannot be reassigned (effectively final if never reassigned anyway) |

```java
public final class ImmutablePoint {
    public final int x, y;
    public ImmutablePoint(int x, int y) { this.x = x; this.y = y; }
}
```

**Blank final field** — declared without initializer, assigned in constructor:
```java
class Circle {
    final double radius;
    Circle(double r) { this.radius = r; }  // must assign here
}
```

**Effectively final** — Java 8+: a variable that is never reassigned after initialization can be used in lambdas/anonymous classes without the `final` keyword.

**See also** → `sealed`, `static`, `record`]],

  ["synchronized"] = [[
**`synchronized`** · Modifier / statement — mutual exclusion

**Method form** — locks on `this` (instance) or the Class object (static):
```java
public synchronized void increment() { count++; }
public static synchronized void classLock() { ... }
```

**Block form** — finer-grained; explicit monitor object:
```java
synchronized (lockObject) {
    // only one thread at a time in this block
}
```

**Guarantees**
1. **Atomicity** — the locked region executes without interleaving
2. **Visibility** — changes made inside the block are visible to the next thread that acquires the same lock

**Common pitfalls**
- Synchronizing on `this` exposes the lock to callers — prefer a private lock object
- `synchronized` does not prevent deadlock; always acquire locks in a consistent order
- High contention → use `java.util.concurrent` (e.g. `ReentrantLock`, `AtomicInteger`)

**See also** → `volatile`, `java.util.concurrent`]],

  ["volatile"] = [[
**`volatile`** · Field modifier — visibility across threads

```java
private volatile boolean running = true;
```

**Guarantees**
- Reads always see the **most recent write** (no CPU cache/register hiding)
- Writes are immediately visible to all threads

**Does NOT guarantee**
- Atomicity for compound operations (read-modify-write like `count++`)
- Use `AtomicInteger`, `AtomicLong`, `AtomicReference`, or `synchronized` for those

**Canonical use** — a stop flag read by one thread, written by another:
```java
class Worker implements Runnable {
    private volatile boolean stop = false;
    public void run()  { while (!stop) { work(); } }
    public void stop() { stop = true; }
}
```

**See also** → `synchronized`, `java.util.concurrent.atomic`]],

  ["transient"] = [[
**`transient`** · Field modifier — excluded from serialization

```java
class Session implements Serializable {
    private String username;
    private transient Socket connection;  // not serialized
    private transient char[] password;    // sensitive — excluded
}
```

When an object is serialized with `ObjectOutputStream`, `transient` fields are skipped and restored to their default values on deserialization (`null`, `0`, `false`).

**Use for** — fields that are: derived/cached (can be recomputed), environment-specific (threads, file handles, network connections), or sensitive.

**See also** → `Serializable`, `ObjectOutputStream`]],

  ["native"] = [[
**`native`** · Method modifier — implemented in platform code via JNI

```java
public native int doNativeThing(byte[] data, int len);
```

Declares that the method body is provided by a native library (C/C++ compiled for the current platform) loaded with `System.loadLibrary("mylib")`.

**Key facts**
- No method body in Java source
- Types map via JNI: `int`↔`jint`, `String`↔`jstring`, `byte[]`↔`jbyteArray`, etc.
- Used by the JDK itself for low-level I/O, memory, signals
- Modern alternative: **Project Panama** (`java.lang.foreign`) — safer, no JNI boilerplate

**See also** → `System.loadLibrary`, `java.lang.foreign`]],

  -- ── Primitive types ────────────────────────────────────────────────────────

  ["int"] = [[
**`int`** · Primitive — 32-bit signed two's complement integer

| Property | Value |
|----------|-------|
| Size | 32 bits |
| Range | −2,147,483,648 to 2,147,483,647 |
| Default | `0` |
| Wrapper | `Integer` |
| Literal suffix | none (`42`, `-7`) |
| Hex / binary literals | `0xFF`, `0b1010_1100` |

**Auto-boxing** — `int` ↔ `Integer` is handled automatically; be aware of `NullPointerException` when unboxing a null `Integer`.

**Overflow** — wraps silently; for big numbers use `long` or `BigInteger`.

**See also** → `long`, `Integer`, `Math`]],

  ["long"] = [[
**`long`** · Primitive — 64-bit signed integer

| Property | Value |
|----------|-------|
| Size | 64 bits |
| Range | −2⁶³ to 2⁶³−1 (≈ ±9.2 × 10¹⁸) |
| Default | `0L` |
| Wrapper | `Long` |
| Literal suffix | `L` or `l` (prefer uppercase: `100L`) |

Use when values may exceed `int` range: timestamps (`System.currentTimeMillis()`), file sizes, IDs from large databases.

**See also** → `int`, `Long`, `BigInteger`]],

  ["double"] = [[
**`double`** · Primitive — 64-bit IEEE 754 floating point

| Property | Value |
|----------|-------|
| Size | 64 bits |
| Precision | ~15–17 significant decimal digits |
| Default | `0.0` |
| Wrapper | `Double` |
| Special values | `Double.NaN`, `Double.POSITIVE_INFINITY`, `Double.NEGATIVE_INFINITY` |

Default type for floating-point literals (`3.14`, `1e-10`). Use `float` only when memory is critical and reduced precision is acceptable.

**Warning** — not suitable for monetary calculations: use `BigDecimal`.

**See also** → `float`, `Double`, `BigDecimal`, `Math`]],

  ["float"] = [[
**`float`** · Primitive — 32-bit IEEE 754 floating point

| Property | Value |
|----------|-------|
| Size | 32 bits |
| Precision | ~6–7 significant decimal digits |
| Default | `0.0f` |
| Wrapper | `Float` |
| Literal suffix | `f` or `F` (required: `1.5f`) |

Prefer `double` unless you have a specific reason (e.g. OpenGL, audio buffers, memory-sensitive large arrays).

**See also** → `double`, `Float`]],

  ["boolean"] = [[
**`boolean`** · Primitive — logical truth value

| Property | Value |
|----------|-------|
| Values | `true`, `false` |
| Default | `false` |
| Wrapper | `Boolean` |

Cannot be cast to or from numeric types (unlike C/C++).

**Auto-boxing** — `boolean` ↔ `Boolean`; a null `Boolean` throws `NullPointerException` when unboxed in an `if` condition.

**See also** → `Boolean`, `true`, `false`]],

  ["byte"] = [[
**`byte`** · Primitive — 8-bit signed integer

| Property | Value |
|----------|-------|
| Range | −128 to 127 |
| Default | `0` |
| Wrapper | `Byte` |

Primarily useful for raw binary data (network buffers, file I/O). Arithmetic on `byte` operands auto-promotes to `int`; cast back explicitly: `(byte)(a + b)`.

**See also** → `short`, `int`, `InputStream`]],

  ["short"] = [[
**`short`** · Primitive — 16-bit signed integer

| Property | Value |
|----------|-------|
| Range | −32,768 to 32,767 |
| Default | `0` |
| Wrapper | `Short` |

Rarely used in modern code; arithmetic auto-promotes to `int`. Useful for legacy binary formats or very large arrays where memory matters.

**See also** → `byte`, `int`]],

  ["char"] = [[
**`char`** · Primitive — 16-bit unsigned Unicode code unit (UTF-16)

| Property | Value |
|----------|-------|
| Range | `' '` to `'￿'` |
| Default | `' '` (null character) |
| Wrapper | `Character` |
| Literal | `'A'`, `'\n'`, `'α'` |

**Gotchas**
- Represents a *code unit*, not a code *point* — characters outside the BMP (emoji, some CJK) require a surrogate pair (two `char` values)
- Arithmetic on `char` auto-promotes to `int`
- Use `String`, `StringBuilder`, or `Character` utilities for serious text work

**See also** → `String`, `Character`, `Character.codePointAt`]],

  ["void"] = [[
**`void`** · Return type — method returns no value

```java
public void doWork() {
    perform();
    // no return statement needed (bare "return;" is allowed)
}
```

**`Void`** (capital V) — the wrapper class; used in generics where a type parameter is required but no value is meaningful:
```java
Future<Void> task = executor.submit(() -> { doWork(); return null; });
Callable<Void> c  = () -> { doWork(); return null; };
```

**See also** → `return`, `Runnable`, `Callable`]],

  ["var"] = [[
**`var`** · Local variable type inference  *(Java 10+)*

```java
var list    = new ArrayList<String>();  // inferred: ArrayList<String>
var map     = Map.of("a", 1, "b", 2);  // inferred: Map<String, Integer>
var entry   = map.entrySet().iterator().next(); // no need to write out the type
```

**Rules**
- Only valid for **local variables** with an initializer
- NOT valid for: fields, method parameters, return types, `catch` variables (pre-Java 16)
- The inferred type is the **static** type of the initializer expression — not a dynamic type

**Lambda + generic inference**
```java
// var cannot be used for lambda parameters by itself:
var fn = (String s) -> s.length();  // ERROR — lambda needs a target type
// But OK with explicit param types in Java 11+:
(var s) -> s.length()               // allowed in lambda params (Java 11+)
```

**See also** → `instanceof`, `record`]],

  -- ── Control flow ──────────────────────────────────────────────────────────

  ["if"] = [[
**`if`** · Conditional branch

```java
if (condition) {
    // executes when condition is true
} else if (other) {
    // next alternative
} else {
    // fallback
}
```

**Short-circuit evaluation** — `&&` and `||` stop early:
```java
if (obj != null && obj.isReady()) { }  // safe: null check first
```

**Ternary** — inline single-expression alternative:
```java
int max = a > b ? a : b;
```

**See also** → `switch`, `instanceof`]],

  ["switch"] = [[
**`switch`** · Multi-way dispatch  *(traditional and expression forms)*

**Arrow-form expression** *(Java 14+)* — no fall-through, can return a value:
```java
String day = switch (dayOfWeek) {
    case MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY -> "Weekday";
    case SATURDAY, SUNDAY -> "Weekend";
};
```

**`yield`** — return a value from a multi-statement arm:
```java
int code = switch (status) {
    case OK      -> 200;
    case MISSING -> { log("missing"); yield 404; }
    default      -> 500;
};
```

**Pattern matching** *(Java 21+)*:
```java
String desc = switch (obj) {
    case Integer i when i < 0 -> "negative int";
    case Integer i             -> "int " + i;
    case String  s             -> "string";
    case null                  -> "null";
    default                    -> "other";
};
```

**Classic colon-form** (still valid) — explicit `break` needed to prevent fall-through.

**Supported selector types**: `int`/`byte`/`short`/`char` (and wrappers), `String`, `enum`, any type in pattern switch.

**See also** → `enum`, `sealed`, `yield`, `instanceof`]],

  ["for"] = [[
**`for`** · Loop

**Classic C-style**:
```java
for (int i = 0; i < n; i++) { }
for (int i = n - 1; i >= 0; i--) { }
for (;;) { /* infinite */ }
```

**Enhanced for-each** (any `Iterable` or array):
```java
for (String item : collection) { }
for (int x : intArray)         { }
```

**Common patterns**
```java
// iterate with index over a list:
for (int i = 0; i < list.size(); i++) { var item = list.get(i); }

// stream alternative for complex transforms:
list.stream().filter(...).map(...).forEach(...);
```

**See also** → `while`, `break`, `continue`, `Iterator`]],

  ["while"] = [[
**`while`** · Pre-condition loop

```java
while (condition) {
    body;
}
// body executes zero or more times; condition checked BEFORE each iteration
```

**`do...while`** — body executes at least once; condition checked AFTER:
```java
do {
    body;
} while (condition);
```

**See also** → `for`, `break`, `continue`]],

  ["do"] = [[
**`do`** · Post-condition loop (`do...while`)

```java
do {
    body;
} while (condition);
```

Body executes **at least once** — condition is checked after each iteration. Useful for input loops where you must execute before you can check:
```java
String input;
do {
    input = scanner.nextLine();
} while (input.isBlank());
```

**See also** → `while`, `for`]],

  ["break"] = [[
**`break`** · Exit loop or switch

**Simple** — exits the innermost `for`, `while`, `do`, or `switch`:
```java
for (int i = 0; i < n; i++) {
    if (found(i)) { break; }
}
```

**Labeled** — exits the named outer statement:
```java
outer:
for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
        if (grid[i][j] == target) break outer;
    }
}
```

**See also** → `continue`, `return`, `switch`]],

  ["continue"] = [[
**`continue`** · Skip to next loop iteration

**Simple** — skips the rest of the current iteration in the innermost loop:
```java
for (String s : list) {
    if (s.isBlank()) continue;
    process(s);
}
```

**Labeled** — continues the named outer loop:
```java
outer:
for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
        if (skip(i, j)) continue outer;
        process(i, j);
    }
}
```

**See also** → `break`, `for`, `while`]],

  ["return"] = [[
**`return`** · Exit method, optionally with a value

```java
// void method — bare return (optional at end)
public void process() {
    if (error) return;   // early exit
    doWork();
}

// non-void — must return a compatible value
public int add(int a, int b) {
    return a + b;
}
```

**In a switch expression** — use `yield` instead of `return` to produce the switch result.

**See also** → `yield`, `void`]],

  ["yield"] = [[
**`yield`** · Produce switch expression value  *(Java 14+)*

Used inside a **block arm** (`case X -> { ... }`) of a switch expression to return the arm's value:
```java
int result = switch (mode) {
    case FAST  -> compute();                   // arrow — no yield needed
    case SAFE  -> {
        validate();
        yield computeSafely();                 // block — yield required
    }
    default    -> throw new AssertionError();
};
```

`yield` is a context keyword — it is only a keyword inside a switch expression block; elsewhere it is a valid identifier (though using it as an identifier is discouraged).

**See also** → `switch`, `return`]],

  -- ── Object model ──────────────────────────────────────────────────────────

  ["new"] = [[
**`new`** · Object / array allocation

**Object**:
```java
Foo f = new Foo(arg1, arg2);
```

**Array**:
```java
int[]    arr  = new int[10];
String[] strs = new String[]{"a", "b", "c"};
int[][]  grid = new int[4][4];
```

**Anonymous class** — single-use subclass or implementation:
```java
Runnable r = new Runnable() {
    @Override public void run() { doWork(); }
};
```
(Prefer lambdas for functional interfaces.)

**Key facts**
- Allocates on the heap; GC handles deallocation
- Always calls a constructor (or the default no-arg constructor if none is declared)
- For arrays of reference types, elements initialise to `null`

**See also** → `class`, `interface`, `instanceof`]],

  ["this"] = [[
**`this`** · Reference to the current instance

**Disambiguate field from local/parameter**:
```java
class Point {
    int x, y;
    Point(int x, int y) { this.x = x; this.y = y; }
}
```

**Constructor delegation** — must be the very first statement:
```java
class Circle {
    Circle()          { this(0, 0, 1.0); }
    Circle(int x, int y, double r) { /* canonical */ }
}
```

**Pass current instance**:
```java
builder.withCallback(this);
```

**`this` capture in lambdas** — unlike anonymous classes, lambdas do NOT have their own `this`; `this` inside a lambda refers to the enclosing instance.

**See also** → `super`, `new`]],

  ["super"] = [[
**`super`** · Reference to the superclass

**Call overridden method**:
```java
@Override public String toString() {
    return super.toString() + ", extra=" + extra;
}
```

**Invoke superclass constructor** — must be the very first statement in a constructor:
```java
class Dog extends Animal {
    Dog(String name) {
        super(name);   // Animal(String) constructor
        this.breed = "unknown";
    }
}
```

**Key facts**
- If you don't call `super(...)` explicitly, the compiler inserts a no-arg `super()` call automatically
- Cannot use `super` in a `static` context
- In interfaces, `InterfaceName.super.method()` calls a specific `default` method

**See also** → `extends`, `this`]],

  -- ── Exception handling ─────────────────────────────────────────────────────

  ["try"] = [[
**`try`** · Exception handling block

**Standard form**:
```java
try {
    riskyOperation();
} catch (IOException e) {
    log("IO error", e);
} catch (IllegalArgumentException e) {
    throw new RuntimeException("bad arg", e);
} finally {
    cleanup();    // ALWAYS runs — even if an exception propagates
}
```

**Try-with-resources** *(Java 7+)* — auto-closes `AutoCloseable` resources:
```java
try (var in  = new FileInputStream(src);
     var out = new FileOutputStream(dst)) {
    in.transferTo(out);
}
// in and out are closed here, in reverse order, even if an exception occurs
```

**Multi-catch** *(Java 7+)*:
```java
catch (IOException | SQLException e) { handle(e); }
```

**See also** → `catch`, `finally`, `throw`, `throws`]],

  ["catch"] = [[
**`catch`** · Exception handler clause

```java
try { ... }
catch (SpecificException e) { /* most specific first */ }
catch (ParentException e)   { /* broader fallback    */ }
```

**Multi-catch** *(Java 7+)* — handle unrelated exceptions identically:
```java
catch (IOException | ParseException e) {
    log(e);    // e is effectively final
}
```

**Key facts**
- Handlers are tried in order — put subclasses before superclasses
- `e` in multi-catch is effectively final; cannot be reassigned
- Catching `Throwable` or `Error` is rarely appropriate outside frameworks

**Exception hierarchy**
```
Throwable
├─ Error          (OutOfMemoryError, StackOverflowError — don't catch)
└─ Exception
   ├─ checked     (IOException, SQLException — must catch or declare)
   └─ RuntimeException (unchecked — NullPointerException, etc.)
```

**See also** → `try`, `finally`, `throw`, `throws`]],

  ["finally"] = [[
**`finally`** · Unconditional cleanup block

```java
try {
    acquire();
    work();
} finally {
    release();   // runs even if work() throws or returns early
}
```

**Always executes** — except when:
- `System.exit()` is called
- The JVM crashes or the process is killed
- The thread is abruptly stopped (rare)

**Return in finally** — overrides any `return` or exception from the `try`/`catch` block (strongly discouraged; causes hard-to-trace bugs).

**Prefer try-with-resources** for `AutoCloseable` resources — cleaner and handles suppressed exceptions correctly.

**See also** → `try`, `catch`, `AutoCloseable`]],

  ["throw"] = [[
**`throw`** · Raise an exception

```java
throw new IllegalArgumentException("value must be positive: " + value);
throw new UnsupportedOperationException("not implemented");
throw ex;   // rethrow a caught exception
```

**Good practice**
- Include a descriptive message with the bad value: `"expected > 0, got: " + n`
- Wrap exceptions to preserve cause: `throw new ServiceException("failed", cause)`
- Use standard exceptions from `java.lang` before creating custom ones

**Common standard exceptions**
- `IllegalArgumentException` — bad input value
- `IllegalStateException` — object in wrong state for this call
- `NullPointerException` — null where not allowed (can throw explicitly)
- `UnsupportedOperationException` — optional operation not implemented
- `IndexOutOfBoundsException` — index out of valid range

**See also** → `throws`, `try`, `catch`, `Exception`]],

  ["throws"] = [[
**`throws`** · Checked exception declaration

```java
public void readFile(Path p) throws IOException, ParseException {
    // callers must catch or also declare these exceptions
}
```

**Checked vs unchecked**
- **Checked** (`Exception` subclasses excluding `RuntimeException`) — must be declared in `throws` or caught
- **Unchecked** (`RuntimeException`, `Error`) — do not need to be declared (but can be)

**Key facts**
- `throws` is part of the method's contract — it's documentation as much as enforcement
- Declaring `throws Exception` is legal but defeats the purpose
- Lambdas cannot throw checked exceptions unless the functional interface declares them

**See also** → `throw`, `try`, `catch`, `Exception`]],

  -- ── Other ─────────────────────────────────────────────────────────────────

  ["import"] = [[
**`import`** · Bring a type or static member into scope

```java
import java.util.List;                  // single type
import java.util.*;                     // wildcard (all public types in package)
import static java.lang.Math.PI;        // static field
import static java.lang.Math.*;         // all static members of Math
```

**Key facts**
- Only a compile-time shortcut — has no effect on runtime performance
- Types in `java.lang` are always in scope (no import needed): `String`, `Object`, `Integer`, `Math`, etc.
- Wildcard imports do NOT import sub-packages
- Static imports are useful for constants (`PI`, `E`) and utility methods (`abs`, `max`)

**See also** → `package`]],

  ["package"] = [[
**`package`** · Compilation unit namespace

```java
package com.example.myapp.service;
```

- Must be the **first non-comment statement** in a `.java` file
- Maps to a directory path on the filesystem (`com/example/myapp/service/`)
- Classes in the same package have package-private access to each other
- The unnamed package (no `package` declaration) is valid for small experiments but not production code

**Naming conventions** — reverse domain name, lowercase, no hyphens:
`com.company.product.component`

**See also** → `import`]],

  ["assert"] = [[
**`assert`** · Runtime assertion *(disabled by default)*

```java
assert condition;
assert condition : "diagnostic message: " + value;
```

Throws `AssertionError` when the condition is false **and** assertions are enabled.

**Enable at JVM startup**: `java -ea MyApp` (or `-enableassertions`).
Disable selectively: `-da:com.example.untrusted...`

**Use assert for**
- Internal invariants ("this should never happen")
- Post-conditions after complex algorithms
- NOT for argument validation in public APIs (use `Objects.requireNonNull`, `IllegalArgumentException` instead — those throw regardless of `-ea`)

**See also** → `throw`, `Objects.requireNonNull`]],

  ["null"] = [[
**`null`** · Absent reference literal

Any reference type can hold `null`. `null` has no type of its own but is assignment-compatible with all reference types.

**`null` is NOT**
- An instance of any class (`null instanceof X` is always `false`)
- A valid receiver for method calls (`null.method()` → `NullPointerException`)

**Defensive patterns**
```java
// Null-safe equality — put the known non-null side first:
"expected".equals(userInput);

// Objects utility (Java 7+):
Objects.requireNonNull(arg, "arg must not be null");
Objects.requireNonNullElse(value, defaultValue);

// Optional (Java 8+) — makes optionality explicit in the type:
Optional<String> name = Optional.ofNullable(maybeNull);
name.ifPresent(System.out::println);
```

**Pattern matching handles null** *(Java 21+)*:
```java
switch (obj) {
    case null   -> handleNull();
    case String s -> handleString(s);
}
```

**See also** → `Optional`, `Objects`, `instanceof`]],

  ["true"]  = "**`true`** — boolean literal: the only other value besides `false`. Type: `boolean`.",
  ["false"] = "**`false`** — boolean literal. Default value for `boolean` fields and array elements. Type: `boolean`.",
}
