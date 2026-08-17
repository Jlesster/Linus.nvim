-- linus/lang/java.lua
-- jdtls enricher: hover with javadoc, type hierarchy, and known subtypes.

local util = require("linus.lang.util")

local M = {}

-- ── Hover parsing ─────────────────────────────────────────────────────────────

-- Turn raw javadoc text into clean markdown lines.
-- Handles both raw @tag format (older jdtls) and pre-formatted markdown (modern).
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  -- Strip " * " javadoc margin markers that sometimes appear in raw output.
  local lines = {}
  for _, line in ipairs(vim.split(raw, "\n", { plain = true })) do
    table.insert(lines, (line:gsub("^%s*%*%s?", "")))
  end

  -- Modern jdtls already returns well-formed markdown with no @tags.
  local joined = table.concat(lines, "\n")
  if not joined:match("@param") and not joined:match("@return") and not joined:match("@throws") then
    local result  = {}
    local started = false
    for _, line in ipairs(lines) do
      if started or not line:match("^%s*$") then
        started = true
        table.insert(result, line)
      end
    end
    while #result > 0 and result[#result]:match("^%s*$") do table.remove(result) end
    return #result > 0 and result or nil
  end

  -- Raw javadoc: parse description and @tags into formatted sections.
  local desc      = {}
  local params    = {}
  local ret       = nil
  local throws    = {}
  local past_tags = false

  for _, line in ipairs(lines) do
    local pname, pdesc = line:match("^@param%s+(%S+)%s*(.*)")
    local rdesc        = line:match("^@return%s+(.*)")
    local etype, edesc = line:match("^@throws?%s+(%S+)%s*(.*)")

    if pname then
      past_tags = true
      table.insert(params, { name = pname, desc = pdesc or "" })
    elseif rdesc then
      past_tags = true
      ret = rdesc
    elseif etype then
      past_tags = true
      table.insert(throws, { type = etype, desc = edesc or "" })
    elseif not past_tags then
      table.insert(desc, line)
    end
  end

  while #desc > 0 and desc[1]:match("^%s*$")    do table.remove(desc, 1) end
  while #desc > 0 and desc[#desc]:match("^%s*$") do table.remove(desc)    end

  local out = {}
  for _, l in ipairs(desc) do table.insert(out, l) end

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

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── Curated External Documentation ──────────────────────────────────────────────────

