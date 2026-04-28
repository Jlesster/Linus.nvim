-- linus/lang/c.lua  (also used by cpp.lua)
-- clangd enricher: hover, doxygen formatting, type hierarchy (up + down), implementations, macro detection.

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
  ["_Bool"] = true,
  ["_Complex"] = true,
  ["_Imaginary"] = true,
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

---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  local lines  = vim.split(raw, "\n", { plain = true })
  local joined = table.concat(lines, "\n")

  if not joined:match("[@\\]param") and not joined:match("[@\\]return")
      and not joined:match("[@\\]brief") then
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

  local desc, params, ret, notes = {}, {}, nil, {}
  local past_tags = false

  for _, line in ipairs(lines) do
    local brief        = line:match("^%s*[@\\]brief%s+(.*)")
    local pname, pdesc = line:match("^%s*[@\\]param%s+(%S+)%s*(.*)")
    local rdesc        = line:match("^%s*[@\\]returns?%s+(.*)")
    local ndesc        = line:match("^%s*[@\\]note%s+(.*)")
        or line:match("^%s*[@\\]warning%s+(.*)")

    if brief then
      table.insert(desc, brief)
    elseif pname then
      past_tags = true
      table.insert(params, { name = pname, desc = pdesc or "" })
    elseif rdesc then
      past_tags = true
      ret = rdesc
    elseif ndesc then
      past_tags = true
      table.insert(notes, ndesc)
    elseif not past_tags then
      table.insert(desc, line)
    end
  end

  while #desc > 0 and desc[1]:match("^%s*$") do table.remove(desc, 1) end
  while #desc > 0 and desc[#desc]:match("^%s*$") do table.remove(desc) end

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

  for _, n in ipairs(notes) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Note:** " .. n)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

-- Fetch supertypes and subtypes in parallel after a single prepareTypeHierarchy call.
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
      util.client_request(bufnr, "clangd", "typeHierarchy/supertypes", { item = item, resolve = 3 }, function(result)
        if not result then
          on_super({})
          tick()
          return
        end
        local names = {}
        for _, it in ipairs(result) do
          if it.name then
            local entry = it.name
            if it.detail and it.detail ~= "" then entry = entry .. "  `" .. it.detail .. "`" end
            table.insert(names, entry)
          end
        end
        on_super(names)
      end)
    else
      on_super({})
    end

    if want_subs then
      util.client_request(bufnr, "clangd", "typeHierarchy/subtypes", { item = item, resolve = 3 }, function(result)
        if not result then
          on_subs({})
          return
        end
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

-- Fetch implementations via textDocument/implementation (virtual functions, interfaces via concepts).
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

  -- Keyword fast-path: skip all LSP work, let providers/main.lua serve built-in ref.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if is_keyword(ft, word_at(line_text, col)) then
    done({})
    return
  end

  -- 5 concurrent async results: hover, supertypes, subtypes, implementations, macro.
  local data = {}
  local tick = util.barrier(5, function() done(data) end)

  util.std_request(bufnr, "clangd", "textDocument/hover", params, function(result)
    if result then
      local sig, doc = util.split_fence(util.extract_value(result.contents))
      if sig ~= "" then data.signature = util.to_lines(sig) end
      local formatted = format_docs(doc)
      if formatted then data.docs = formatted end
    end
    tick()
  end)

  fetch_hierarchy(bufnr, params, cfg,
    function(types)
      if #types > 0 then data.hierarchy = types end
      tick()
    end,
    function(types)
      if #types > 0 then
        data.implementations = data.implementations or {}
        vim.list_extend(data.implementations, types)
      end
      tick()
    end
  )

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

  if cfg.sections.extra ~= false then
    fetch_macro(bufnr, params, function(info)
      if info then data.extra = { info } end
      tick()
    end)
  else
    tick()
  end
end

return M
