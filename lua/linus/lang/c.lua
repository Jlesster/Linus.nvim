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

local util = require("linus.lang.util")

local M = {}

-- ── Keyword sets ───────────────────────────────────────────────────────────────

local C_KEYWORDS = {
  ["auto"] = true,
  ["break"] = true,
  ["case"] = true,
  ["char"] = true,
  ["const"] = true,
  ["continue"] = true,
  ["default"] = true,
  ["do"] = true,
  ["double"] = true,
  ["else"] = true,
  ["enum"] = true,
  ["extern"] = true,
  ["float"] = true,
  ["for"] = true,
  ["goto"] = true,
  ["if"] = true,
  ["inline"] = true,
  ["int"] = true,
  ["long"] = true,
  ["register"] = true,
  ["restrict"] = true,
  ["return"] = true,
  ["short"] = true,
  ["signed"] = true,
  ["sizeof"] = true,
  ["static"] = true,
  ["struct"] = true,
  ["switch"] = true,
  ["typedef"] = true,
  ["union"] = true,
  ["unsigned"] = true,
  ["void"] = true,
  ["volatile"] = true,
  ["while"] = true,
  -- C99 / C11
  ["_Bool"] = true,
  ["_Complex"] = true,
  ["_Imaginary"] = true,
  ["_Atomic"] = true,
  ["_Generic"] = true,
  ["_Noreturn"] = true,
  ["_Static_assert"] = true,
  ["_Thread_local"] = true,
  ["_Alignas"] = true,
  ["_Alignof"] = true,
  -- common macro names treated as keywords
  ["NULL"] = true,
  ["true"] = true,
  ["false"] = true,
  -- preprocessor directives
  ["#define"] = true,
  ["#include"] = true,
  ["#ifdef"] = true,
  ["#ifndef"] = true,
  ["#endif"] = true,
  ["#pragma"] = true,
  ["#if"] = true,
  ["#else"] = true,
  ["#elif"] = true,
  ["#undef"] = true,
  ["#error"] = true,
  ["#warning"] = true,
}

local CPP_KEYWORDS = vim.tbl_extend("force", C_KEYWORDS, {
  ["alignas"] = true,
  ["alignof"] = true,
  ["and"] = true,
  ["and_eq"] = true,
  ["asm"] = true,
  ["bitand"] = true,
  ["bitor"] = true,
  ["bool"] = true,
  ["catch"] = true,
  ["class"] = true,
  ["compl"] = true,
  ["concept"] = true,
  ["consteval"] = true,
  ["constexpr"] = true,
  ["constinit"] = true,
  ["const_cast"] = true,
  ["co_await"] = true,
  ["co_return"] = true,
  ["co_yield"] = true,
  ["decltype"] = true,
  ["delete"] = true,
  ["dynamic_cast"] = true,
  ["explicit"] = true,
  ["export"] = true,
  ["final"] = true,
  ["friend"] = true,
  ["mutable"] = true,
  ["namespace"] = true,
  ["new"] = true,
  ["noexcept"] = true,
  ["not"] = true,
  ["not_eq"] = true,
  ["nullptr"] = true,
  ["operator"] = true,
  ["or"] = true,
  ["or_eq"] = true,
  ["override"] = true,
  ["private"] = true,
  ["protected"] = true,
  ["public"] = true,
  ["reinterpret_cast"] = true,
  ["requires"] = true,
  ["static_assert"] = true,
  ["static_cast"] = true,
  ["template"] = true,
  ["this"] = true,
  ["thread_local"] = true,
  ["throw"] = true,
  ["try"] = true,
  ["typeid"] = true,
  ["typename"] = true,
  ["using"] = true,
  ["virtual"] = true,
  ["wchar_t"] = true,
  ["xor"] = true,
  ["xor_eq"] = true,
})

local function is_keyword(ft, word)
  if ft == "cpp" then return CPP_KEYWORDS[word] end
  return C_KEYWORDS[word]
end

-- ── External Documentation Pipeline ───────────────────────────────────────────────

