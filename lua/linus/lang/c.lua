-- linus/lang/c.lua  (also used by cpp.lua via lang/cpp.lua)
-- clangd enricher: hover, doxygen doc formatting, type hierarchy, implementations, macro detection.
--
-- Hover parsing mirrors lang/java.lua exactly:
--   parse_hover_result() handles all three LSP content shapes clangd may return
--   (MarkupContent, MarkedString scalar, MarkedString[]), routes each through
--   split_sig_docs() + format_docs(), and returns (sig_lines, doc_lines).
--   fetch_hover() distinguishes "empty because keyword" from "empty because no
--   symbol here" and only retries (retry_at_symbol) for the latter — same
--   logic as jdtls in java.lua.
--   The stray tick() upvalue bug that existed in the previous fetch_hierarchy
--   has been removed; callers own their tick() calls.

local util = require('linus.lang.util')

local M = {}

-- ── Keyword sets ───────────────────────────────────────────────────────────────

local C_KEYWORDS = {
  ['auto'] = true,
  ['break'] = true,
  ['case'] = true,
  ['char'] = true,
  ['const'] = true,
  ['continue'] = true,
  ['default'] = true,
  ['do'] = true,
  ['double'] = true,
  ['else'] = true,
  ['enum'] = true,
  ['extern'] = true,
  ['float'] = true,
  ['for'] = true,
  ['goto'] = true,
  ['if'] = true,
  ['inline'] = true,
  ['int'] = true,
  ['long'] = true,
  ['register'] = true,
  ['restrict'] = true,
  ['return'] = true,
  ['short'] = true,
  ['signed'] = true,
  ['sizeof'] = true,
  ['static'] = true,
  ['struct'] = true,
  ['switch'] = true,
  ['typedef'] = true,
  ['union'] = true,
  ['unsigned'] = true,
  ['void'] = true,
  ['volatile'] = true,
  ['while'] = true,
  -- C99 / C11
  ['_Bool'] = true,
  ['_Complex'] = true,
  ['_Imaginary'] = true,
  ['_Atomic'] = true,
  ['_Generic'] = true,
  ['_Noreturn'] = true,
  ['_Static_assert'] = true,
  ['_Thread_local'] = true,
  ['_Alignas'] = true,
  ['_Alignof'] = true,
  -- common macro names treated as keywords
  ['NULL'] = true,
  ['true'] = true,
  ['false'] = true,
  -- preprocessor directives
  ['#define'] = true,
  ['#include'] = true,
  ['#ifdef'] = true,
  ['#ifndef'] = true,
  ['#endif'] = true,
  ['#pragma'] = true,
  ['#if'] = true,
  ['#else'] = true,
  ['#elif'] = true,
  ['#undef'] = true,
  ['#error'] = true,
  ['#warning'] = true,
}

local CPP_KEYWORDS = vim.tbl_extend('force', C_KEYWORDS, {
  ['alignas'] = true,
  ['alignof'] = true,
  ['and'] = true,
  ['and_eq'] = true,
  ['asm'] = true,
  ['bitand'] = true,
  ['bitor'] = true,
  ['bool'] = true,
  ['catch'] = true,
  ['class'] = true,
  ['compl'] = true,
  ['concept'] = true,
  ['consteval'] = true,
  ['constexpr'] = true,
  ['constinit'] = true,
  ['const_cast'] = true,
  ['co_await'] = true,
  ['co_return'] = true,
  ['co_yield'] = true,
  ['decltype'] = true,
  ['delete'] = true,
  ['dynamic_cast'] = true,
  ['explicit'] = true,
  ['export'] = true,
  ['final'] = true,
  ['friend'] = true,
  ['mutable'] = true,
  ['namespace'] = true,
  ['new'] = true,
  ['noexcept'] = true,
  ['not'] = true,
  ['not_eq'] = true,
  ['nullptr'] = true,
  ['operator'] = true,
  ['or'] = true,
  ['or_eq'] = true,
  ['override'] = true,
  ['private'] = true,
  ['protected'] = true,
  ['public'] = true,
  ['reinterpret_cast'] = true,
  ['requires'] = true,
  ['static_assert'] = true,
  ['static_cast'] = true,
  ['template'] = true,
  ['this'] = true,
  ['thread_local'] = true,
  ['throw'] = true,
  ['try'] = true,
  ['typeid'] = true,
  ['typename'] = true,
  ['using'] = true,
  ['virtual'] = true,
  ['wchar_t'] = true,
  ['xor'] = true,
  ['xor_eq'] = true,
})

local function is_keyword(ft, word)
  if ft == 'cpp' then
    return CPP_KEYWORDS[word]
  end
  return C_KEYWORDS[word]
end

-- ── External Documentation Pipeline ───────────────────────────────────────────────

