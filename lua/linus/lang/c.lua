-- linus/lang/c.lua  (also used by cpp.lua)
-- clangd enricher: hover with doxygen formatting, type hierarchy, macro detection.

local util = require("linus.lang.util")

local M = {}

-- ── Doc formatting ─────────────────────────────────────────────────────────────

-- Turn raw doxygen/doc-comment text into clean markdown lines.
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  local lines  = vim.split(raw, "\n", { plain = true })
  local joined = table.concat(lines, "\n")

  -- No doxygen tags → already clean prose, just strip leading blanks.
  if not joined:match("[@\\]param") and not joined:match("[@\\]return")
      and not joined:match("[@\\]brief") then
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

  -- Parse @brief, @param, @return, @note / @warning.
  local desc      = {}
  local params    = {}
  local ret       = nil
  local notes     = {}
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

  for _, n in ipairs(notes) do
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Note:** " .. n)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

---@param bufnr integer
---@param params table
---@param cb fun(types: string[])
local function fetch_hierarchy(bufnr, params, cb)
  util.std_request(bufnr, "clangd", "textDocument/prepareTypeHierarchy", params, function(items)
    if not items or #items == 0 then cb({}) return end
    util.client_request(bufnr, "clangd", "typeHierarchy/supertypes", { item = items[1], resolve = 3 }, function(result)
      if not result then cb({}) return end
      local names = {}
      for _, item in ipairs(result) do
        if item.name then
          local entry = item.name
          if item.detail and item.detail ~= "" then entry = entry .. "  `" .. item.detail .. "`" end
          table.insert(names, entry)
        end
      end
      cb(names)
    end)
  end)
end

-- clangd extension: detect macros by their SymbolKind (14 = Macro).
---@param bufnr integer
---@param params table
---@param cb fun(info: string|nil)
local function fetch_macro(bufnr, params, cb)
  util.std_request(bufnr, "clangd", "textDocument/symbolInfo", params, function(result)
    if not result or #result == 0 then cb(nil) return end
    local sym = result[1]
    cb(sym and sym.kind == 14 and ("Macro: `" .. (sym.name or "?") .. "`") or nil)
  end)
end

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params = util.pos_params(bufnr)
  local cfg    = require("linus").config
  local data   = {}
  local tick   = util.barrier(3, function() done(data) end)

  util.std_request(bufnr, "clangd", "textDocument/hover", params, function(result)
    if result then
      local sig, doc = util.split_fence(util.extract_value(result.contents))
      if sig ~= "" then data.signature = util.to_lines(sig) end
      local formatted = format_docs(doc)
      if formatted then data.docs = formatted end
    end
    tick()
  end)

  if cfg.sections.hierarchy then
    fetch_hierarchy(bufnr, params, function(types)
      if #types > 0 then data.hierarchy = types end
      tick()
    end)
  else
    tick()
  end

  fetch_macro(bufnr, params, function(info)
    if info then data.extra = { info } end
    tick()
  end)
end

return M