local CURATED_JAVA_DOCS = {
  ['ArrayList'] = {
    '**Dynamic Array**',
    'A resizable-array implementation of the `List` interface.',
    '',
    '- **Access**: `O(1)` random access.',
    '- **Insertion/Deletion**: `O(1)` amortized at the end; `O(n)` elsewhere.',
    '- **Storage**: Contiguous memory block.',
    '',
    'Common methods: `add()`, `get()`, `remove()`, `size()`, `clear()`.',
  },
  ['HashMap'] = {
    '**Hash Table**',
    'A map based on a hash table, providing fast lookups.',
    '',
    '- **Complexity**: `O(1)` average case for get, put, and remove.',
    '- **Ordering**: No guaranteed order of keys.',
    '',
    'Common methods: `put()`, `get()`, `containsKey()`, `remove()`, `entrySet()`.',
  },
  ['HashSet'] = {
    '**Hash Set**',
    'A collection that contains no duplicate elements, backed by a `HashMap`.',
    '',
    '- **Complexity**: `O(1)` average case for add, remove, and contains.',
    '',
    'Common methods: `add()`, `remove()`, `contains()`, `clear()`.',
  },
  ['Optional'] = {
    '**Optional Value**',
    'A container object which may or may not contain a non-null value.',
    '',
    '- **Purpose**: Explicitly represent the absence of a value to avoid `NullPointerException`.',
    '- **Nature**: Immutable value container.',
    '',
    'Common methods: `isPresent()`, `orElse()`, `orElseGet()`, `ifPresent()`, `map()`.',
  },
  ['Stream'] = {
    '**Sequence Processor**',
    'A sequence of elements supporting sequential and parallel aggregate operations.',
    '',
    '- **Pipeline**: source $\to$ intermediate (filter, map) $\to$ terminal (collect, reduce).',
    '- **Evaluation**: Lazy; intermediate operations are not executed until a terminal operation is called.',
    '',
    'Common methods: `filter()`, `map()`, `flatMap()`, `sorted()`, `collect()`, `reduce()`.',
  },
  ['String'] = {
    '**Immutable Sequence**',
    'A sequence of characters that is immutable and supports interning.',
    '',
    '- **Nature**: Once created, the value cannot be changed.',
    '- **String Pool**: Literal strings are stored in a common pool to save memory.',
    '',
    'Common methods: `substring()`, `indexOf()`, `replace()`, `split()`, `trim()`.',
  },
  ['StringBuilder'] = {
    '**Mutable String**',
    'A mutable sequence of characters for efficient string concatenation.',
    '',
    '- **Performance**: Far more efficient than `String` concatenation in loops.',
    '- **Thread Safety**: Not thread-safe; use `StringBuffer` for multi-threaded environments.',
    '',
    'Common methods: `append()`, `insert()`, `delete()`, `reverse()`, `toString()`.',
  },
  ['ConcurrentHashMap'] = {
    '**Thread-Safe Map**',
    'A highly concurrent hash map with fine-grained locking.',
    '',
    '- **Performance**: High scalability under contention; does not lock the entire map.',
    '- **Ordering**: No guaranteed order.',
    '',
    'Common methods: `putIfAbsent()`, `computeIfAbsent()`, `merge()`.',
  },
  ['CompletableFuture'] = {
    '**Async Future**',
    'A future that can be manually completed and supports callback chaining.',
    '',
    '- **Concurrency**: Usually runs tasks in the `ForkJoinPool.commonPool()` by default.',
    '- **Composition**: Supports `thenApply()`, `thenCompose()`, and `thenCombine()`.',
    '',
    'Common methods: `supplyAsync()`, `thenAccept()`, `get()`, `join()`, `complete()`.',
  },
}

local JAVA_QUALIFIED_NAMES = {
  ArrayList = 'java.util.ArrayList',
  HashMap = 'java.util.HashMap',
  HashSet = 'java.util.HashSet',
  Optional = 'java.util.Optional',
  Stream = 'java.util.stream.Stream',
  String = 'java.lang.String',
  StringBuilder = 'java.lang.StringBuilder',
  ConcurrentHashMap = 'java.util.concurrent.ConcurrentHashMap',
  CompletableFuture = 'java.util.concurrent.CompletableFuture',
  LinkedList = 'java.util.LinkedList',
  PriorityQueue = 'java.util.PriorityQueue',
  Collections = 'java.util.Collections',
  Arrays = 'java.util.Arrays',
}

local function resolve_java_url(symbol)
  if not symbol or symbol == '' then return nil end
  local qualified = JAVA_QUALIFIED_NAMES[symbol]
  if not qualified then return nil end

  local path = qualified:gsub('%.', '/')
  return 'https://docs.oracle.com/en/java/javase/21/docs/api/java.base/' .. path .. '.html'
end

local external_docs_cache = {}

local function fetch_external_docs(symbol, callback)
  if external_docs_cache[symbol] ~= nil then
    callback(external_docs_cache[symbol])
    return
  end

  local curated = CURATED_JAVA_DOCS[symbol]
  if curated then
    external_docs_cache[symbol] = curated
    callback(curated)
    return
  end

  external_docs_cache[symbol] = false
  callback(nil)
end

-- All Java keywords that jdtls returns empty hover for.
-- "return" must be quoted because it is a Lua reserved word.
local JAVA_KEYWORDS = {
  abstract=true,  boolean=true,    byte=true,     char=true,
  class=true,     default=true,    double=true,   enum=true,
  extends=true,   final=true,      float=true,    implements=true,
  import=true,    instanceof=true, int=true,      interface=true,
  long=true,      native=true,     new=true,      package=true,
  private=true,   protected=true,  public=true,   record=true,
  ["return"]=true, short=true,     static=true,   strictfp=true,
  super=true,     synchronized=true, this=true,   throws=true,
  transient=true, void=true,       volatile=true,
}

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