-- Maps symbols to cppreference.com pages.
-- C symbols use the function name directly; C++ symbols use the name after `std::`.
local CPP_PAGE_MAPPING = {

  -- ── C Standard Library ──────────────────────────────────────────────────────
  -- <stdio.h>
  ['printf']    = 'c/io/fprintf',
  ['fprintf']   = 'c/io/fprintf',
  ['sprintf']   = 'c/io/sprintf',
  ['snprintf']  = 'c/io/snprintf',
  ['scanf']     = 'c/io/fscanf',
  ['fscanf']    = 'c/io/fscanf',
  ['sscanf']    = 'c/io/sscanf',
  ['vprintf']   = 'c/io/vfprintf',
  ['vfprintf']  = 'c/io/vfprintf',
  ['vsprintf']  = 'c/io/vsprintf',
  ['vsnprintf'] = 'c/io/vsnprintf',
  ['fopen']     = 'c/io/fopen',
  ['fclose']    = 'c/io/fclose',
  ['freopen']   = 'c/io/freopen',
  ['fread']     = 'c/io/fread',
  ['fwrite']    = 'c/io/fwrite',
  ['fseek']     = 'c/io/fseek',
  ['ftell']     = 'c/io/ftell',
  ['rewind']    = 'c/io/rewind',
  ['fgetc']     = 'c/io/fgetc',
  ['fputc']     = 'c/io/fputc',
  ['fgets']     = 'c/io/fgets',
  ['fputs']     = 'c/io/fputs',
  ['getc']      = 'c/io/fgetc',
  ['putc']      = 'c/io/fputc',
  ['getchar']   = 'c/io/getchar',
  ['putchar']   = 'c/io/putchar',
  ['feof']      = 'c/io/feof',
  ['ferror']    = 'c/io/ferror',
  ['clearerr']  = 'c/io/clearerr',
  ['perror']    = 'c/io/perror',
  ['ungetc']    = 'c/io/ungetc',
  ['setbuf']    = 'c/io/setbuf',
  ['setvbuf']   = 'c/io/setvbuf',
  ['tmpfile']   = 'c/io/tmpfile',
  ['tmpnam']    = 'c/io/tmpnam',
  ['remove']    = 'c/io/remove',
  ['rename']    = 'c/io/rename',
  ['fgetpos']   = 'c/io/fgetpos',
  ['fsetpos']   = 'c/io/fsetpos',

  -- <stdlib.h>
  ['malloc']         = 'c/memory/malloc',
  ['calloc']         = 'c/memory/calloc',
  ['realloc']        = 'c/memory/realloc',
  ['free']           = 'c/memory/free',
  ['aligned_alloc']  = 'c/memory/aligned_alloc',
  ['atoi']           = 'c/string/byte/atoi',
  ['atol']           = 'c/string/byte/atoi',
  ['atoll']          = 'c/string/byte/atoi',
  ['strtol']         = 'c/string/byte/strtol',
  ['strtoul']        = 'c/string/byte/strtoul',
  ['strtoll']        = 'c/string/byte/strtol',
  ['strtoull']       = 'c/string/byte/strtoul',
  ['strtof']         = 'c/string/byte/strtof',
  ['strtod']         = 'c/string/byte/strtod',
  ['strtold']        = 'c/string/byte/strtold',
  ['rand']           = 'c/numeric/random/rand',
  ['srand']          = 'c/numeric/random/srand',
  ['abs']            = 'c/numeric/math/fabs',
  ['labs']           = 'c/numeric/math/fabs',
  ['llabs']          = 'c/numeric/math/fabs',
  ['div']            = 'c/numeric/math/div',
  ['ldiv']           = 'c/numeric/math/div',
  ['lldiv']          = 'c/numeric/math/div',
  ['qsort']          = 'c/algorithm/qsort',
  ['bsearch']        = 'c/algorithm/bsearch',
  ['exit']           = 'c/program/exit',
  ['EXIT_SUCCESS']   = 'c/program/exit',
  ['EXIT_FAILURE']   = 'c/program/exit',
  ['atexit']         = 'c/program/atexit',
  ['quick_exit']     = 'c/program/quick_exit',
  ['at_quick_exit']  = 'c/program/at_quick_exit',
  ['_Exit']          = 'c/program/_Exit',
  ['abort']          = 'c/program/abort',
  ['getenv']         = 'c/program/getenv',
  ['system']         = 'c/program/system',

  -- <string.h>
  ['memcpy']    = 'c/string/byte/memcpy',
  ['memmove']   = 'c/string/byte/memmove',
  ['memcmp']    = 'c/string/byte/memcmp',
  ['memchr']    = 'c/string/byte/memchr',
  ['memset']    = 'c/string/byte/memset',
  ['strcpy']    = 'c/string/byte/strcpy',
  ['strncpy']   = 'c/string/byte/strncpy',
  ['strcat']    = 'c/string/byte/strcat',
  ['strncat']   = 'c/string/byte/strncat',
  ['strcmp']    = 'c/string/byte/strcmp',
  ['strncmp']   = 'c/string/byte/strncmp',
  ['strchr']    = 'c/string/byte/strchr',
  ['strrchr']   = 'c/string/byte/strrchr',
  ['strstr']    = 'c/string/byte/strstr',
  ['strspn']    = 'c/string/byte/strspn',
  ['strcspn']   = 'c/string/byte/strcspn',
  ['strpbrk']   = 'c/string/byte/strpbrk',
  ['strtok']    = 'c/string/byte/strtok',
  ['strlen']    = 'c/string/byte/strlen',
  ['strerror']  = 'c/string/byte/strerror',
  ['strcoll']   = 'c/string/byte/strcoll',
  ['strxfrm']   = 'c/string/byte/strxfrm',

  -- <math.h>
  ['sin']       = 'c/numeric/math/sin',
  ['cos']       = 'c/numeric/math/cos',
  ['tan']       = 'c/numeric/math/tan',
  ['asin']      = 'c/numeric/math/asin',
  ['acos']      = 'c/numeric/math/acos',
  ['atan']      = 'c/numeric/math/atan',
  ['atan2']     = 'c/numeric/math/atan2',
  ['sinh']      = 'c/numeric/math/sinh',
  ['cosh']      = 'c/numeric/math/cosh',
  ['tanh']      = 'c/numeric/math/tanh',
  ['asinh']     = 'c/numeric/math/asinh',
  ['acosh']     = 'c/numeric/math/acosh',
  ['atanh']     = 'c/numeric/math/atanh',
  ['sqrt']      = 'c/numeric/math/sqrt',
  ['cbrt']      = 'c/numeric/math/cbrt',
  ['hypot']     = 'c/numeric/math/hypot',
  ['pow']       = 'c/numeric/math/pow',
  ['exp']       = 'c/numeric/math/exp',
  ['exp2']      = 'c/numeric/math/exp2',
  ['expm1']     = 'c/numeric/math/expm1',
  ['log']       = 'c/numeric/math/log',
  ['log2']      = 'c/numeric/math/log2',
  ['log10']     = 'c/numeric/math/log10',
  ['log1p']     = 'c/numeric/math/log1p',
  ['floor']     = 'c/numeric/math/floor',
  ['ceil']      = 'c/numeric/math/ceil',
  ['round']     = 'c/numeric/math/round',
  ['lround']    = 'c/numeric/math/round',
  ['llround']   = 'c/numeric/math/round',
  ['trunc']     = 'c/numeric/math/trunc',
  ['fabs']      = 'c/numeric/math/fabs',
  ['fmod']      = 'c/numeric/math/fmod',
  ['remainder'] = 'c/numeric/math/remainder',
  ['fmax']      = 'c/numeric/math/fmax',
  ['fmin']      = 'c/numeric/math/fmin',
  ['fdim']      = 'c/numeric/math/fdim',
  ['fma']       = 'c/numeric/math/fma',
  ['copysign']  = 'c/numeric/math/copysign',
  ['frexp']     = 'c/numeric/math/frexp',
  ['ldexp']     = 'c/numeric/math/ldexp',
  ['modf']      = 'c/numeric/math/modf',
  ['nan']       = 'c/numeric/math/nan',
  ['nearbyint'] = 'c/numeric/math/nearbyint',
  ['rint']      = 'c/numeric/math/rint',
  ['scalbn']    = 'c/numeric/math/scalbn',
  ['scalbln']   = 'c/numeric/math/scalbln',
  ['ilogb']     = 'c/numeric/math/ilogb',
  ['logb']      = 'c/numeric/math/logb',
  ['nextafter'] = 'c/numeric/math/nextafter',

  -- <ctype.h>
  ['isalpha']   = 'c/string/byte/isalpha',
  ['isdigit']   = 'c/string/byte/isdigit',
  ['isalnum']   = 'c/string/byte/isalnum',
  ['isxdigit']  = 'c/string/byte/isxdigit',
  ['islower']   = 'c/string/byte/islower',
  ['isupper']   = 'c/string/byte/isupper',
  ['isspace']   = 'c/string/byte/isspace',
  ['isblank']   = 'c/string/byte/isblank',
  ['ispunct']   = 'c/string/byte/ispunct',
  ['iscntrl']   = 'c/string/byte/iscntrl',
  ['isgraph']   = 'c/string/byte/isgraph',
  ['isprint']   = 'c/string/byte/isprint',
  ['tolower']   = 'c/string/byte/tolower',
  ['toupper']   = 'c/string/byte/toupper',

  -- <time.h>
  ['time']         = 'c/chrono/time',
  ['clock']        = 'c/chrono/clock',
  ['difftime']     = 'c/chrono/difftime',
  ['mktime']       = 'c/chrono/mktime',
  ['asctime']      = 'c/chrono/asctime',
  ['ctime']        = 'c/chrono/ctime',
  ['gmtime']       = 'c/chrono/gmtime',
  ['localtime']    = 'c/chrono/localtime',
  ['strftime']     = 'c/chrono/strftime',
  ['timespec_get'] = 'c/chrono/timespec_get',

  -- <errno.h> / <assert.h> / <signal.h> / <setjmp.h> / <stdarg.h>
  ['errno']      = 'c/error/errno',
  ['EDOM']       = 'c/error/errno',
  ['ERANGE']     = 'c/error/errno',
  ['EILSEQ']     = 'c/error/errno',
  ['assert']     = 'c/error/assert',
  ['signal']     = 'c/program/signal',
  ['raise']      = 'c/program/raise',
  ['setjmp']     = 'c/program/setjmp',
  ['longjmp']    = 'c/program/longjmp',
  ['va_list']    = 'c/variadic/va_list',
  ['va_start']   = 'c/variadic/va_start',
  ['va_arg']     = 'c/variadic/va_arg',
  ['va_end']     = 'c/variadic/va_end',
  ['va_copy']    = 'c/variadic/va_copy',

  -- ── C++ Containers ──────────────────────────────────────────────────────────
  vector             = 'cpp/container/vector',
  deque              = 'cpp/container/deque',
  list               = 'cpp/container/list',
  ['forward_list']   = 'cpp/container/forward_list',
  array              = 'cpp/container/array',
  string             = 'cpp/string/basic_string',
  ['string_view']    = 'cpp/string/basic_string_view',
  map                = 'cpp/container/map',
  multimap           = 'cpp/container/multimap',
  set                = 'cpp/container/set',
  multiset           = 'cpp/container/multiset',
  ['unordered_map']   = 'cpp/container/unordered_map',
  ['unordered_multimap'] = 'cpp/container/unordered_multimap',
  ['unordered_set']   = 'cpp/container/unordered_set',
  ['unordered_multiset'] = 'cpp/container/unordered_multiset',
  stack              = 'cpp/container/stack',
  queue              = 'cpp/container/queue',
  ['priority_queue'] = 'cpp/container/priority_queue',
  span               = 'cpp/container/span',
  bitset             = 'cpp/utility/bitset',
  optional           = 'cpp/utility/optional',
  variant            = 'cpp/utility/variant',
  any                = 'cpp/utility/any',
  expected           = 'cpp/utility/expected',
  pair               = 'cpp/utility/pair',
  tuple              = 'cpp/utility/tuple',

  -- ── C++ Smart Pointers ─────────────────────────────────────────────────────
  ['shared_ptr']  = 'cpp/memory/shared_ptr',
  ['unique_ptr']  = 'cpp/memory/unique_ptr',
  ['weak_ptr']    = 'cpp/memory/weak_ptr',
  ['make_shared'] = 'cpp/memory/shared_ptr/make_shared',
  ['make_unique'] = 'cpp/memory/unique_ptr/make_unique',
  ['allocate_shared'] = 'cpp/memory/shared_ptr/allocate_shared',
  ['enable_shared_from_this'] = 'cpp/memory/enable_shared_from_this',

  -- ── C++ Algorithms ─────────────────────────────────────────────────────────
  sort              = 'cpp/algorithm/sort',
  ['stable_sort']   = 'cpp/algorithm/stable_sort',
  ['partial_sort']  = 'cpp/algorithm/partial_sort',
  ['nth_element']   = 'cpp/algorithm/nth_element',
  ['lower_bound']   = 'cpp/algorithm/lower_bound',
  ['upper_bound']   = 'cpp/algorithm/upper_bound',
  ['binary_search'] = 'cpp/algorithm/binary_search',
  ['equal_range']   = 'cpp/algorithm/equal_range',
  find              = 'cpp/algorithm/find',
  ['find_if']       = 'cpp/algorithm/find',
  ['find_if_not']   = 'cpp/algorithm/find',
  ['find_end']      = 'cpp/algorithm/find_end',
  ['find_first_of'] = 'cpp/algorithm/find_first_of',
  ['adjacent_find'] = 'cpp/algorithm/adjacent_find',
  count             = 'cpp/algorithm/count',
  ['count_if']      = 'cpp/algorithm/count',
  for_each          = 'cpp/algorithm/for_each',
  transform         = 'cpp/algorithm/transform',
  copy              = 'cpp/algorithm/copy',
  ['copy_n']        = 'cpp/algorithm/copy_n',
  ['copy_if']       = 'cpp/algorithm/copy_if',
  ['copy_backward'] = 'cpp/algorithm/copy_backward',
  move              = 'cpp/algorithm/move',
  ['move_backward'] = 'cpp/algorithm/move_backward',
  fill              = 'cpp/algorithm/fill',
  ['fill_n']        = 'cpp/algorithm/fill_n',
  generate          = 'cpp/algorithm/generate',
  ['generate_n']    = 'cpp/algorithm/generate_n',
  replace           = 'cpp/algorithm/replace',
  ['replace_if']    = 'cpp/algorithm/replace',
  ['replace_copy']  = 'cpp/algorithm/replace_copy',
  ['replace_copy_if'] = 'cpp/algorithm/replace_copy',
  remove            = 'cpp/algorithm/remove',
  ['remove_if']     = 'cpp/algorithm/remove',
  ['remove_copy']   = 'cpp/algorithm/remove_copy',
  ['remove_copy_if'] = 'cpp/algorithm/remove_copy',
  unique            = 'cpp/algorithm/unique',
  ['unique_copy']   = 'cpp/algorithm/unique_copy',
  reverse           = 'cpp/algorithm/reverse',
  ['reverse_copy']  = 'cpp/algorithm/reverse_copy',
  rotate            = 'cpp/algorithm/rotate',
  ['rotate_copy']   = 'cpp/algorithm/rotate_copy',
  shuffle           = 'cpp/algorithm/random_shuffle',
  sample            = 'cpp/algorithm/sample',
  swap              = 'cpp/algorithm/swap',
  ['iter_swap']     = 'cpp/algorithm/iter_swap',
  ['swap_ranges']   = 'cpp/algorithm/swap_ranges',
  accumulate        = 'cpp/algorithm/accumulate',
  ['inner_product'] = 'cpp/algorithm/inner_product',
  ['partial_sum']   = 'cpp/algorithm/partial_sum',
  ['adjacent_difference'] = 'cpp/algorithm/adjacent_difference',
  iota              = 'cpp/algorithm/iota',
  min               = 'cpp/algorithm/min',
  max               = 'cpp/algorithm/max',
  minmax            = 'cpp/algorithm/minmax',
  ['min_element']   = 'cpp/algorithm/min_element',
  ['max_element']   = 'cpp/algorithm/max_element',
  ['minmax_element'] = 'cpp/algorithm/minmax_element',
  clamp             = 'cpp/algorithm/clamp',
  equal             = 'cpp/algorithm/equal',
  mismatch          = 'cpp/algorithm/mismatch',
  ['lexicographical_compare'] = 'cpp/algorithm/lexicographical_compare',
  ['all_of']        = 'cpp/algorithm/all_any_none_of',
  ['any_of']        = 'cpp/algorithm/all_any_none_of',
  ['none_of']       = 'cpp/algorithm/all_any_none_of',
  is_sorted         = 'cpp/algorithm/is_sorted',
  ['is_sorted_until'] = 'cpp/algorithm/is_sorted_until',
  ['is_heap']       = 'cpp/algorithm/is_heap',
  ['is_heap_until'] = 'cpp/algorithm/is_heap_until',
  partition         = 'cpp/algorithm/partition',
  ['stable_partition'] = 'cpp/algorithm/stable_partition',
  ['partition_point'] = 'cpp/algorithm/partition_point',
  ['partition_copy'] = 'cpp/algorithm/partition_copy',
  merge             = 'cpp/algorithm/merge',
  ['inplace_merge'] = 'cpp/algorithm/inplace_merge',
  includes          = 'cpp/algorithm/includes',
  ['set_difference']    = 'cpp/algorithm/set_difference',
  ['set_intersection']  = 'cpp/algorithm/set_intersection',
  ['set_symmetric_difference'] = 'cpp/algorithm/set_symmetric_difference',
  ['set_union']     = 'cpp/algorithm/set_union',
  ['is_permutation'] = 'cpp/algorithm/is_permutation',
  ['next_permutation'] = 'cpp/algorithm/next_permutation',
  ['prev_permutation'] = 'cpp/algorithm/prev_permutation',

  -- ── C++ Utilities ──────────────────────────────────────────────────────────
  ['function']  = 'cpp/utility/functional',
  bind          = 'cpp/utility/functional/bind',
  ref           = 'cpp/utility/functional/ref',
  cref          = 'cpp/utility/functional/ref',
  ['mem_fn']    = 'cpp/utility/functional/mem_fn',
  hash          = 'cpp/utility/hash',
  ['from_chars'] = 'cpp/utility/from_chars',
  ['to_chars']  = 'cpp/utility/to_chars',

  -- ── C++ I/O and manipulators ───────────────────────────────────────────────
  iostream      = 'cpp/header/iostream',
  fstream       = 'cpp/header/fstream',
  sstream       = 'cpp/header/sstream',
  iomanip       = 'cpp/header/iomanip',
  iosfwd        = 'cpp/header/iosfwd',
  streambuf     = 'cpp/header/streambuf',
  cout          = 'cpp/io/cout',
  cin           = 'cpp/io/cin',
  cerr          = 'cpp/io/cerr',
  clog          = 'cpp/io/clog',
  ['setw']      = 'cpp/io/manip/setw',
  ['setprecision'] = 'cpp/io/manip/setprecision',
  ['setfill']   = 'cpp/io/manip/setfill',
  ['setbase']   = 'cpp/io/manip/setbase',
  boolalpha     = 'cpp/io/manip/boolalpha',
  showbase      = 'cpp/io/manip/showbase',
  showpoint     = 'cpp/io/manip/showpoint',
  uppercase     = 'cpp/io/manip/uppercase',
  hex           = 'cpp/io/manip/hex',
  dec           = 'cpp/io/manip/hex',
  oct           = 'cpp/io/manip/hex',
  ws            = 'cpp/io/manip/ws',
  ends          = 'cpp/io/manip/ends',
  flush         = 'cpp/io/manip/flush',
  endl          = 'cpp/io/manip/endl',
  skipws        = 'cpp/io/manip/skipws',
  unitbuf       = 'cpp/io/manip/unitbuf',

  -- ── C++ Threading ──────────────────────────────────────────────────────────
  thread                = 'cpp/thread/thread',
  jthread               = 'cpp/thread/jthread',
  mutex                 = 'cpp/thread/mutex',
  ['shared_mutex']      = 'cpp/thread/shared_mutex',
  ['timed_mutex']       = 'cpp/thread/timed_mutex',
  ['recursive_mutex']   = 'cpp/thread/recursive_mutex',
  ['shared_timed_mutex'] = 'cpp/thread/shared_timed_mutex',
  ['lock_guard']        = 'cpp/thread/lock_guard',
  ['unique_lock']       = 'cpp/thread/unique_lock',
  ['shared_lock']       = 'cpp/thread/shared_lock',
  ['scoped_lock']       = 'cpp/thread/scoped_lock',
  ['condition_variable'] = 'cpp/thread/condition_variable',
  ['condition_variable_any'] = 'cpp/thread/condition_variable',
  future                = 'cpp/thread/future',
  promise               = 'cpp/thread/promise',
  async                 = 'cpp/thread/async',
  atomic                = 'cpp/atomic/atomic',
  ['atomic_flag']       = 'cpp/atomic/atomic_flag',
  ['call_once']         = 'cpp/thread/call_once',
  ['once_flag']         = 'cpp/thread/once_flag',
  ['packaged_task']     = 'cpp/thread/packaged_task',
  latch                 = 'cpp/thread/latch',
  barrier               = 'cpp/thread/barrier',
  ['counting_semaphore'] = 'cpp/thread/counting_semaphore',
  ['binary_semaphore']  = 'cpp/thread/counting_semaphore',

  -- ── C++ Chrono ─────────────────────────────────────────────────────────────
  chrono                = 'cpp/chrono',
  ['system_clock']      = 'cpp/chrono/system_clock',
  ['steady_clock']      = 'cpp/chrono/steady_clock',
  ['high_resolution_clock'] = 'cpp/chrono/high_resolution_clock',
  duration              = 'cpp/chrono/duration',
  ['time_point']        = 'cpp/chrono/time_point',
  hours                 = 'cpp/chrono/duration',
  minutes               = 'cpp/chrono/duration',
  seconds               = 'cpp/chrono/duration',
  milliseconds          = 'cpp/chrono/duration',
  microseconds          = 'cpp/chrono/duration',
  nanoseconds           = 'cpp/chrono/duration',
  ['duration_cast']     = 'cpp/chrono/duration_cast',
  ['time_point_cast']   = 'cpp/chrono/time_point_cast',

  -- ── C++ Filesystem ─────────────────────────────────────────────────────────
  path                  = 'cpp/filesystem/path',
  ['directory_entry']   = 'cpp/filesystem/directory_entry',
  ['directory_iterator'] = 'cpp/filesystem/directory_iterator',
  ['recursive_directory_iterator'] = 'cpp/filesystem/recursive_directory_iterator',
  ['file_status']       = 'cpp/filesystem/file_status',
  ['space_info']        = 'cpp/filesystem/space',
  ['filesystem_error']  = 'cpp/filesystem/filesystem_error',

  -- ── C++ Numeric / Random ───────────────────────────────────────────────────
  ['mt19937']             = 'cpp/numeric/random/mersenne_twister_engine',
  ['mt19937_64']          = 'cpp/numeric/random/mersenne_twister_engine',
  ['random_device']       = 'cpp/numeric/random/random_device',
  ['uniform_int_distribution'] = 'cpp/numeric/random/uniform_int_distribution',
  ['normal_distribution'] = 'cpp/numeric/random/normal_distribution',
  complex                 = 'cpp/numeric/complex',
  ['numeric_limits']      = 'cpp/types/numeric_limits',
  ratio                   = 'cpp/numeric/ratio/ratio',
  ['popcount']            = 'cpp/numeric/popcount',
  ['bit_cast']            = 'cpp/numeric/bit_cast',
  gcd                     = 'cpp/numeric/gcd',
  lcm                     = 'cpp/numeric/lcm',
  midpoint                = 'cpp/numeric/midpoint',
  lerp                    = 'cpp/numeric/lerp',

  -- ── C++ Ranges (C++20) ─────────────────────────────────────────────────────
  ['views::filter']    = 'cpp/ranges/filter_view',
  ['views::transform'] = 'cpp/ranges/transform_view',
  ['views::take']      = 'cpp/ranges/take_view',
  ['views::drop']      = 'cpp/ranges/drop_view',
  ['views::reverse']   = 'cpp/ranges/reverse_view',
  ['views::join']      = 'cpp/ranges/join_view',
  ['views::split']     = 'cpp/ranges/split_view',
  ['views::elements']  = 'cpp/ranges/elements_view',
  ['views::keys']      = 'cpp/ranges/keys_view',
  ['views::values']    = 'cpp/ranges/values_view',
  ['ranges::sort']     = 'cpp/algorithm/ranges/sort',
  ['ranges::find']     = 'cpp/algorithm/ranges/find',
  ['ranges::copy']     = 'cpp/algorithm/ranges/copy',
  ['ranges::transform'] = 'cpp/algorithm/ranges/transform',

  -- ── C++ Regex ──────────────────────────────────────────────────────────────
  regex                 = 'cpp/regex/basic_regex',
  ['smatch']            = 'cpp/regex/match_results',
  ['cmatch']            = 'cpp/regex/match_results',
  ['regex_match']       = 'cpp/regex/regex_match',
  ['regex_search']      = 'cpp/regex/regex_search',
  ['regex_replace']     = 'cpp/regex/regex_replace',
  ['regex_iterator']    = 'cpp/regex/regex_iterator',
  ['regex_token_iterator'] = 'cpp/regex/regex_token_iterator',

  -- ── C++ Type Traits ───────────────────────────────────────────────────────
  ['is_same']             = 'cpp/types/is_same',
  ['is_integral']         = 'cpp/types/is_integral',
  ['is_floating_point']   = 'cpp/types/is_floating_point',
  ['is_arithmetic']       = 'cpp/types/is_arithmetic',
  ['is_pointer']          = 'cpp/types/is_pointer',
  ['is_reference']        = 'cpp/types/is_reference',
  ['is_const']            = 'cpp/types/is_const',
  ['is_volatile']         = 'cpp/types/is_volatile',
  ['is_base_of']          = 'cpp/types/is_base_of',
  ['is_convertible']      = 'cpp/types/is_convertible',
  ['is_trivially_copyable'] = 'cpp/types/is_trivially_copyable',
  ['is_standard_layout']  = 'cpp/types/is_standard_layout',
  ['is_polymorphic']      = 'cpp/types/is_polymorphic',
  ['is_abstract']         = 'cpp/types/is_abstract',
  ['is_class']            = 'cpp/types/is_class',
  ['is_enum']             = 'cpp/types/is_enum',
  ['is_union']            = 'cpp/types/is_union',
  ['is_function']         = 'cpp/types/is_function',
  ['is_empty']            = 'cpp/types/is_empty',
  ['is_final']            = 'cpp/types/is_final',
  ['is_aggregate']        = 'cpp/types/is_aggregate',
  ['is_signed']           = 'cpp/types/is_signed',
  ['is_unsigned']         = 'cpp/types/is_unsigned',
  ['enable_if']           = 'cpp/types/enable_if',
  ['conditional']         = 'cpp/types/conditional',
  ['remove_reference']    = 'cpp/types/remove_reference',
  ['remove_const']        = 'cpp/types/remove_const',
  ['remove_volatile']     = 'cpp/types/remove_volatile',
  ['remove_pointer']      = 'cpp/types/remove_pointer',
  ['add_pointer']         = 'cpp/types/add_pointer',
  ['make_signed']         = 'cpp/types/make_signed',
  ['make_unsigned']       = 'cpp/types/make_unsigned',
  ['decay']               = 'cpp/types/decay',
  ['common_type']         = 'cpp/types/common_type',
  ['underlying_type']     = 'cpp/types/underlying_type',
  ['void_t']              = 'cpp/types/void_t',
  ['invoke_result']       = 'cpp/types/invoke_result',
  ['integral_constant']   = 'cpp/types/integral_constant',
  ['conjunction']         = 'cpp/types/conjunction',
  ['disjunction']         = 'cpp/types/disjunction',
  ['negation']            = 'cpp/types/negation',
}

