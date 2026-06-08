-- linus/keywords/cpp/threading.lua
-- Thread support library: threads, mutexes, futures, atomics.

return {

  ["thread"] = [[
**`std::thread`** · Independent thread of execution (`<thread>`, C++11)

```cpp
#include <thread>
std::thread t([]{ work(); });
t.join();                         // wait for completion

std::thread t2;
t2 = std::thread(f);
t2.detach();                      // let it run independently

unsigned n = std::thread::hardware_concurrency(); // cores/threads hint
```

**Must** call `join()` or `detach()` before `std::thread` destructor — otherwise calls `std::terminate`. Copy-deleted; move-only.

**See also →** `std::jthread` (C++20), `std::async`, `std::mutex`, `std::this_thread::`]],

  ["jthread"] = [[
**`std::jthread`** · Joining thread with built-in stop support (`<thread>`, C++20)

```cpp
#include <thread>
std::jthread jt([]{ while (!stop_token.stop_requested()) work(); });
// destructor automatically joins
```

Automatically `join()`s on destruction (no manual join/detach needed). Supports cooperative cancellation via `std::stop_token`.

**See also →** `std::thread`, `std::stop_token`, `std::stop_source`, `std::jthread::request_stop`]],

  ["mutex"] = [[
**`std::mutex`** · Basic mutual exclusion (`<mutex>`, C++11)

```cpp
#include <mutex>
std::mutex m;
{
    std::lock_guard<std::mutex> lock(m);
    // critical section
}
```

Non-recursive. Calling `lock()` from the same thread without unlocking first = **deadlock**. Use `std::recursive_mutex` if reentrant locking is needed (but reconsider design).

**See also →** `std::lock_guard`, `std::unique_lock`, `std::scoped_lock` (C++17), `std::recursive_mutex`, `std::timed_mutex`]],

  ["recursive_mutex"] = [[
**`std::recursive_mutex`** · Mutex that can be locked multiple times by the same thread (`<mutex>`, C++11)

```cpp
std::recursive_mutex m;
m.lock();               // acquire
m.lock();               // acquire again (same thread, OK)
m.unlock();             // must match lock count
m.unlock();
```

**Slightly slower** than `std::mutex`. Usually a sign of design issues.

**See also →** `std::mutex`, `std::timed_mutex`, `std::lock_guard`]],

  ["timed_mutex"] = [[
**`std::timed_mutex`** · Mutex with timeout support (`<mutex>`, C++11)

```cpp
std::timed_mutex m;
if (m.try_lock_for(std::chrono::milliseconds(100))) {
    // acquired within 100ms
    m.unlock();
}
```

**See also →** `std::mutex`, `std::recursive_timed_mutex`, `std::unique_lock`, `std::try_to_lock`]],

  ["lock_guard"] = [[
**`std::lock_guard`** · RAII mutex wrapper (simple, C++11)

```cpp
{
    std::lock_guard<std::mutex> lock(m);
    // m is locked, automatically unlocked at scope exit
}
```

**Lighter** than `unique_lock` (no deferred/timed lock). C++17's class template argument deduction: `std::lock_guard lock(m);`.

**See also →** `std::unique_lock`, `std::scoped_lock` (C++17), `std::mutex`]],

  ["unique_lock"] = [[
**`std::unique_lock`** · RAII mutex wrapper (flexible, C++11)

```cpp
std::unique_lock<std::mutex> lock(m, std::defer_lock);  // don't lock yet
lock.lock();                      // manually lock
auto* mtx = lock.mutex();         // get the underlying mutex
lock.unlock();                    // release early (RAII still guards)

// Condition variable usage:
cv.wait(lock, []{ return ready; });
```

More flexibility than `lock_guard`: deferred locking, timed locking, manual unlock, ownership transfer.

**See also →** `std::lock_guard`, `std::scoped_lock` (C++17), `std::condition_variable`, `std::defer_lock`]],

  ["scoped_lock"] = [[
**`std::scoped_lock`** · RAII mutex wrapper (variadic, deadlock-safe, C++17)

```cpp
std::scoped_lock lock(m1, m2);   // locks both (deadlock-safe)
// ... critical section using both mutexes ...
```

**Prefer over multiple `lock_guard`** when locking >1 mutex. Uses deadlock-avoidance algorithm (same as `std::lock`).

**See also →** `std::lock_guard`, `std::unique_lock`, `std::lock`, `std::mutex`]],

  ["condition_variable"] = [[
**`std::condition_variable`** · Block thread until notified (`<condition_variable>`, C++11)

```cpp
std::mutex m;
std::condition_variable cv;
bool ready = false;

// waiter:
{
    std::unique_lock<std::mutex> lock(m);
    cv.wait(lock, []{ return ready; });    // atomically unlock + wait
}

// notifier:
{
    std::lock_guard<std::mutex> lock(m);
    ready = true;
}
cv.notify_one();      // or notify_all()
```

**Spurious wakeups** — always use the predicate overload of `wait()`. Must hold a `unique_lock` (not `lock_guard`).

**See also →** `std::condition_variable_any` (works with any BasicLockable), `std::notify_all_at_thread_exit`]],

  ["future"] = [[
**`std::future`** · Asynchronous return value placeholder (`<future>`, C++11)

```cpp
std::future<int> fut = std::async([] { return 42; });
int result = fut.get();             // blocks until result is ready

std::future_status st = fut.wait_for(100ms);  // check without blocking
```

Can only call `get()` **once** (moves the value). For shared results, use `std::shared_future`.

**See also →** `std::async`, `std::promise`, `std::packaged_task`, `std::shared_future`]],

  ["shared_future"] = [[
**`std::shared_future`** · Results that can be queried multiple times (`<future>`, C++11)

```cpp
std::shared_future<int> sf = std::async([] { return 42; }).share();
int a = sf.get();   // first call
int b = sf.get();   // second call (OK — shared_future is copyable)
```

Copyable. `get()` can be called many times; returns a const reference to the (immutable) result.

**See also →** `std::future`, `std::async`, `std::promise`]],

  ["async"] = [[
**`std::async`** · Asynchronous function invocation (`<future>`, C++11)

```cpp
auto fut = std::async(std::launch::async, []{ return compute(); });
auto fut = std::async(std::launch::deferred, []{ return lazy(); });
auto fut = std::async([] { ... });       // implementation chooses policy
```

`std::launch::async` = new thread. `std::launch::deferred` = lazy (run on `get()`). Default = either.

**Warning:** the returned `std::future` destructor may block until completion in some cases — keep the future alive.

**See also →** `std::future`, `std::promise`, `std::packaged_task`]],

  ["promise"] = [[
**`std::promise`** · Store a value for a future (`<future>`, C++11)

```cpp
std::promise<int> p;
std::future<int> f = p.get_future();

std::thread t([p = std::move(p)] mutable {
    p.set_value(42);
});

int result = f.get();   // blocks until set_value
t.join();
```

**One-shot** — `set_value` can only be called once. `set_exception` stores an exception that `get()` will rethrow.

**See also →** `std::future`, `std::async`, `std::packaged_task`]],

  ["packaged_task"] = [[
**`std::packaged_task`** · Wrap callable as a future (`<future>`, C++11)

```cpp
std::packaged_task<int()> task([]{ return 42; });
std::future<int> fut = task.get_future();
std::thread t(std::move(task));   // runs in thread
int result = fut.get();
t.join();
```

**See also →** `std::future`, `std::async`, `std::promise`]],

  ["atomic"] = [[
**`std::atomic`** · Lock-free atomic operations (`<atomic>`, C++11)

```cpp
#include <atomic>
std::atomic<int> counter{0};
counter.fetch_add(1);             // atomic increment
int old = counter.exchange(42);   // atomic exchange
bool ok = counter.compare_exchange_weak(expected, desired);  // CAS

counter.store(0);                 // atomic store (default seq_cst)
int val = counter.load();         // atomic load
```

**Lock-free** for integral/pointer types on most platforms. For user-defined types, may use internal mutex (check `.is_lock_free()`).

**Memory ordering:** default is `std::memory_order_seq_cst` (strongest). Relaxed ordering: `counter.fetch_add(1, std::memory_order_relaxed)`.

**See also →** `std::atomic_flag`, `std::memory_order`, `std::mutex`, `std::barrier` (C++20)]],

  ["atomic_flag"] = [[
**`std::atomic_flag`** · The simplest atomic type (`<atomic>`, C++11)

```cpp
std::atomic_flag lock = ATOMIC_FLAG_INIT;  // C++11
std::atomic_flag lock;                     // C++20: cleared by default

while (lock.test_and_set());   // spinlock acquire
// critical section
lock.clear();                  // spinlock release
```

Guaranteed **lock-free** on all platforms. Only two operations: `test_and_set` (TAS) and `clear`. No load/store.

**See also →** `std::atomic`, `std::memory_order`, `std::mutex`]],

  ["call_once"] = [[
**`std::call_once`** · Execute a callable exactly once (`<mutex>`, C++11)

```cpp
std::once_flag flag;
void lazy_init() {
    std::call_once(flag, []{ /* runs exactly once */ });
}
```

Thread-safe — multiple threads may invoke `call_once` on the same flag; only one wins.

**See also →** `std::once_flag`, `std::mutex`, function-local `static` (also thread-safe since C++11)]],

  ["this_thread"] = [[
**`std::this_thread`** · Control the current thread (`<thread>`, C++11)

```cpp
using namespace std::chrono_literals;
std::this_thread::sleep_for(100ms);        // sleep for duration
std::this_thread::sleep_until(tp);          // sleep until time point
std::this_thread::yield();                  // reschedule (hint)
std::thread::id tid = std::this_thread::get_id();  // current thread id
```

**See also →** `std::thread`, `std::jthread`, `std::stop_token`]],

  ["barrier"] = [[
**`std::barrier`** · Reusable synchronization barrier (`<barrier>`, C++20)

```cpp
#include <barrier>
std::barrier sync(3, []{ /* completion function */ });
// 3 threads:
sync.arrive_and_wait();     // blocks until all 3 arrive
```

Each phase: all threads arrive, then the completion function runs, then all proceed. Reusable across multiple phases.

**See also →** `std::latch` (C++20, single-use), `std::semaphore` (C++20)]],

  ["latch"] = [[
**`std::latch`** · Single-use synchronization point (`<latch>`, C++20)

```cpp
std::latch done(3);          // count of 3
// thread 1:
done.arrive_and_wait();      // decrement + block until 0
// thread 2:
done.count_down();           // just decrement
```

**Single-use** — count cannot be reset. Simpler than `std::barrier` for one-time coordination.

**See also →** `std::barrier` (C++20, reusable), `std::counting_semaphore` (C++20)]],

  ["counting_semaphore"] = [[
**`std::counting_semaphore`** · Semaphore with a counter (`<semaphore>`, C++20)

```cpp
#include <semaphore>
std::counting_semaphore<10> sem(3);   // max 10, initial 3
sem.acquire();              // decrement (block if 0)
sem.release();              // increment (wake a waiter)
```

Binary semaphore: `std::binary_semaphore` — specialization with max count = 1.

**See also →** `std::mutex`, `std::condition_variable`, `std::barrier`]],

  ["stop_token"] = [[
**`std::stop_token`** · Cooperative cancellation token (`<stop_token>`, C++20)

```cpp
void worker(std::stop_token st) {
    while (!st.stop_requested()) {
        work_on_chunk();
    }
}

std::jthread jt(worker);
jt.request_stop();           // signals all associated stop_tokens
```

Associated with `std::jthread` or `std::stop_source`. Poll `stop_requested()` or register a callback with `std::stop_callback`.

**See also →** `std::jthread`, `std::stop_source`, `std::stop_callback`]],
}
