-- linus/lang/go.lua
-- gopls enricher: hover with godoc formatting, type hierarchy, interface implementations.
-- Matches java.lua feature parity: structured doc parsing, retry_at_symbol, correct barrier accounting.

local util = require("linus.lang.util")

local M = {}

-- ── Keyword fast-path ─────────────────────────────────────────────────────────

local GO_KEYWORDS = {
  ["break"] = true,
  ["case"] = true,
  ["chan"] = true,
  ["const"] = true,
  ["continue"] = true,
  ["default"] = true,
  ["defer"] = true,
  ["else"] = true,
  ["fallthrough"] = true,
  ["for"] = true,
  ["func"] = true,
  ["go"] = true,
  ["goto"] = true,
  ["if"] = true,
  ["import"] = true,
  ["interface"] = true,
  ["map"] = true,
  ["package"] = true,
  ["range"] = true,
  ["return"] = true,
  ["select"] = true,
  ["struct"] = true,
  ["switch"] = true,
  ["type"] = true,
  ["var"] = true,
  -- built-in identifiers
  ["append"] = true,
  ["cap"] = true,
  ["close"] = true,
  ["complex"] = true,
  ["copy"] = true,
  ["delete"] = true,
  ["imag"] = true,
  ["len"] = true,
  ["make"] = true,
  ["new"] = true,
  ["panic"] = true,
  ["print"] = true,
  ["println"] = true,
  ["real"] = true,
  ["recover"] = true,
  ["any"] = true,
  ["error"] = true,
  ["nil"] = true,
  ["true"] = true,
  ["false"] = true,
  ["iota"] = true,
  -- predeclared types
  ["string"] = true,
  ["bool"] = true,
  ["int"] = true,
  ["int8"] = true,
  ["int16"] = true,
  ["int32"] = true,
  ["int64"] = true,
  ["uint"] = true,
  ["uint8"] = true,
  ["uint16"] = true,
  ["uint32"] = true,
  ["uint64"] = true,
  ["uintptr"] = true,
  ["byte"] = true,
  ["rune"] = true,
  ["float32"] = true,
  ["float64"] = true,
  ["complex64"] = true,
  ["complex128"] = true,
}

local function word_at(line_text, col)
  local pos = 1
  while true do
    local s, e = line_text:find("[%a_][%w_]*", pos)
    if not s then break end
    if col >= s - 1 and col <= e - 1 then
      return line_text:sub(s, e)
    end
    if s - 1 > col then break end
    pos = e + 1
  end
end

-- ── Godoc formatting ──────────────────────────────────────────────────────────