---@param symbol string
---@return string|nil
local function resolve_cpp_url(symbol)
  local prefix = 'std::'
  local name = symbol
  if symbol:sub(1, #prefix) == prefix then
    name = symbol:sub(#prefix + 1)
  end

  local page = CPP_PAGE_MAPPING[name]
  if page then
    return page
  end

  -- Best-effort fallback
  if symbol:sub(1, #prefix) == prefix then
    return 'cpp/container/' .. name
  end

  return 'c/' .. name
end

-- Cache for external documentation
local external_docs_cache = {}

---@param html string
---@return string|nil
local function extract_main_content(html)
  local start_idx = html:find('<div id="mw-content-text"')
  if not start_idx then
    return nil
  end
  start_idx = html:find('>', start_idx)
  if not start_idx then
    return nil
  end
  start_idx = start_idx + 1

  local end_idx = html:find('</div>', start_idx)
  if not end_idx then
    return nil
  end

  return html:sub(start_idx, end_idx)
end

local HTML_REPLACEMENTS = {
  -- Block elements
  { '<h1[^>]*>', '# ' },
  { '</h1>', '\n' },
  { '<h2[^>]*>', '## ' },
  { '</h2>', '\n' },
  { '<h3[^>]*>', '### ' },
  { '</h3>', '\n' },
  { '<h4[^>]*>', '#### ' },
  { '</h4>', '\n' },
  { '<h5[^>]*>', '##### ' },
  { '</h5>', '\n' },
  { '<h6[^>]*>', '###### ' },
  { '</h6>', '\n' },
  { '<p[^>]*>', '\n' },
  { '</p>', '\n' },
  { '<ul[^>]*>', '\n' },
  { '</ul>', '\n' },
  { '<ol[^>]*>', '\n' },
  { '</ol>', '\n' },
  { '<li[^>]*>', '- ' },
  { '</li>', '\n' },
  { '<pre[^>]*>', '```\n' },
  { '</pre>', '\n```\n' },
  { '<code[^>]*>', '`' },
  { '</code>', '`' },
  { '<table[^>]*>', '\n' },
  { '</table>', '\n' },
  { '<thead[^>]*>', '\n' },
  { '</thead>', '\n' },
  { '<tbody[^>]*>', '\n' },
  { '</tbody>', '\n' },
  { '<tr[^>]*>', '\n' },
  { '</tr>', '\n' },
  { '<th[^>]*>', '| ' },
  { '</th>', ' |' },
  { '<td[^>]*>', '| ' },
  { '</td>', ' |' },
  { '<hr[%s/>]*>', '\n---\n' },
  { '<br[%s/>]*>', '\n' },
  { '<div[^>]*>', '\n' },
  { '</div>', '\n' },
  { '<span[^>]*>', '' },
  { '</span>', '' },
  -- Emphasis
  { '<strong[^>]*>', '**' },
  { '</strong>', '**' },
  { '<b[^>]*>', '**' },
  { '</b>', '**' },
  { '<em[^>]*>', '*' },
  { '</em>', '*' },
  { '<i[^>]*>', '*' },
  { '</i>', '*' },
  { '<del[^>]*>', '~~' },
  { '</del>', '~~' },
  { '<ins[^>]*>', '__' },
  { '</ins>', '__' },
  { '<mark[^>]*>', '==' },
  { '</mark>', '==' },
}

local ENTITY_REPLACEMENTS = {
  ['&lt;'] = '<',
  ['&gt;'] = '>',
  ['&amp;'] = '&',
  ['&quot;'] = '"',
  ['&#39;'] = "'",
  ['&nbsp;'] = ' ',
  ['&ldquo;'] = '"',
  ['&rdquo;'] = '"',
  ['&lsquo;'] = "'",
  ['&rsquo;'] = "'",
}

---@param content string
---@return string[]|nil
local function convert_html_to_markdown(content)
  -- Remove high-noise elements first
  content = content
    :gsub('<script[^>]*>.*?</script>', '')
    :gsub('<style[^>]*>.*?</style>', '')
    :gsub('<nav[^>]*>.*?</nav>', '')
    :gsub('<header[^>]*>.*?</header>', '')
    :gsub('<footer[^>]*>.*?</footer>', '')
    :gsub('<aside[^>]*>.*?</aside>', '')
    :gsub('<!--.*?-->', '')

  -- Apply table-driven replacements
  for _, rep in ipairs(HTML_REPLACEMENTS) do
    content = content:gsub(rep[1], rep[2])
  end

  -- Handle links: <a href="URL">TEXT</a> -> TEXT (URL)
  content = content:gsub('<a[^>]*href="([^"]*)"[^>]*>([^<]*)</a>', '%2 (%1)')
  content = content:gsub('<a[^>]*>[^<]*</a>', '')

  -- Strip any remaining tags
  content = content:gsub('<[^>]+>', '')

  -- Decode entities
  for ent, val in pairs(ENTITY_REPLACEMENTS) do
    content = content:gsub(ent, val)
  end

  local lines = {}
  for line in content:gmatch('[^\n]+') do
    line = line:gsub('^%s+', ''):gsub('%s+$', '')
    if line ~= '' then
      table.insert(lines, line)
    end
  end

  -- Clean up consecutive empty lines (max 2)
  local i = 2
  while i <= #lines do
    if lines[i] == '' and lines[i - 1] == '' and lines[i - 2] == '' then
      table.remove(lines, i)
    else
      i = i + 1
    end
  end

  while #lines > 0 and lines[1] == '' do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines] == '' do
    table.remove(lines)
  end

  if #lines > 30 then
    lines = { table.unpack(lines, 1, 30) }
    table.insert(lines, '')
    table.insert(lines, '... (truncated for brevity)')
  end

  return #lines > 0 and lines or nil
end

-- Fetch external documentation from cppreference.com
---@param symbol string
---@param callback fun(lines: string[]|nil)
local function fetch_external_docs(symbol, callback)
  if external_docs_cache[symbol] ~= nil then
    callback(external_docs_cache[symbol])
    return
  end

  local page = resolve_cpp_url(symbol)
  if not page then
    external_docs_cache[symbol] = false
    callback(nil)
    return
  end

  local url = 'https://en.cppreference.com/w/' .. page .. '?printable=yes'

  vim.system({ 'curl', '-s', '-L', '--max-time', '8', url }, {}, function(obj)
    if obj.code ~= 0 or not obj.stdout or obj.stdout == '' then
      external_docs_cache[symbol] = false
      callback(nil)
      return
    end

    local content = extract_main_content(obj.stdout)
    if not content then
      external_docs_cache[symbol] = false
      callback(nil)
      return
    end

    local lines = convert_html_to_markdown(content)
    external_docs_cache[symbol] = lines
    callback(lines)
  end)
end

-- Return the identifier whose character span contains col (0-indexed).
-- Handles # for preprocessor directives.
-- Identical structure to word_containing() in java.lua.
local function word_containing(line_text, col)
  local pos = 1
  while true do
    local s, e = line_text:find('[%a_#][%w_]*', pos)
    if not s then
      break
    end
    if col >= s - 1 and col <= e - 1 then
      return line_text:sub(s, e)
    end
    if s - 1 > col then
      break
    end
    pos = e + 1
  end
end

-- ── Hover parsing ─────────────────────────────────────────────────────────────

-- Turn raw doxygen/prose text into clean markdown lines.
-- Mirrors the structure of format_docs() in java.lua, extended for C/C++-specific
-- Doxygen tags: @brief, @param [in/out/inout], @tparam, @return/@returns,
-- @note, @warning, @deprecated, @throws / @exception (C++ exceptions).
--
-- Two fast paths mirror java.lua:
--   1. No doxygen markers → strip blanks and return plain prose.
--   2ات la markers → full parse into **Parameters**, **Returns**, etc.
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match('^%s*$') then
    return nil
  end

  local lines = {}
  for _, line in ipairs(vim.split(raw, '\n', { plain = true })) do
    table.insert(lines, (line:gsub('^%s*%*%s?', '')))
  end

  -- Strip trailing redundant signature block clangd appends after doxygen:
  -- a "---" separator followed by a fenced code block.
  do
    local cut = nil
    for i = 1, #lines do
      if
        lines[i]:match('^%-%-%-$')
        and lines[i + 1]
        and lines[i + 1]:match('^```')
      then
        cut = i
        break
      end
    end
    if cut then
      local trimmed = {}
      for i = 1, cut - 1 do
        trimmed[#trimmed + 1] = lines[i]
      end
      lines = trimmed
    end
  end

  local desc = {}
  local extra = {} -- prose paragraphs appearing after tag blocks
  local tparams = {}
  local params = {}
  local ret = nil
  local notes = {}
  local warnings = {}
  local throws = {}
  local deprecated = nil
  local past_tags = false
  local last_tag = nil
  local last_idx = nil

  local function append_continuation(line)
    local text = line:match('^%s*(.*)')
    if text == '' then
      last_tag = nil
      last_idx = nil
      return
    end
    if last_tag == 'tparam' and last_idx then
      tparams[last_idx].desc = tparams[last_idx].desc .. ' ' .. text
    elseif last_tag == 'param' and last_idx then
      params[last_idx].desc = params[last_idx].desc .. ' ' .. text
    elseif last_tag == 'return' and ret then
      ret = ret .. ' ' .. text
    elseif last_tag == 'note' and last_idx then
      notes[last_idx] = notes[last_idx] .. ' ' .. text
    elseif last_tag == 'warn' and last_idx then
      warnings[last_idx] = warnings[last_idx] .. ' ' .. text
    elseif last_tag == 'throw' and last_idx then
      throws[last_idx].desc = throws[last_idx].desc .. ' ' .. text
    else
      last_tag = nil
      last_idx = nil
    end
  end

  for _, line in ipairs(lines) do
    line = line:gsub('@c%s+(%b[])', '`%1`')
    line = line:gsub('@c%s+(%S+)', '`%1`')
    line = line:gsub('@p%s+(%S+)', '`%1`')
    line = line:gsub('\\<a href=[^>]+>(.-)\\</a>', '%1')
    line = line:gsub('<a [^>]+>(.-)</a>', '%1')
    line = line:gsub('%%([%a_][%w_:]*)', '`%1`')

    local skip = line:match('^%s*[@\\]ingroup%s')
      or line:match('^%s*[@\\]headerfile%s')
      or line:match('^%s*[@\\]file%s')
      or line:match('^%s*[@\\]since%s')
    local brief = line:match('^%s*[@\\]brief%s+(.*)')
    local tname, tdesc = line:match('^%s*[@\\]tparam%s+(%S+)%s*(.*)')
    local pname, pdesc = line:match('^%s*[@\\]param%s*%[?%a*%]?%s*(%S+)%s*(.*)')
    local rdesc = line:match('^%s*[@\\]returns?%s+(.*)')
    local ndesc = line:match('^%s*[@\\]note%s+(.*)')
    local wdesc = line:match('^%s*[@\\]warning%s+(.*)')
    local etype, edesc = line:match('^%s*[@\\]throws?%s+(%S+)%s*(.*)')
    if not etype then
      etype, edesc = line:match('^%s*[@\\]exception%s+(%S+)%s*(.*)')
    end
    local depr = line:match('^%s*[@\\]deprecated%s*(.*)')

    if skip then
      last_tag = nil
    elseif brief then
      past_tags = true
      last_tag = nil
      table.insert(desc, brief)
    elseif tname then
      past_tags = true
      table.insert(tparams, { name = tname, desc = tdesc or '' })
      last_tag = 'tparam'
      last_idx = #tparams
    elseif pname then
      past_tags = true
      table.insert(params, { name = pname, desc = pdesc or '' })
      last_tag = 'param'
      last_idx = #params
    elseif rdesc then
      past_tags = true
      ret = rdesc
      last_tag = 'return'
      last_idx = nil
    elseif ndesc then
      past_tags = true
      table.insert(notes, ndesc)
      last_tag = 'note'
      last_idx = #notes
    elseif wdesc then
      past_tags = true
      table.insert(warnings, wdesc)
      last_tag = 'warn'
      last_idx = #warnings
    elseif etype then
      past_tags = true
      table.insert(throws, { type = etype, desc = edesc or '' })
      last_tag = 'throw'
      last_idx = #throws
    elseif depr then
      past_tags = true
      deprecated = depr
      last_tag = nil
    elseif not past_tags then
      last_tag = nil
      table.insert(desc, line)
    else
      if line:match('^%s+') and last_tag then
        append_continuation(line)
      else
        last_tag = nil
        if not line:match('^%s*$') then
          table.insert(extra, line)
        end
      end
    end
  end

  while #desc > 0 and desc[1]:match('^%s*$') do
    table.remove(desc, 1)
  end
  while #desc > 0 and desc[#desc]:match('^%s*$') do
    table.remove(desc)
  end

  local out = {}
  for _, l in ipairs(desc) do
    table.insert(out, l)
  end

  if #tparams > 0 then
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '**Template Parameters**')
    for _, p in ipairs(tparams) do
      local entry = '- `' .. p.name .. '`'
      if p.desc ~= '' then
        entry = entry .. ' — ' .. p.desc
      end
      table.insert(out, entry)
    end
  end

  if #params > 0 then
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '**Parameters**')
    for _, p in ipairs(params) do
      local entry = '- `' .. p.name .. '`'
      if p.desc ~= '' then
        entry = entry .. ' — ' .. p.desc
      end
      table.insert(out, entry)
    end
  end

  if ret and ret ~= '' then
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '**Returns** — ' .. ret)
  end

  if #throws > 0 then
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '**Throws**')
    for _, t in ipairs(throws) do
      local entry = '- `' .. t.type .. '`'
      if t.desc ~= '' then
        entry = entry .. ' — ' .. t.desc
      end
      table.insert(out, entry)
    end
  end

  for _, n in ipairs(notes) do
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '> **Note:** ' .. n)
  end

  for _, w in ipairs(warnings) do
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '> **Warning:** ' .. w)
  end

  if deprecated and deprecated ~= '' then
    if #out > 0 then
      table.insert(out, '')
    end
    table.insert(out, '> **Deprecated:** ' .. deprecated)
  end

  if #extra > 0 then
    if #out > 0 then
      table.insert(out, '')
    end
    for _, l in ipairs(extra) do
      table.insert(out, l)
    end
  end

  while #out > 0 and out[#out]:match('^%s*$') do
    table.remove(out)
  end

  if #out == 0 then
    local result, started = {}, false
    for _, line in ipairs(lines) do
      if started or not line:match('^%s*$') then
        started = true
        table.insert(result, line)
      end
    end
    while #result > 0 and result[#result]:match('^%s*$') do
      table.remove(result)
    end
    return #result > 0 and result or nil
  end

  return out