-- When hover returns nothing for a non-keyword position, scan ahead on the
-- same line for the first non-keyword identifier after the cursor and retry.
---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function retry_at_symbol(bufnr, params, cb)
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""

  local new_col
  local pos = 1
  while true do
    local s, e = line_text:find("[%a_$][%w_$]*", pos)
    if not s then break end
    local word_col = s - 1  -- convert to 0-based
    if word_col > col and not JAVA_KEYWORDS[line_text:sub(s, e)] then
      new_col = word_col
      break
    end
    pos = e + 1
  end

  if not new_col then cb(nil, nil) return end

  local new_params = vim.deepcopy(params)
  new_params.position.character = new_col
  util.std_request(bufnr, "jdtls", "textDocument/hover", new_params, function(result)
    cb(util.parse_hover_result(result, "java", format_docs))
  end)
end

---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, cb)
  util.std_request(bufnr, "jdtls", "textDocument/hover", params, function(result)
    local sig_lines, doc_lines = util.parse_hover_result(result, "java", format_docs)
    if sig_lines then
      cb(sig_lines, doc_lines)
      return
    end

    -- If hover returned nothing because the cursor is on a keyword, bail out
    -- cleanly so main.lua can serve the built-in keyword reference.
    local col       = params.position.character
    local line_nr   = params.position.line
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
    if JAVA_KEYWORDS[util.word_containing(line_text, col, "[%a_$][%w_$]*")] then
      cb(nil, nil)
      return
    end

    retry_at_symbol(bufnr, params, cb)
  end)
end

-- Run prepareTypeHierarchy once, then fire supertypes and subtypes in parallel.
-- Saves one LSP round trip compared to calling prepareTypeHierarchy twice.
---@param bufnr integer
---@param params table
---@param cfg table
---@param on_super fun(extends: string[], implements: string[])
---@param on_subs  fun(types: string[])
local function fetch_hierarchy(bufnr, params, cfg, on_super, on_subs)
  local want_super = cfg.sections.hierarchy or cfg.sections.implements
  local want_subs  = cfg.sections.implementations

  if not want_super and not want_subs then
    on_super({}, {})
    on_subs({})
    return
  end

  util.std_request(bufnr, "jdtls", "textDocument/prepareTypeHierarchy", params, function(items)
    if not items or #items == 0 then
      on_super({}, {})
      on_subs({})
      return
    end

    local item = items[1]

    if want_super then
      util.client_request(bufnr, "jdtls", "typeHierarchy/supertypes", { item = item, resolve = 5 }, function(result)
        if not result then on_super({}, {}) return end
        local extends, implements = {}, {}
        for _, it in ipairs(result) do
          if it.name then
            local entry = it.name
            if it.detail and it.detail ~= "" then entry = entry .. "  `" .. it.detail .. "`" end
            if it.kind == 11 then table.insert(implements, entry) else table.insert(extends, entry) end
          end
        end
        on_super(extends, implements)
      end)
    else
      on_super({}, {})
    end

    if want_subs then
      util.client_request(bufnr, "jdtls", "typeHierarchy/subtypes", { item = item, resolve = 3 }, function(result)
        if not result then on_subs({}) return end
        local names = {}
        for _, it in ipairs(result) do
          if it.name then
            local entry = it.name
            if it.detail and it.detail ~= "" then entry = entry .. "  `" .. it.detail .. "`" end
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

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params = util.pos_params(bufnr)
  local cfg    = require("linus").config

  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  local word = util.word_containing(line_text, col, "[%a_$][%w_$]*")

  -- Fast-path for keywords
  if word and JAVA_KEYWORDS[word] then
    done({})
    return
  end

  -- Four async results: hover, supertypes, subtypes, external docs.
  local data = {}
  local tick = util.barrier(4, function() done(data) end)

  fetch_hover(bufnr, params, function(sig_lines, doc_lines)
    data.signature = sig_lines
    data.docs      = doc_lines
    tick()
  end)

  fetch_hierarchy(bufnr, params, cfg,
    function(extends, implements)
      if #extends    > 0 then data.hierarchy  = extends    end
      if #implements > 0 then data.implements = implements end
      tick()
    end,
    function(types)
      if #types > 0 then data.implementations = types end
      tick()
    end
  )

  -- External documentation slot
  if cfg.sections.external_docs and word then
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
