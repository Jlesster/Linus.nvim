-- linus/lang/go.lua
-- gopls enricher: hover with godoc formatting, type hierarchy, interface implementations.
--
-- Hover parsing mirrors lang/java.lua exactly:
--   parse_hover_result() handles all three LSP content shapes gopls may return
--   (MarkupContent, MarkedString scalar, MarkedString[]), routes each through
--   split_sig_docs() + format_docs(), and returns (sig_lines, doc_lines).
--   fetch_hover() distinguishes "empty because keyword" from "empty because no
--   symbol here" and only retries (retry_at_symbol) for the latter — same
--   logic as jdtls in java.lua.

local util = require("linus.lang.util")

local M = {}

-- ── Keyword fast-path ─────────────────────────────────────────────────────────

local GO_KEYWORDS = {
  -- language keywords
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
  -- built-in identifiers — gopls returns nothing useful for these
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

-- Return the identifier whose character span contains col (0-indexed).
-- Identical to word_containing() in java.lua.
local function word_containing(line_text, col)
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

-- ── Hover parsing ─────────────────────────────────────────────────────────────

-- gopls hover markdown: everything inside the first code fence is the
-- signature; everything after the closing fence is the godoc comment.
-- Identical structure to split_sig_docs() in java.lua.
---@param text string
---@return string sig_text, string docs_text
local function split_sig_docs(text)
  if not text or text == "" then return "", "" end

  local sig_parts  = {}
  local doc_parts  = {}
  local in_fence   = false
  local past_fence = false

  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    if line:match("^```") then
      in_fence = not in_fence
      if not in_fence then past_fence = true end
      table.insert(sig_parts, line)
    elseif in_fence then
      table.insert(sig_parts, line)
    elseif past_fence then
      table.insert(doc_parts, line)
    else
      table.insert(sig_parts, line)
    end
  end

  return table.concat(sig_parts, "\n"), table.concat(doc_parts, "\n")
end

-- Turn raw godoc text into clean markdown lines.
-- Mirrors the structure of format_docs() in java.lua.
--
-- gopls emits two doc formats depending on version and symbol type:
--   Modern (≥0.14):  "Parameters:\n  - name: desc\nReturns:\n  - desc"
--   Legacy / manual: "@param name desc\n@returns desc"
--   Plain prose:     no markers — returned as-is
---@param raw string
---@return string[]|nil
local function format_docs(raw)
  if not raw or raw:match("^%s*$") then return nil end

  local lines = vim.split(raw, "\n", { plain = true })

  while #lines > 0 and lines[1]:match("^%s*$") do table.remove(lines, 1) end
  while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
  if #lines == 0 then return nil end

  local joined     = table.concat(lines, "\n")

  local has_modern = joined:match("\nParameters:") or joined:match("^Parameters:")
      or joined:match("\nReturns?:") or joined:match("^Returns?:")
  local has_legacy = joined:match("@param%s") or joined:match("@returns?%s")
  local has_depr   = joined:match("\nDeprecated:") or joined:match("^Deprecated:")

  -- Fast path: plain prose.
  if not has_modern and not has_legacy and not has_depr then
    return lines
  end

  local desc         = {}
  local params       = {} -- { name=string, desc=string }
  local ret_lines    = {}
  local deprecated   = nil

  local STATE_DESC   = 1
  local STATE_PARAMS = 2
  local STATE_RET    = 3
  local state        = STATE_DESC

  for _, line in ipairs(lines) do
    -- Section headers
    if line:match("^Parameters:%s*$") then
      state = STATE_PARAMS
    elseif line:match("^Returns?:%s*$") then
      state = STATE_RET
    elseif line:match("^Deprecated:%s*$") then
      deprecated = ""
      state = STATE_DESC

      -- Inline "Deprecated: reason" (single-line form)
    elseif line:match("^Deprecated:%s*(.+)") then
      deprecated = line:match("^Deprecated:%s*(.+)")
      state = STATE_DESC

      -- Modern param line: "  - name: description"
    elseif state == STATE_PARAMS and line:match("^%s*%-%s*(%S+):%s*(.*)") then
      local pname, pdesc = line:match("^%s*%-%s*(%S+):%s*(.*)")
      table.insert(params, { name = pname, desc = pdesc or "" })

      -- Modern return line: "  - description"
    elseif state == STATE_RET and line:match("^%s*%-%s*(.+)") then
      table.insert(ret_lines, line:match("^%s*%-%s*(.+)"))

      -- Legacy @param
    elseif line:match("^@param%s+(%S+)%s*(.*)") then
      local pname, pdesc = line:match("^@param%s+(%S+)%s*(.*)")
      state = STATE_PARAMS
      table.insert(params, { name = pname, desc = pdesc or "" })

      -- Legacy @return / @returns
    elseif line:match("^@returns?%s+(.*)") then
      state = STATE_RET
      table.insert(ret_lines, line:match("^@returns?%s+(.*)"))

      -- Description accumulator
    elseif state == STATE_DESC then
      if deprecated == "" and not line:match("^%s*$") then
        deprecated = line -- first non-blank after bare "Deprecated:"
      elseif deprecated == nil then
        table.insert(desc, line)
      end

      -- Continuation: indented line extends last param or return entry
    elseif state == STATE_PARAMS and line:match("^%s+") and #params > 0 then
      params[#params].desc = params[#params].desc
          .. " " .. line:match("^%s+(.*)")
    elseif state == STATE_RET and line:match("^%s+") and #ret_lines > 0 then
      ret_lines[#ret_lines] = ret_lines[#ret_lines]
          .. " " .. line:match("^%s+(.*)")
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

  if #ret_lines > 0 then
    if #out > 0 then table.insert(out, "") end
    if #ret_lines == 1 then
      table.insert(out, "**Returns** — " .. ret_lines[1])
    else
      table.insert(out, "**Returns**")
      for _, r in ipairs(ret_lines) do table.insert(out, "- " .. r) end
    end
  end

  if deprecated and deprecated ~= "" then
    if #out > 0 then table.insert(out, "") end
    table.insert(out, "> **Deprecated:** " .. deprecated)
  end

  while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
  return #out > 0 and out or nil
end

-- ── LSP hover result parsing ───────────────────────────────────────────────────

-- Parse any gopls hover result shape into (sig_lines, doc_lines).
-- Mirrors parse_hover_result() in java.lua exactly, adapted for gopls:
--
--   MarkupContent  {kind="markdown", value="```go\nfunc...\n```\ngodoc"}
--   MarkedString   "func Foo(...)" (plain string — older gopls)
--   MarkedString[] [{language="go", value="func..."}, "godoc prose"]
---@param result table|nil
---@return string[]|nil sig_lines, string[]|nil doc_lines
local function parse_hover_result(result)
  if not result then return nil, nil end
  local contents = result.contents
  if not contents then return nil, nil end

  -- MarkupContent {kind, value}
  if type(contents) == "table" and contents.kind then
    local raw = contents.value or ""
    if raw == "" then return nil, nil end
    local sig_text, docs_text = split_sig_docs(raw)
    return sig_text ~= "" and util.to_lines(sig_text) or nil,
        format_docs(docs_text)
  end

  -- MarkedString scalar
  if type(contents) == "string" then
    if contents == "" then return nil, nil end
    local sig_text, docs_text = split_sig_docs(contents)
    return sig_text ~= "" and util.to_lines(sig_text) or nil,
        format_docs(docs_text)
  end

  -- MarkedString[] — wrap each code object in a language fence
  if type(contents) == "table" then
    local sig_lines = {}
    local doc_parts = {}
    for _, item in ipairs(contents) do
      if type(item) == "table" and item.value and item.value ~= "" then
        table.insert(sig_lines, "```" .. (item.language or "go"))
        for _, l in ipairs(vim.split(item.value, "\n", { plain = true })) do
          table.insert(sig_lines, l)
        end
        table.insert(sig_lines, "```")
      elseif type(item) == "string" and item ~= "" then
        table.insert(doc_parts, item)
      end
    end
    while #sig_lines > 0 and sig_lines[#sig_lines]:match("^%s*$") do
      table.remove(sig_lines)
    end
    local doc_lines = #doc_parts > 0
        and format_docs(table.concat(doc_parts, "\n"))
        or nil
    return #sig_lines > 0 and sig_lines or nil, doc_lines
  end

  return nil, nil
end

-- ── fetch_hover + retry ────────────────────────────────────────────────────────

-- When hover returns nothing for a non-keyword position, scan ahead on the
-- same line for the first non-keyword identifier after the cursor and retry.
-- Mirrors retry_at_symbol() in java.lua exactly.
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
    local word_col = s - 1 -- 0-based
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
    cb(parse_hover_result(result))
  end)
end

-- Fetch hover from gopls and route through parse_hover_result().
-- Distinguishes three outcomes:
--   got sig  → cb(sig_lines, doc_lines)
--   keyword  → cb(nil, nil)  [let main.lua serve the keyword table]
--   no-symbol non-keyword → retry_at_symbol
-- Mirrors fetch_hover() in java.lua.
---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, cb)
  util.std_request(bufnr, "gopls", "textDocument/hover", params, function(result)
    local sig_lines, doc_lines = parse_hover_result(result)
    if sig_lines then
      cb(sig_lines, doc_lines)
      return
    end

    local col       = params.position.character
    local line_nr   = params.position.line
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
    if GO_KEYWORDS[word_containing(line_text, col)] then
      cb(nil, nil)
      return
    end

    retry_at_symbol(bufnr, params, cb)
  end)
end

-- ── Type hierarchy ─────────────────────────────────────────────────────────────

-- Resolve a display label from a gopls implementation location.
---@param loc table
---@return string
local function loc_display(loc)
  local uri   = loc.uri or loc.targetUri or ""
  local base  = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t:r")
  local range = loc.range or loc.targetSelectionRange or { start = { line = 0 } }
  local line  = range.start.line

  local fname = vim.uri_to_fname(uri)
  local buf   = vim.fn.bufnr(fname)
  if buf ~= -1 then
    local target_line = vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]
    if target_line then
      local col   = range.start.character or 0
      local ident = word_containing(target_line, col)
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

-- Run prepareTypeHierarchy once, fire supertypes and subtypes in parallel.
-- on_super and on_subs are each called exactly once — required for barrier.
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

  -- Fast-path for keywords: skip all LSP work and let main.lua serve the
  -- built-in reference.  Must happen before any request fires because gopls
  -- can return hover for built-in types, which would make data non-empty and
  -- bypass the keyword lookup.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if GO_KEYWORDS[word_containing(line_text, col)] then
    done({})
    return
  end

  -- Four async slots — barrier must be reached exactly 4 times:
  --   1. hover
  --   2. supertypes  ┐ both from fetch_hierarchy after one prepare call;
  --   3. subtypes    ┘ each calls tick() independently
  --   4. textDocument/implementation
  local data = {}
  local tick = util.barrier(4, function() done(data) end)

  -- Slot 1
  fetch_hover(bufnr, params, function(sig_lines, doc_lines)
    data.signature = sig_lines
    data.docs      = doc_lines
    tick()
  end)

  -- Slots 2 + 3
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
end

return M