end

-- ── fetch_hover + retry ────────────────────────────────────────────────────────

-- When hover returns nothing for a non-keyword position, scan ahead on the
-- same line for the first non-keyword identifier after the cursor and retry.
-- Mirrors retry_at_symbol() in java.lua exactly.
---@param bufnr integer
---@param params table
---@param ft string
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function retry_at_symbol(bufnr, params, ft, cb)
  local line_nr = params.position.line
  local col = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(
    bufnr,
    line_nr,
    line_nr + 1,
    false
  )[1] or ''

  local new_col
  local pos = 1
  while true do
    local s, e = line_text:find('[%a_][%w_]*', pos)
    if not s then
      break
    end
    local word_col = s - 1 -- 0-based
    if word_col > col and not is_keyword(ft, line_text:sub(s, e)) then
      new_col = word_col
      break
    end
    pos = e + 1
  end

  if not new_col then
    cb(nil, nil)
    return
  end

  local new_params = vim.deepcopy(params)
  new_params.position.character = new_col
  util.std_request(
    bufnr,
    'clangd',
    'textDocument/hover',
    new_params,
    function(result)
      cb(util.parse_hover_result(result, ft, format_docs))
    end
  )
end

-- Fetch hover from clangd and route through parse_hover_result().
-- Distinguishes three outcomes — mirrors fetch_hover() in java.lua:
--   got sig  → cb(sig_lines, doc_lines)
--   keyword  → cb(nil, nil)  [let main.lua serve the keyword table]
--   no-symbol non-keyword → retry_at_symbol
---@param bufnr integer
---@param params table
---@param ft string
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, ft, cb)
  util.std_request(
    bufnr,
    'clangd',
    'textDocument/hover',
    params,
    function(result)
      local sig_lines, doc_lines =
        util.parse_hover_result(result, ft, format_docs)
      if sig_lines then
        cb(sig_lines, doc_lines)
        return
      end

      local col = params.position.character
      local line_nr = params.position.line
      local line_text = vim.api.nvim_buf_get_lines(
        bufnr,
        line_nr,
        line_nr + 1,
        false
      )[1] or ''
      if
        is_keyword(ft, util.word_containing(line_text, col, '[%a_#][%w_]*'))
      then
        cb(nil, nil)
        return
      end

      retry_at_symbol(bufnr, params, ft, cb)
    end
  )