-- Maps symbols to cppreference.com pages.
local CPP_PAGE_MAPPING = {
  -- Containers
  vector = "cpp/container/vector",
  string = "cpp/string/basic_string",
  ["shared_ptr"] = "cpp/memory/shared_ptr",
  ["unique_ptr"] = "cpp/memory/unique_ptr",
  weak_ptr = "cpp/memory/weak_ptr",
  array = "cpp/container/array",
  deque = "cpp/container/deque",
  forward_list = "cpp/container/forward_list",
  list = "cpp/container/list",
  map = "cpp/container/map",
  multimap = "cpp/container/multimap",
  set = "cpp/container/set",
  multiset = "cpp/container/multiset",
  unordered_map = "cpp/container/unordered_map",
  unordered_multimap = "cpp/container/unordered_multimap",
  unordered_set = "cpp/container/unordered_set",
  unordered_multiset = "cpp/container/unordered_multiset",
  stack = "cpp/container/stack",
  queue = "cpp/container/queue",
  priority_queue = "cpp/container/priority_queue",
  span = "cpp/container/span",

  -- Algorithms
  sort = "cpp/algorithm/sort",
  find = "cpp/algorithm/find",
  binary_search = "cpp/algorithm/binary_search",
  accumulate = "cpp/algorithm/accumulate",
  for_each = "cpp/algorithm/for_each",
  transform = "cpp/algorithm/transform",
  copy = "cpp/algorithm/copy",
  move = "cpp/algorithm/move",
  swap = "cpp/algorithm/swap",

  -- Utilities
  pair = "cpp/utility/pair",
  tuple = "cpp/utility/tuple",
  optional = "cpp/utility/optional",
  variant = "cpp/utility/variant",
  any = "cpp/utility/any",
  ["function"] = "cpp/utility/functional",
  bind = "cpp/utility/functional/bind",
  ref = "cpp/utility/functional/ref",

  -- I/O
  iostream = "cpp/header/iostream",
  fstream = "cpp/header/fstream",
  sstream = "cpp/header/sstream",
  iomanip = "cpp/header/iomanip",
  iosfwd = "cpp/header/iosfwd",
  streambuf = "cpp/header/streambuf",

  -- Threading
  thread = "cpp/thread/thread",
  mutex = "cpp/thread/mutex",
  condition_variable = "cpp/thread/condition_variable",
  future = "cpp/thread/future",
  promise = "cpp/thread/promise",
  atomic = "cpp/atomic/atomic",

  -- Chrono
  chrono = "cpp/chrono/chrono",
  system_clock = "cpp/chrono/system_clock",
  steady_clock = "cpp/chrono/steady_clock",
  high_resolution_clock = "cpp/chrono/high_resolution_clock",
  duration = "cpp/chrono/duration",
  time_point = "cpp/chrono/time_point",

  -- C standard library (in C++)
  ["printf"] = "c/io/fprintf",
  ["scanf"] = "c/io/scanf",
  ["malloc"] = "c/memory/malloc",
  ["free"] = "c/memory/free",
  ["strlen"] = "c/string/byte/strlen",
  ["strcpy"] = "c/string/byte/strcpy",
  ["strcmp"] = "c/string/byte/strcmp",
}

