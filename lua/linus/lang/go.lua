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

local util = require('linus.lang.util')

local M = {}

-- ── Keyword fast-path ─────────────────────────────────────────────────────────

local GO_KEYWORDS = {
  -- language keywords
  ['break'] = true,
  ['case'] = true,
  ['chan'] = true,
  ['const'] = true,
  ['continue'] = true,
  ['default'] = true,
  ['defer'] = true,
  ['else'] = true,
  ['fallthrough'] = true,
  ['for'] = true,
  ['func'] = true,
  ['go'] = true,
  ['goto'] = true,
  ['if'] = true,
  ['import'] = true,
  ['interface'] = true,
  ['map'] = true,
  ['package'] = true,
  ['range'] = true,
  ['return'] = true,
  ['select'] = true,
  ['struct'] = true,
  ['switch'] = true,
  ['type'] = true,
  ['var'] = true,
  -- built-in identifiers — gopls returns nothing useful for these
  ['append'] = true,
  ['cap'] = true,
  ['close'] = true,
  ['complex'] = true,
  ['copy'] = true,
  ['delete'] = true,
  ['imag'] = true,
  ['len'] = true,
  ['make'] = true,
  ['new'] = true,
  ['panic'] = true,
  ['print'] = true,
  ['println'] = true,
  ['real'] = true,
  ['recover'] = true,
  ['any'] = true,
  ['error'] = true,
  ['nil'] = true,
  ['true'] = true,
  ['false'] = true,
  ['iota'] = true,
  -- predeclared types
  ['string'] = true,
  ['bool'] = true,
  ['int'] = true,
  ['int8'] = true,
  ['int16'] = true,
  ['int32'] = true,
  ['int64'] = true,
  ['uint'] = true,
  ['uint8'] = true,
  ['uint16'] = true,
  ['uint32'] = true,
  ['uint64'] = true,
  ['uintptr'] = true,
  ['byte'] = true,
  ['rune'] = true,
  ['float32'] = true,
  ['float64'] = true,
  ['complex64'] = true,
  ['complex128'] = true,
}

-- ── Hover parsing ─────────────────────────────────────────────────────────────

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
  if not raw or raw:match('^%s*$') then
    return nil
  end

  local lines = {}
  for _, line in ipairs(vim.split(raw, '\n', { plain = true })) do
    table.insert(lines, (line:gsub('^%s*%*%s?', '')))
  end

  -- Strip trailing redundant signature block: "---\n```...\n```" that
  -- clangd appends after the doxygen text.
  local trimmed = {}
  local i = 1
  while i <= #lines do
    if
      lines[i]:match('^%-%-%-$')
      and lines[i + 1]
      and lines[i + 1]:match('^```')
    then
      break
    end
    table.insert(trimmed, lines[i])
    i = i + 1
  end
  lines = trimmed

  local desc = {}
  local extra = {} -- prose paragraphs that appear after tags
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
    line = line:gsub('\\<a href=[^>]+>(.-)\\</a>', '%1')
    line = line:gsub('<a [^>]+>(.-)</a>', '%1')
    line = line:gsub('%%([%a_][%w_:]*)', '`%1`')
    line = line:gsub('@c%s+(%S+)', '`%1`')
    line = line:gsub('@p%s+(%S+)', '`%1`')

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
        -- Unindented prose after tags: goes into extra section.
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
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function retry_at_symbol(bufnr, params, cb)
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
  util.std_request(
    bufnr,
    'gopls',
    'textDocument/hover',
    new_params,
    function(result)
      cb(util.parse_hover_result(result, 'go', format_docs))
    end
  )
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
  util.std_request(
    bufnr,
    'gopls',
    'textDocument/hover',
    params,
    function(result)
      local sig_lines, doc_lines = parse_hover_result(result)
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
      if GO_KEYWORDS[util.word_containing(line_text, col, '[%a_][%w_]*')] then
        cb(nil, nil)
        return
      end

      retry_at_symbol(bufnr, params, cb)
    end
  )
end

-- ── Type hierarchy ─────────────────────────────────────────────────────────────

-- Resolve a display label from a gopls implementation location.
---@param loc table
---@return string
local function loc_display(loc)
  local uri = loc.uri or loc.targetUri or ''
  local base = vim.fn.fnamemodify(vim.uri_to_fname(uri), ':t:r')
  local range = loc.range
    or loc.targetSelectionRange
    or { start = { line = 0 } }
  local line = range.start.line

  local fname = vim.uri_to_fname(uri)
  local buf = vim.fn.bufnr(fname)
  if buf ~= -1 then
    local target_line =
      vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]
    if target_line then
      local col = range.start.character or 0
      local ident = util.word_containing(target_line, col, '[%a_][%w_]*')
      if ident and ident ~= '' then
        return ident .. '  `' .. base .. '`'
      end
    end
  end

  return base ~= '' and (base .. ':' .. (line + 1)) or '?'
end

---@param bufnr integer
---@param params table
---@param cb fun(impls: string[])
local function fetch_implementations(bufnr, params, cb)
  util.std_request(
    bufnr,
    'gopls',
    'textDocument/implementation',
    params,
    function(result)
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

-- Run prepareTypeHierarchy once, fire supertypes and subtypes in parallel.
-- on_super and on_subs are each called exactly once — required for barrier.
---@param bufnr integer
---@param params table
---@param cfg table
---@param on_super fun(extends: string[])
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
    'gopls',
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
          'gopls',
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
          'gopls',
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

-- ── Entry point ────────────────────────────────────────────────────────────────

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params = util.pos_params(bufnr)
  local cfg = require('linus').config

  -- Fast-path for keywords: skip all LSP work and let main.lua serve the
  -- built-in reference.  Must happen before any request fires because gopls
  -- can return hover for built-in types, which would make data non-empty and
  -- bypass the keyword lookup.
  local line_nr = params.position.line
  local col = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(
    bufnr,
    line_nr,
    line_nr + 1,
    false
  )[1] or ''
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
  local tick = util.barrier(4, function()
    done(data)
  end)

  -- Slot 1
  fetch_hover(bufnr, params, function(sig_lines, doc_lines)
    data.signature = sig_lines
    data.docs = doc_lines
    tick()
  end)

  -- Slots 2 + 3
  fetch_hierarchy(bufnr, params, cfg, function(supers)
    if #supers > 0 then
      data.hierarchy = supers
    end
    tick() -- slot 2
  end, function(subs)
    if #subs > 0 then
      data.implementations = data.implementations or {}
      vim.list_extend(data.implementations, subs)
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
end

return M