end

-- ── Type hierarchy ─────────────────────────────────────────────────────────────

-- Fetch supertypes and subtypes via a single prepareTypeHierarchy call.
-- on_super and on_subs are each guaranteed to be called exactly once.
-- The stray tick() upvalue that existed in the previous version has been removed;
-- callers handle their own tick() calls.
---@param bufnr integer
---@param params table
---@param cfg table
---@param on_super fun(types: string[])
---@param on_subs  fun(types: string[])
local function fetch_hierarchy(bufnr, params, cfg, on_super, on_subs)
  local want_super = cfg.sections.hierarchy
  local want_subs = cfg.sections.implementations

  if not want_super and not want_subs then
    on_super({})
    on_subs({})
    return
  end

  util.std_request(
    bufnr,
    'clangd',
    'textDocument/prepareTypeHierarchy',
    params,
    function(items)
      if not items or #items == 0 then
        on_super({})
        on_subs({})
        return
      end

      local item = items[1]

      if want_super then
        util.client_request(
          bufnr,
          'clangd',
          'typeHierarchy/supertypes',
          { item = item, resolve = 3 },
          function(result)
            if not result then
              on_super({})
              return
            end
            local names = {}
            for _, it in ipairs(result) do
              if it.name then
                local entry = it.name
                if it.detail and it.detail ~= '' then
                  entry = entry .. '  `' .. it.detail .. '`'
                end
                table.insert(names, entry)
              end
            end
            on_super(names)
          end
        )
      else
        on_super({})
      end

      if want_subs then
        util.client_request(
          bufnr,
          'clangd',
          'typeHierarchy/subtypes',
          { item = item, resolve = 3 },
          function(result)
            if not result then
              on_subs({})
              return
            end
            local names = {}
            for _, it in ipairs(result) do
              if it.name then
                local entry = it.name
                if it.detail and it.detail ~= '' then
                  entry = entry .. '  `' .. it.detail .. '`'
                end
                table.insert(names, entry)
              end
            end
            on_subs(names)
          end
        )
      else
        on_subs({})
      end
    end
  )
