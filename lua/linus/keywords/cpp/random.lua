-- linus/keywords/cpp/random.lua
-- Random number generation (<random>).

return {

  ["mt19937"] = [[
**`std::mt19937`** · Mersenne Twister 32-bit PRNG (`<random>`)

```cpp
#include <random>
std::random_device rd;
std::mt19937 gen(rd());               // seed with hardware entropy

std::uniform_int_distribution<int> dist(1, 6);
int roll = dist(gen);                 // die roll [1, 6]
```

Period: 2¹⁹⁹³⁷ − 1 (enormous). State: ~2.5 KiB. Common variant: `std::mt19937_64` (64-bit).

**Do not** seed with `time(nullptr)` — use `std::random_device` or `std::seed_seq` for proper seeding.

**See also →** `std::mt19937_64`, `std::random_device`, `std::uniform_int_distribution`, `std::seed_seq`]],

  ["random_device"] = [[
**`std::random_device`** · Non-deterministic random number source (`<random>`)

```cpp
std::random_device rd;
int entropy = rd.entropy();           // may return 0 if deterministic
int value = rd();                     // a random unsigned int
```

On most platforms: reads from `/dev/urandom` or uses hardware RNG. May be deterministic on embedded systems (check `.entropy()`).

**See also →** `std::mt19937`, `std::seed_seq`]],

  ["uniform_int_distribution"] = [[
**`std::uniform_int_distribution`** · Integer uniform distribution (`<random>`)

```cpp
std::uniform_int_distribution<int> dist(0, 99);  // [0, 99] inclusive
int n = dist(gen);
```

**Both endpoints inclusive.** For exclusive upper bound, subtract 1 or use `std::uniform_real_distribution`.

**See also →** `std::uniform_real_distribution`, `std::normal_distribution`, `std::poisson_distribution`, `std::binomial_distribution`]],

  ["uniform_real_distribution"] = [[
**`std::uniform_real_distribution`** · Real uniform distribution (`<random>`)

```cpp
std::uniform_real_distribution<double> dist(0.0, 1.0);  // [0.0, 1.0)
double r = dist(gen);
```

**Half-open interval** `[a, b)` — includes `a`, excludes `b`.

**See also →** `std::uniform_int_distribution`, `std::normal_distribution`]],

  ["normal_distribution"] = [[
**`std::normal_distribution`** · Normal (Gaussian) distribution (`<random>`)

```cpp
std::normal_distribution<double> dist(mean=0.0, stddev=1.0);
double val = dist(gen);               // mostly [-3σ, 3σ]
```

**See also →** `std::uniform_real_distribution`, `std::lognormal_distribution`, `std::cauchy_distribution`]],

  ["bernoulli_distribution"] = [[
**`std::bernoulli_distribution`** · Bernoulli distribution (coin flip) (`<random>`)

```cpp
std::bernoulli_distribution fair(0.5);
std::bernoulli_distribution biased(0.7);
if (fair(gen)) { /* heads (50% of the time) */ }
```

Returns `bool`. Single parameter `p` = probability of `true`.

**See also →** `std::binomial_distribution`, `std::discrete_distribution`]],

  ["binomial_distribution"] = [[
**`std::binomial_distribution`** · Binomial distribution (`<random>`)

```cpp
std::binomial_distribution<int> dist(trials=10, prob=0.5);
int heads = dist(gen);                // number of heads in 10 flips
```

**See also →** `std::bernoulli_distribution`, `std::poisson_distribution`, `std::negative_binomial_distribution`]],

  ["poisson_distribution"] = [[
**`std::poisson_distribution`** · Poisson distribution (`<random>`)

```cpp
std::poisson_distribution<int> dist(mean=1.0);
int events = dist(gen);
```

Models number of events in a fixed interval with given average rate.

**See also →** `std::binomial_distribution`, `std::exponential_distribution`, `std::gamma_distribution`]],

  ["discrete_distribution"] = [[
**`std::discrete_distribution`** · Weighted integer distribution (`<random>`)

```cpp
std::discrete_distribution<int> dist({10, 20, 70});  // weights 10%, 20%, 70%
int idx = dist(gen);  // 0, 1, or 2
```

Weights don't need to sum to any particular value — relative weights.

**See also →** `std::piecewise_constant_distribution`, `std::piecewise_linear_distribution`, `std::uniform_int_distribution`]],

  ["seed_seq"] = [[
**`std::seed_seq`** · Seed sequence for PRNGs (`<random>`)

```cpp
std::seed_seq seq{1, 2, 3, 4, 5};
std::mt19937 gen(seq);
```

Warms up the generator better than a single integer seed. Fills with a burn-in of the seed sequence to reduce correlation between seeds.

**See also →** `std::mt19937`, `std::random_device`]],
}