-- gopls returns hover as:
--   ```go
--   func Foo(x int) error
--   ```
--   Foo does something useful.
--
--   Parameters:
--     - x: the value
--
-- The signature part is handled by util.split_fence / util.to_lines.
-- This function formats the prose doc section (everything after the fence).
--
-- gopls doc sections we recognise:
--   "Parameters:\n  - name: desc"  (gopls >= 0.14 structured docs)
--   "@param name desc"              (rare, some older setups)
--   Plain prose paragraphs
--
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  local lines = vim.split(raw, "\n", { plain = true })

  -- Strip leading blank lines.
  while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
  -- Strip trailing blank lines.
  while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end

  if #lines == 0 then return nil end

  -- Fast path: if no structured section markers exist, return plain prose.
  local joined             = table.concat(lines, "\n")
  local has_params_section = joined:match("\nParameters:") or joined:match("^Parameters:")
  local has_at_param       = joined:match("@param%s+%S")
  local has_at_return      = joined:match("@returns?%s+")

  if not has_params_section and not has_at_param and not has_at_return then
    return lines
  end

  -- Parse structured sections.
  -- gopls structured format:
  --   Parameters:
  --     - name: description
  --     - name: description
  --   Returns:
  --     - description
  --   Deprecated: reason
  --
  -- We collect: desc[], params[], ret[], deprecated string
  local desc         = {}
  local params       = {}
  local ret_lines    = {}
  local deprecated   = nil

  local STATE_DESC   = "desc"
  local STATE_PARAMS = "params"
  local STATE_RET    = "ret"
  local state        = STATE_DESC

  for _, line in ipairs(lines) do
    -- Section headers
    if line:match("^Parameters:%s*$") then
      state = STATE_PARAMS
    elseif line:match("^Returns?:%s*$") then
      state = STATE_RET
    elseif line:match("^Deprecated:%s*(.+)") then
      deprecated = line:match("^Deprecated:%s*(.+)")
      state = STATE_DESC -- treat subsequent lines as desc again
      -- gopls structured param line: "  - name: description"
    elseif state == STATE_PARAMS and line:match("^%s*%-%s*(%S+):%s*(.*)") then
      local pname, pdesc = line:match("^%s*%-%s*(%S+):%s*(.*)")
      table.insert(params, { name = pname, desc = pdesc or "" })
      -- gopls structured return line: "  - description"
    elseif state == STATE_RET and line:match("^%s*%-%s*(.+)") then
      table.insert(ret_lines, line:match("^%s*%-%s*(.+)"))
      -- @param fallback (older gopls / hand-written)
    elseif line:match("^@param%s+(%S+)%s*(.*)") then
      local pname, pdesc = line:match("^@param%s+(%S+)%s*(.*)")
      state = STATE_PARAMS
      table.insert(params, { name = pname, desc = pdesc or "" })
    elseif line:match("^@returns?%s+(.*)") then
      state = STATE_RET
      table.insert(ret_lines, line:match("^@returns?%s+(.*)"))
      -- description accumulator
    elseif state == STATE_DESC then
      table.insert(desc, line)
    end
  end

  -- Strip blank lines from the description tail.
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

  if #ret_lines > 0 then
    if #out > 0 then table.insert(out, "") end
    if #ret_lines == 1 then
      table.insert(out, "**Returns** — " .. ret_lines[1])
    else
      table.insert(out, "**Returns**")
      for _, r in ipairs(ret_lines) do table.insert(out, "- " .. r) end
    end
  end

  if deprecated then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Deprecated:** " .. deprecated)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

-- When gopls hover returns nothing for a non-keyword position, scan ahead on the
-- same line for the first non-keyword identifier after the cursor and retry.
-- Mirrors java.lua's retry_at_symbol.
---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function retry_at_symbol(bufnr, params, cb)
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""

  local new_col
  local pos       = 1
  while true do
    local s, e = line_text:find("[%a_][%w_]*", pos)
    if not s then break end
    local word_col = s - 1 -- convert to 0-based
    if word_col > col and not GO_KEYWORDS[line_text:sub(s, e)] then
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
  util.std_request(bufnr, "gopls", "textDocument/hover", new_params, function(result)
    if not result then
      cb(nil, nil)
      return
    end
    local raw       = util.extract_value(result.contents)
    local sig, doc  = util.split_fence(raw)
    local sig_lines = sig ~= "" and util.to_lines(sig) or nil
    local doc_lines = format_docs(doc)
    cb(sig_lines, doc_lines)
  end)
end

---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, cb)
  util.std_request(bufnr, "gopls", "textDocument/hover", params, function(result)
    if not result then
      -- Nothing returned — cursor may be between tokens.  Try the next symbol.
      retry_at_symbol(bufnr, params, cb)
      return
    end

    local raw = util.extract_value(result.contents)
    if raw == "" then
      retry_at_symbol(bufnr, params, cb)
      return
    end

    local sig, doc = util.split_fence(raw)
    local sig_lines = sig ~= "" and util.to_lines(sig) or nil
    local doc_lines = format_docs(doc)

    if sig_lines then
      cb(sig_lines, doc_lines)
    else
      retry_at_symbol(bufnr, params, cb)
    end
  end)
end

