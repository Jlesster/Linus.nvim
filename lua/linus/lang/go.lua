-- linus/lang/go.lua
-- gopls enricher: hover, type hierarchy, interface implementations.

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

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

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
      local col = range.start.character or 0
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

-- Fetch supertypes and subtypes in parallel via a single prepareTypeHierarchy call.
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

    if want_super then
      util.client_request(bufnr, "gopls", "typeHierarchy/supertypes", { item = item, resolve = 3 }, function(result)
        if not result then
          on_super({})
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
      util.client_request(bufnr, "gopls", "typeHierarchy/subtypes", { item = item, resolve = 3 }, function(result)
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

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params    = util.pos_params(bufnr)
  local cfg       = require("linus").config

  -- Keyword fast-path.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if GO_KEYWORDS[word_at(line_text, col)] then
    done({})
    return
  end

  -- 4 concurrent results: hover, supertypes, subtypes, implementations.
  -- hierarchy/subtypes share one prepareTypeHierarchy call so they count as one async unit.
  -- implementations (textDocument/implementation) is separate.
  local data = {}
  local tick = util.barrier(3, function() done(data) end)

  util.std_request(bufnr, "gopls", "textDocument/hover", params, function(result)
    if result then
      local raw      = util.extract_value(result.contents)
      local sig, doc = util.split_fence(raw)
      if sig ~= "" then data.signature = util.to_lines(sig) end
      if doc ~= "" then data.docs = util.to_lines(doc) end
    end
    tick()
  end)

  fetch_hierarchy(bufnr, params, cfg,
    function(supers)
      if #supers > 0 then data.hierarchy = supers end
      -- subtypes merged into implementations bucket (same renderer slot)
    end,
    function(subs)
      if #subs > 0 then
        data.implementations = data.implementations or {}
        vim.list_extend(data.implementations, subs)
      end
      tick()
    end
  )

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
      tick()
    end)
  else
    tick()
  end
end

return M
