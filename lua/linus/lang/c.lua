-- linus/lang/c.lua  (also used by cpp.lua)
-- clangd enricher: hover, doxygen formatting, type hierarchy (up + down),
-- implementations, macro detection.
-- Matches java.lua feature parity: retry_at_symbol, correct barrier accounting,
-- stray tick() upvalue bug from fetch_hierarchy removed.

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
  -- C99/C11 extensions
  ["_Bool"] = true,
  ["_Complex"] = true,
  ["_Imaginary"] = true,
  ["_Atomic"] = true,
  ["_Generic"] = true,
  ["_Static_assert"] = true,
  ["_Noreturn"] = true,
  ["_Thread_local"] = true,
  ["_Alignas"] = true,
  ["_Alignof"] = true,
  -- common macros treated as keywords for hover purposes
  ["NULL"] = true,
  ["true"] = true,
  ["false"] = true,
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

-- Match an identifier (including # for preprocessor) at 0-based col.
local function word_at(line_text, col)
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

-- ── Doc formatting ─────────────────────────────────────────────────────────────

-- Format clangd hover docs, which may be plain prose or Doxygen-annotated.
-- Handles @brief/@param/@return/@note/@warning and their \-prefix equivalents.
-- Also handles multi-line @param continuations and @tparam (template params).
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  local lines  = vim.split(raw, "\n", { plain = true })
  local joined = table.concat(lines, "\n")

  -- Fast path: no doxygen markers → return plain prose, stripped.
  if not joined:match("[@\\]param") and not joined:match("[@\\]return")
      and not joined:match("[@\\]brief") and not joined:match("[@\\]tparam")
      and not joined:match("[@\\]note") and not joined:match("[@\\]warning") then
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

  local desc      = {}
  local params    = {} -- { name, desc }
  local tparams   = {} -- { name, desc }  (template params)
  local ret       = nil
  local notes     = {}
  local warnings  = {}
  local past_tags = false

  -- Track multi-line continuation for the last opened tag type.
  local last_tag  = nil -- "param" | "tparam" | "return" | "note" | "warn"
  local last_idx  = nil -- index into params/tparams/notes/warnings

  local function flush_continuation(line)
    if not last_tag or line:match("^%s*$") then
      last_tag = nil
      last_idx = nil
      return false
    end
    -- Continuation: line has content and no new tag, indented or bare.
    if line:match("^%s+") or not line:match("^[@\\]") then
      local text = line:match("^%s*(.*)")
      if last_tag == "param" and last_idx then
        params[last_idx].desc = params[last_idx].desc .. " " .. text
        return true
      elseif last_tag == "tparam" and last_idx then
        tparams[last_idx].desc = tparams[last_idx].desc .. " " .. text
        return true
      elseif last_tag == "return" and ret then
        ret = ret .. " " .. text
        return true
      elseif last_tag == "note" and last_idx then
        notes[last_idx] = notes[last_idx] .. " " .. text
        return true
      elseif last_tag == "warn" and last_idx then
        warnings[last_idx] = warnings[last_idx] .. " " .. text
        return true
      end
    end
    last_tag = nil
    last_idx = nil
    return false
  end

  for _, line in ipairs(lines) do
    local brief        = line:match("^%s*[@\\]brief%s+(.*)")
    local pname, pdesc = line:match("^%s*[@\\]param%s*%[?%a*%]?%s*(%S+)%s*(.*)")
    local tname, tdesc = line:match("^%s*[@\\]tparam%s+(%S+)%s*(.*)")
    local rdesc        = line:match("^%s*[@\\]returns?%s+(.*)")
    local ndesc        = line:match("^%s*[@\\]note%s+(.*)")
    local wdesc        = line:match("^%s*[@\\]warning%s+(.*)")

    if brief then
      past_tags = true
      last_tag  = nil
      table.insert(desc, brief)
    elseif pname then
      past_tags = true
      table.insert(params, { name = pname, desc = pdesc or "" })
      last_tag = "param"
      last_idx = #params
    elseif tname then
      past_tags = true
      table.insert(tparams, { name = tname, desc = tdesc or "" })
      last_tag = "tparam"
      last_idx = #tparams
    elseif rdesc then
      past_tags = true
      ret       = rdesc
      last_tag  = "return"
      last_idx  = nil
    elseif ndesc then
      past_tags = true
      table.insert(notes, ndesc)
      last_tag = "note"
      last_idx = #notes
    elseif wdesc then
      past_tags = true
      table.insert(warnings, wdesc)
      last_tag = "warn"
      last_idx = #warnings
    elseif not past_tags then
      last_tag = nil
      table.insert(desc, line)
    else
      -- Possibly a continuation of the previous tag.
      flush_continuation(line)
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

  for _, n in ipairs(notes) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Note:** " .. n)
  end

  for _, w in ipairs(warnings) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Warning:** " .. w)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

-- When clangd hover returns nothing for a non-keyword, scan ahead on the same
-- line for the first non-keyword identifier after the cursor and retry.
-- Mirrors java.lua's retry_at_symbol.
---@param bufnr integer
---@param params table
---@param ft string  filetype ("c" or "cpp") for keyword lookup
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
    local word_col = s - 1 -- convert to 0-based
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
    if not result then
      cb(nil, nil)
      return
    end
    local sig, doc  = util.split_fence(util.extract_value(result.contents))
    local sig_lines = sig ~= "" and util.to_lines(sig) or nil
    local doc_lines = format_docs(doc)
    cb(sig_lines, doc_lines)
  end)