---@param symbol string
---@return string|nil
local function resolve_cpp_url(symbol)
  local prefix = "std::"
  local name = symbol
  if symbol:sub(1, #prefix) == prefix then
    name = symbol:sub(#prefix + 1)
  end

  local page = CPP_PAGE_MAPPING[name]
  if page then return page end

  if symbol:sub(1, #prefix) == prefix then
    -- Guessing order: container -> algorithm -> utility -> generic cpp/
    local guesses = { "cpp/container/", "cpp/algorithm/", "cpp/utility/" }
    for _, g in ipairs(guesses) do
      return g .. name
    end
    return "cpp/" .. name
  end

  return "c/" .. name
end

-- Cache for external documentation
local external_docs_cache = {}

---@param html string
---@return string|nil
local function extract_main_content(html)
  local start_idx = html:find('<div id="mw-content-text"')
  if not start_idx then return nil end
  start_idx = html:find('>', start_idx)
  if not start_idx then return nil end
  start_idx = start_idx + 1

  local end_idx = html:find('</div>', start_idx)
  if not end_idx then return nil end

  return html:sub(start_idx, end_idx)
end

local HTML_REPLACEMENTS = {
  -- Block elements
  { '<h1[^>]*>', '# ' }, { '</h1>', '\n' },
  { '<h2[^>]*>', '## ' }, { '</h2>', '\n' },
  { '<h3[^>]*>', '### ' }, { '</h3>', '\n' },
  { '<h4[^>]*>', '#### ' }, { '</h4>', '\n' },
  { '<h5[^>]*>', '##### ' }, { '</h5>', '\n' },
  { '<h6[^>]*>', '###### ' }, { '</h6>', '\n' },
  { '<p[^>]*>', '\n' }, { '</p>', '\n' },
  { '<ul[^>]*>', '\n' }, { '</ul>', '\n' },
  { '<ol[^>]*>', '\n' }, { '</ol>', '\n' },
  { '<li[^>]*>', '- ' }, { '</li>', '\n' },
  { '<pre[^>]*>', '```\n' }, { '</pre>', '\n```\n' },
  { '<code[^>]*>', '`' }, { '</code>', '`' },
  { '<table[^>]*>', '\n' }, { '</table>', '\n' },
  { '<thead[^>]*>', '\n' }, { '</thead>', '\n' },
  { '<tbody[^>]*>', '\n' }, { '</tbody>', '\n' },
  { '<tr[^>]*>', '\n' }, { '</tr>', '\n' },
  { '<th[^>]*>', '| ' }, { '</th>', ' |' },
  { '<td[^>]*>', '| ' }, { '</td>', ' |' },
  { '<hr[%s/>]*>', '\n---\n' },
  { '<br[%s/>]*>', '\n' },
  { '<div[^>]*>', '\n' }, { '</div>', '\n' },
  { '<span[^>]*>', '' }, { '</span>', '' },
  -- Emphasis
  { '<strong[^>]*>', '**' }, { '</strong>', '**' },
  { '<b[^>]*>', '**' }, { '</b>', '**' },
  { '<em[^>]*>', '*' }, { '</em>', '*' },
  { '<i[^>]*>', '*' }, { '</i>', '*' },
  { '<del[^>]*>', '~~' }, { '</del>', '~~' },
  { '<ins[^>]*>', '__' }, { '</ins>', '__' },
  { '<mark[^>]*>', '==' }, { '</mark>', '==' },
}

local ENTITY_REPLACEMENTS = {
  ['&lt;'] = '<', ['&gt;'] = '>', ['&amp;'] = '&', ['&quot;'] = '"', ['&#39;'] = "'",
  ['&nbsp;'] = ' ', ['&ldquo;'] = '"', ['&rdquo;'] = '"', ['&lsquo;'] = "'", ['&rsquo;'] = "'",
}

---@param content string
---@return string[]|nil
local function convert_html_to_markdown(content)
  -- Remove high-noise elements first
  content = content:gsub('<script[^>]*>.*?</script>', '')
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
    if line ~= '' then table.insert(lines, line) end
  end

  -- Clean up consecutive empty lines (max 2)
  local i = 2
  while i <= #lines do
    if lines[i] == '' and lines[i-1] == '' and lines[i-2] == '' then
      table.remove(lines, i)
    else
      i = i + 1
    end
  end

  while #lines > 0 and lines[1] == '' do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines] == '' do table.remove(lines) end

  if #lines > 30 then
    lines = { table.unpack(lines, 1, 30) }
    table.insert(lines, "")
    table.insert(lines, "... (truncated for brevity)")
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

  local url = "https://en.cppreference.com/w/" .. page .. "?printable=yes"

  vim.system({ "curl", "-s", "-L", "--max-time", "8", url }, {}, function(obj)
    if obj.code ~= 0 or not obj.stdout or obj.stdout == "" then
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
    local s, e = line_text:find("[%a_#][%w_]*", pos)
    if not s then break end
    if col >= s - 1 and col <= e - 1 then
      return line_text:sub(s, e)
    end
    if s - 1 > col then break end
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
  if not raw or raw:match("^%s*$") then return nil end

  -- Strip leading " * " javadoc-style margin markers clangd sometimes passes through.
  local lines = {}
  for _, line in ipairs(vim.split(raw, "\n", { plain = true })) do
    table.insert(lines, (line:gsub("^%s*%*%s?", "")))
  end

  local joined = table.concat(lines, "\n")

  -- Fast path: no doxygen tags — return plain prose, stripped.
  if not joined:match("[@\\]param") and not joined:match("[@\\]return")
      and not joined:match("[@\\]brief") and not joined:match("[@\\]tparam")
      and not joined:match("[@\\]note") and not joined:match("[@\\]warning")
      and not joined:match("[@\\]deprecated") and not joined:match("[@\\]throws?")
      and not joined:match("[@\\]exception") then
    local result, started = {}, false
    for _, line in ipairs(lines) do
      if started or not line:match("^%s*$") then
        started = true
        table.insert(result, line)
      end
    end
    while #result > 0 and result[#result]:match("^%s*$") do table.remove(result) end
    return #result > 0 and result or nil
  end

  -- Full Doxygen parse — mirrors java.lua's @param/@return/@throws parse.
  local desc       = {}
  local tparams    = {}  -- { name=string, desc=string }  template params (C++)
  local params     = {}  -- { name=string, desc=string }
  local ret        = nil -- string
  local notes      = {}
  local warnings   = {}
  local throws     = {}  -- { type=string, desc=string }
  local deprecated = nil -- string
  local past_tags  = false

  -- Track which "bucket" the last tag opened, for multi-line continuation.
  -- Mirrors the continuation logic used in java.lua's @param multi-line handling.
  local last_tag   = nil -- "tparam"|"param"|"return"|"note"|"warn"|"throw"
  local last_idx   = nil

  local function append_continuation(line)
    local text = line:match("^%s*(.*)")
    if text == "" then
      last_tag = nil; last_idx = nil; return
    end
    if last_tag == "tparam" and last_idx then
      tparams[last_idx].desc = tparams[last_idx].desc .. " " .. text
    elseif last_tag == "param" and last_idx then
      params[last_idx].desc = params[last_idx].desc .. " " .. text
    elseif last_tag == "return" and ret then
      ret = ret .. " " .. text
    elseif last_tag == "note" and last_idx then
      notes[last_idx] = notes[last_idx] .. " " .. text
    elseif last_tag == "warn" and last_idx then
      warnings[last_idx] = warnings[last_idx] .. " " .. text
    elseif last_tag == "throw" and last_idx then
      throws[last_idx].desc = throws[last_idx].desc .. " " .. text
    else
      last_tag = nil; last_idx = nil
    end
  end

  for _, line in ipairs(lines) do
    -- @brief desc
    local brief = line:match("^%s*[@\\]brief%s+(.*)")
    -- @tparam Name desc
    local tname, tdesc = line:match("^%s*[@\\]tparam%s+(%S+)%s*(.*)")
    -- @param [in|out|inout] Name desc  (bracket direction optional)
    local pname, pdesc = line:match("^%s*[@\\]param%s*%[?%a*%]?%s*(%S+)%s*(.*)")
    -- @return / @returns desc
    local rdesc = line:match("^%s*[@\\]returns?%s+(.*)")
    -- @note desc
    local ndesc = line:match("^%s*[@\\]note%s+(.*)")
    -- @warning desc
    local wdesc = line:match("^%s*[@\\]warning%s+(.*)")
    -- @throws / @throw / @exception ExcType desc
    local etype, edesc = line:match("^%s*[@\\](?:throws?|exception)%s+(%S+)%s*(.*)")
    if not etype then
      etype, edesc = line:match("^%s*[@\\]throws?%s+(%S+)%s*(.*)")
    end
    if not etype then
      etype, edesc = line:match("^%s*[@\\]exception%s+(%S+)%s*(.*)")
    end
    -- @deprecated desc
    local depr = line:match("^%s*[@\\]deprecated%s*(.*)")

    if brief then
      past_tags = true
      last_tag  = nil
      table.insert(desc, brief)
    elseif tname then
      past_tags = true
      table.insert(tparams, { name = tname, desc = tdesc or "" })
      last_tag = "tparam"; last_idx = #tparams
    elseif pname then
      past_tags = true
      table.insert(params, { name = pname, desc = pdesc or "" })
      last_tag = "param"; last_idx = #params
    elseif rdesc then
      past_tags = true
      ret       = rdesc
      last_tag  = "return"; last_idx = nil
    elseif ndesc then
      past_tags = true
      table.insert(notes, ndesc)
      last_tag = "note"; last_idx = #notes
    elseif wdesc then
      past_tags = true
      table.insert(warnings, wdesc)
      last_tag = "warn"; last_idx = #warnings
    elseif etype then
      past_tags = true
      table.insert(throws, { type = etype, desc = edesc or "" })
      last_tag = "throw"; last_idx = #throws
    elseif depr then
      past_tags  = true
      deprecated = depr
      last_tag   = nil
    elseif not past_tags then
      last_tag = nil
      table.insert(desc, line)
    else
      -- Possible continuation of the previous tag (indented or non-blank).
      if line:match("^%s+") and last_tag then
        append_continuation(line)
      else
        last_tag = nil
      end
    end
  end

  while #desc > 0 and desc[1]:match("^%s*$") do table.remove(desc, 1) end
  while #desc > 0 and desc[#desc]:match("^%s*$") do table.remove(desc) end

  local out = {}
  for _, l in ipairs(desc) do table.insert(out, l) end

  if #tparams > 0 then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "**Template Parameters**")
    for _, p in ipairs(tparams) do
      local entry = "- `" .. p.name .. "`"
      if p.desc ~= "" then entry = entry .. " — " .. p.desc end
      table.insert(out, entry)
    end
  end

  if #params > 0 then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "**Parameters**")
    for _, p in ipairs(params) do
      local entry = "- `" .. p.name .. "`"
      if p.desc ~= "" then entry = entry .. " — " .. p.desc end
      table.insert(out, entry)
    end
  end

  if ret and ret ~= "" then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "**Returns** — " .. ret)
  end

  if #throws > 0 then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "**Throws**")
    for _, t in ipairs(throws) do
      local entry = "- `" .. t.type .. "`"
      if t.desc ~= "" then entry = entry .. " — " .. t.desc end
      table.insert(out, entry)
    end
  end

  for _, n in ipairs(notes) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Note:** " .. n)
  end

  for _, w in ipairs(warnings) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Warning:** " .. w)
  end

  if deprecated and deprecated ~= "" then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Deprecated:** " .. deprecated)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
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
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""

  local new_col
  local pos       = 1
  while true do
    local s, e = line_text:find("[%a_][%w_]*", pos)
    if not s then break end
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
  util.std_request(bufnr, "clangd", "textDocument/hover", new_params, function(result)
    cb(util.parse_hover_result(result, ft, format_docs))
  end)
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
  util.std_request(bufnr, "clangd", "textDocument/hover", params, function(result)
    local sig_lines, doc_lines = util.parse_hover_result(result, ft, format_docs)
    if sig_lines then
      cb(sig_lines, doc_lines)
      return
    end

    local col       = params.position.character
    local line_nr   = params.position.line
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
    if is_keyword(ft, util.word_containing(line_text, col, "[%a_#][%w_]*")) then
      cb(nil, nil)
      return
    end

    retry_at_symbol(bufnr, params, ft, cb)
  end)
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
  local want_subs  = cfg.sections.implementations

  if not want_super and not want_subs then
    on_super({})
    on_subs({})
    return
  end

  util.std_request(bufnr, "clangd", "textDocument/prepareTypeHierarchy", params, function(items)
    if not items or #items == 0 then
      on_super({})
      on_subs({})
      return
    end

    local item = items[1]

    if want_super then
      util.client_request(bufnr, "clangd", "typeHierarchy/supertypes",
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
              if it.detail and it.detail ~= "" then
                entry = entry .. "  `" .. it.detail .. "`"
              end
              table.insert(names, entry)
            end
          end
          on_super(names)
        end)
    else
      on_super({})
    end

    if want_subs then
      util.client_request(bufnr, "clangd", "typeHierarchy/subtypes",
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
              if it.detail and it.detail ~= "" then
                entry = entry .. "  `" .. it.detail .. "`"
              end
              table.insert(names, entry)
            end
          end
          on_subs(names)
        end)
    else
      on_subs({})
    end
  end)
end

---@param bufnr integer
---@param params table
---@param cb fun(names: string[])
local function fetch_implementations(bufnr, params, cb)
  util.std_request(bufnr, "clangd", "textDocument/implementation", params, function(result)
    if not result then
      cb({})
      return
    end
    local seen, names = {}, {}
    for _, loc in ipairs(vim.islist(result) and result or { result }) do
      local uri   = loc.uri or loc.targetUri or ""
      local base  = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t:r")
      local line  = (loc.range or loc.targetSelectionRange or { start = { line = 0 } }).start.line
      local label = base ~= "" and (base .. ":" .. (line + 1)) or "?"
      if not seen[label] then
        seen[label] = true
        table.insert(names, label)
      end
      if #names >= 12 then break end
    end
    if #names >= 12 then table.insert(names, "…(more)") end
    cb(names)
  end)
end

---@param bufnr integer
---@param params table
---@param cb fun(info: string|nil)
local function fetch_macro(bufnr, params, cb)
  util.std_request(bufnr, "clangd", "textDocument/symbolInfo", params, function(result)
    if not result or #result == 0 then
      cb(nil)
      return
    end
    local sym = result[1]
    cb(sym and sym.kind == 14 and ("Macro: `" .. (sym.name or "?") .. "`") or nil)
  end)
end

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params    = util.pos_params(bufnr)
  local cfg       = require("linus").config
  local ft        = vim.bo[bufnr].filetype

  -- Get the word under the cursor early for keyword check and external docs
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  local word      = util.word_containing(line_text, col, "[%a_#][%w_]*")

  -- Fast-path for keywords: skip all LSP work and let main.lua serve the
  -- built-in reference.  Must happen before any request fires.
  if is_keyword(ft, word) then
    done({})
    return
  end

  -- Determine if we should fetch external documentation
  local fetch_external = cfg.sections.external_docs and word and word:find("^std::") ~= nil

  -- Six async slots — barrier must be reached exactly 6 times:
  --   1. hover
  --   2. supertypes  ┐ both from fetch_hierarchy after one prepare call;
  --   3. subtypes    ┘ each calls tick() independently
  --   4. textDocument/implementation
  --   5. textDocument/symbolInfo (macro detection)
  --   6. external documentation
  local data = {}
  local tick = util.barrier(6, function() done(data) end)

  -- Slot 1
  fetch_hover(bufnr, params, ft, function(sig_lines, doc_lines)
    data.signature = sig_lines
    data.docs      = doc_lines
    tick()
  end)

  -- Slots 2 + 3
  fetch_hierarchy(bufnr, params, cfg,
    function(types)
      if #types > 0 then data.hierarchy = types end
      tick() -- slot 2
    end,
    function(types)
      if #types > 0 then
        data.implementations = data.implementations or {}
        vim.list_extend(data.implementations, types)
      end
      tick() -- slot 3
    end
  )

  -- Slot 4
  if cfg.sections.implementations then
    fetch_implementations(bufnr, params, function(impls)
      if #impls > 0 then
        data.implementations = data.implementations or {}
        local seen = {}
        for _, v in ipairs(data.implementations) do seen[v] = true end
        for _, v in ipairs(impls) do
          if not seen[v] then table.insert(data.implementations, v) end
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
      if info then data.extra = { info } end
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