end

---@param bufnr integer
---@param params table
---@param cb fun(names: string[])
local function fetch_implementations(bufnr, params, cb)
  util.std_request(
    bufnr,
    'clangd',
    'textDocument/implementation',
    params,
    function(result)
      if not result then
        cb({})
        return
      end
      local seen, names = {}, {}
      for _, loc in ipairs(vim.islist(result) and result or { result }) do
        local uri = loc.uri or loc.targetUri or ''
        local base = vim.fn.fnamemodify(vim.uri_to_fname(uri), ':t:r')
        local line = (loc.range or loc.targetSelectionRange or {
          start = { line = 0 },
        }).start.line
        local label = base ~= '' and (base .. ':' .. (line + 1)) or '?'
        if not seen[label] then
          seen[label] = true
          table.insert(names, label)
        end
        if #names >= 12 then
          break
        end
      end
      if #names >= 12 then
        table.insert(names, '…(more)')
      end
      cb(names)
    end
  )
end

---@param bufnr integer
---@param params table
---@param cb fun(info: string|nil)
local function fetch_macro(bufnr, params, cb)
  util.std_request(
    bufnr,
    'clangd',
    'textDocument/symbolInfo',
    params,
    function(result)
      if not result or #result == 0 then
        cb(nil)
        return
      end
      local sym = result[1]
      cb(
        sym and sym.kind == 14 and ('Macro: `' .. (sym.name or '?') .. '`')
          or nil
      )
    end
  )