end

---@param bufnr integer
---@param params table
---@param ft string
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, ft, cb)
  util.std_request(bufnr, "clangd", "textDocument/hover", params, function(result)
    if not result then
      retry_at_symbol(bufnr, params, ft, cb)
      return
    end

    local sig, doc  = util.split_fence(util.extract_value(result.contents))
    local sig_lines = sig ~= "" and util.to_lines(sig) or nil
    local doc_lines = format_docs(doc)

    if sig_lines then
      cb(sig_lines, doc_lines)
    else
      retry_at_symbol(bufnr, params, ft, cb)
    end
  end)
end

-- Fetch supertypes and subtypes via a single prepareTypeHierarchy call.
-- IMPORTANT: both on_super and on_subs are guaranteed to be called exactly once.
-- The previous implementation had a stray `tick()` call inside this function
-- that referenced the `tick` upvalue from enrich() — which is out of scope here.
-- That has been removed; callers handle tick() themselves.
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

-- Fetch implementations via textDocument/implementation.
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

  -- Keyword fast-path: skip all LSP work, let providers/main.lua serve the
  -- built-in keyword reference.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if is_keyword(ft, word_at(line_text, col)) then
    done({})
    return
  end

  -- Five concurrent async slots:
  --   1. hover       (fetch_hover — may internally retry once)
  --   2. supertypes  ┐ both resolved inside fetch_hierarchy;
  --   3. subtypes    ┘ each calls tick() exactly once
  --   4. textDocument/implementation
  --   5. textDocument/symbolInfo (macro detection)
  local data = {}
  local tick = util.barrier(5, function() done(data) end)

  -- ── Slot 1: hover ─────────────────────────────────────────────────────────
  fetch_hover(bufnr, params, ft, function(sig_lines, doc_lines)
    if sig_lines then data.signature = sig_lines end
    if doc_lines then data.docs = doc_lines end
    tick()
  end)

  -- ── Slots 2 & 3: type hierarchy ───────────────────────────────────────────
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

  -- ── Slot 4: virtual / concept implementations ─────────────────────────────
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
      tick() -- slot 4
    end)
  else
    tick() -- slot 4 (skipped)
  end

  -- ── Slot 5: macro detection ────────────────────────────────────────────────
  if cfg.sections.extra ~= false then
    fetch_macro(bufnr, params, function(info)
      if info then data.extra = { info } end
      tick() -- slot 5
    end)
  else
    tick() -- slot 5 (skipped)
  end
end

return M