-- Resolve a display label from a gopls implementation location.
-- Tries to extract the type name from the target symbol if available,
-- falling back to file:line.
---@param loc table  LSP Location or LocationLink
---@return string
local function loc_display(loc)
  local uri   = loc.uri or loc.targetUri or ""
  local base  = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t:r")
  local range = loc.range or loc.targetSelectionRange or { start = { line = 0 } }
  local line  = range.start.line

  -- If the file is open, read the identifier at the target position directly.
  local fname = vim.uri_to_fname(uri)
  local buf   = vim.fn.bufnr(fname)
  if buf ~= -1 then
    local target_line = vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]
    if target_line then
      local col   = range.start.character or 0
      local ident = word_at(target_line, col)
      if ident and ident ~= "" then
        return ident .. "  `" .. base .. "`"
      end
    end
  end

  return base ~= "" and (base .. ":" .. (line + 1)) or "?"
end

---@param bufnr integer
---@param params table
---@param cb fun(impls: string[])
local function fetch_implementations(bufnr, params, cb)
  util.std_request(bufnr, "gopls", "textDocument/implementation", params, function(result)
    if not result then
      cb({})
      return
    end
    local seen, names = {}, {}
    for _, loc in ipairs(vim.islist(result) and result or { result }) do
      local label = loc_display(loc)
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

-- Fetch supertypes and subtypes via a single prepareTypeHierarchy call.
-- Both on_super and on_subs are guaranteed to be called exactly once each,
-- which is required for correct barrier accounting in enrich().
-- gopls supports typeHierarchy since gopls 0.11 / Go 1.21.
---@param bufnr integer
---@param params table
---@param cfg table
---@param on_super fun(extends: string[])
---@param on_subs  fun(types: string[])
local function fetch_hierarchy(bufnr, params, cfg, on_super, on_subs)
  local want_super = cfg.sections.hierarchy
  local want_subs  = cfg.sections.implementations

  if not want_super and not want_subs then
    on_super({})
    on_subs({})
    return
  end

  util.std_request(bufnr, "gopls", "textDocument/prepareTypeHierarchy", params, function(items)
    if not items or #items == 0 then
      on_super({})
      on_subs({})
      return
    end

    local item = items[1]

    -- Both supertypes and subtypes run concurrently after prepare.
    -- Each callback is always called exactly once — callers depend on this.
    if want_super then
      util.client_request(bufnr, "gopls", "typeHierarchy/supertypes",
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
      util.client_request(bufnr, "gopls", "typeHierarchy/subtypes",
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

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params    = util.pos_params(bufnr)
  local cfg       = require("linus").config

  -- Keyword fast-path: skip all LSP work, let providers/main.lua serve the
  -- built-in keyword reference.  Must happen before any request fires because
  -- gopls can return hover for some keywords (e.g. built-in types), which
  -- would compete with the keyword table lookup.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if GO_KEYWORDS[word_at(line_text, col)] then
    done({})
    return
  end

  -- Four concurrent async slots:
  --   1. hover (fetch_hover — may internally retry)
  --   2. hierarchy supertypes  ┐ both resolved inside fetch_hierarchy,
  --   3. hierarchy subtypes    ┘ each calls tick() exactly once
  --   4. textDocument/implementation
  --
  -- fetch_hierarchy issues two client_request calls (super + subs) but we
  -- wrap their combined result into two separate tick() calls so the barrier
  -- always reaches 4 exactly once, regardless of want_super / want_subs.
  local data = {}
  local tick = util.barrier(4, function() done(data) end)

  -- ── Slot 1: hover ─────────────────────────────────────────────────────────
  fetch_hover(bufnr, params, function(sig_lines, doc_lines)
    if sig_lines then data.signature = sig_lines end
    if doc_lines then data.docs = doc_lines end
    tick()
  end)

  -- ── Slots 2 & 3: type hierarchy ───────────────────────────────────────────
  fetch_hierarchy(bufnr, params, cfg,
    function(supers)
      if #supers > 0 then data.hierarchy = supers end
      tick() -- slot 2
    end,
    function(subs)
      if #subs > 0 then
        data.implementations = data.implementations or {}
        vim.list_extend(data.implementations, subs)
      end
      tick() -- slot 3
    end
  )

  -- ── Slot 4: interface implementations ─────────────────────────────────────
  if cfg.sections.implementations then
    fetch_implementations(bufnr, params, function(impls)
      if #impls > 0 then
        data.implementations = data.implementations or {}
        -- merge without duplicates
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
end

return M