end

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params = util.pos_params(bufnr)
  local cfg = require('linus').config
  local ft = vim.bo[bufnr].filetype

  -- Get the word under the cursor early for keyword check and external docs
  local line_nr = params.position.line
  local col = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(
    bufnr,
    line_nr,
    line_nr + 1,
    false
  )[1] or ''
  local word = util.word_containing(line_text, col, '[%a_#][%w_]*')

  -- Fast-path for keywords: skip all LSP work and let main.lua serve the
  -- built-in reference.  Must happen before any request fires.
  if is_keyword(ft, word) then
    done({})
    return
  end

  -- Determine if we should fetch external documentation
  -- Triggers for std:: symbols and known C library functions
  local fetch_external = cfg.sections.external_docs
    and word
    and (word:find('^std::') ~= nil or CPP_PAGE_MAPPING[word] ~= nil)

  -- Six async slots — barrier must be reached exactly 6 times:
  --   1. hover
  --   2. supertypes  ┐ both from fetch_hierarchy after one prepare call;
  --   3. subtypes    ┘ each calls tick() independently
  --   4. textDocument/implementation
  --   5. textDocument/symbolInfo (macro detection)
  --   6. external documentation
  local data = {}
  local tick = util.barrier(6, function()
    done(data)
  end)

  -- Slot 1
  fetch_hover(bufnr, params, ft, function(sig_lines, doc_lines)
    data.signature = sig_lines
    data.docs = doc_lines
    tick()
  end)

  -- Slots 2 + 3
  fetch_hierarchy(bufnr, params, cfg, function(types)
    if #types > 0 then
      data.hierarchy = types
    end
    tick() -- slot 2
  end, function(types)
    if #types > 0 then
      data.implementations = data.implementations or {}
      vim.list_extend(data.implementations, types)
    end
    tick() -- slot 3
  end)

  -- Slot 4
  if cfg.sections.implementations then
    fetch_implementations(bufnr, params, function(impls)
      if #impls > 0 then
        data.implementations = data.implementations or {}
        local seen = {}
        for _, v in ipairs(data.implementations) do
          seen[v] = true
        end
        for _, v in ipairs(impls) do
          if not seen[v] then
            table.insert(data.implementations, v)
          end
        end
      end
      tick()
    end)
  else
    tick()
  end

  -- Slot 5
  if cfg.sections.extra ~= false then
    fetch_macro(bufnr, params, function(info)
      if info then
        data.extra = { info }
      end
      tick()
    end)
  else
    tick()
  end

  -- Slot 6: external documentation
  if fetch_external and word then
    fetch_external_docs(word, function(lines)
      if lines then
        data.external_docs = lines
      end
      tick()
    end)
  else
    tick()
  end
end

return M
