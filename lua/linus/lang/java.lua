-- linus/lang/java.lua
-- jdtls enricher: hover with javadoc, type hierarchy, and known subtypes.

local util = require("linus.lang.util")

local M = {}

-- ── Hover parsing ─────────────────────────────────────────────────────────────

-- jdtls hover markdown: everything inside the first code fence is the
-- signature; everything after the closing fence is the javadoc.
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

-- ── Keyword detection ──────────────────────────────────────────────────────────

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

-- Return the identifier whose character span contains col (0-indexed).
-- Works from anywhere inside the word, not just the first character.
local function word_containing(line_text, col)
  local pos = 1
  while true do
    local s, e = line_text:find("[%a_$][%w_$]*", pos)
    if not s then break end
    if col >= s - 1 and col <= e - 1 then  -- col is 0-based; s/e are 1-based
      return line_text:sub(s, e)
    end
    if s - 1 > col then break end
    pos = e + 1
  end
end

-- ── LSP fetchers ───────────────────────────────────────────────────────────────

-- Parse any jdtls hover result shape into (sig_lines, doc_lines).
-- jdtls can return three distinct content formats:
--   MarkupContent  {kind="markdown", value="```java\n...\n```\ndocs"}
--   MarkedString   "" (empty for keyword positions)
--   MarkedString[] [{language="java", value="FQN"}, "Source: ..."]
---@param result table|nil
---@return string[]|nil, string[]|nil
local function parse_hover_result(result)
  if not result then return nil, nil end
  local contents = result.contents
  if not contents then return nil, nil end

  if type(contents) == "table" and contents.kind then
    -- MarkupContent
    local raw = contents.value or ""
    if raw == "" then return nil, nil end
    local sig_text, docs_text = split_sig_docs(raw)
    return sig_text ~= "" and util.to_lines(sig_text) or nil, format_docs(docs_text)
  end

  if type(contents) == "string" then
    -- MarkedString scalar
    if contents == "" then return nil, nil end
    local sig_text, docs_text = split_sig_docs(contents)
    return sig_text ~= "" and util.to_lines(sig_text) or nil, format_docs(docs_text)
  end

  if type(contents) == "table" then
    -- MarkedString[] — wrap each code object in a language fence
    local sig_lines = {}
    local doc_parts = {}
    for _, item in ipairs(contents) do
      if type(item) == "table" and item.value and item.value ~= "" then
        table.insert(sig_lines, "```" .. (item.language or "java"))
        for _, l in ipairs(vim.split(item.value, "\n", { plain = true })) do
          table.insert(sig_lines, l)
        end
        table.insert(sig_lines, "```")
      elseif type(item) == "string" and item ~= "" then
        table.insert(doc_parts, item)
      end
    end
    while #sig_lines > 0 and sig_lines[#sig_lines]:match("^%s*$") do table.remove(sig_lines) end
    local doc_lines = #doc_parts > 0 and format_docs(table.concat(doc_parts, "\n")) or nil
    return #sig_lines > 0 and sig_lines or nil, doc_lines
  end

  return nil, nil
end

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
    cb(parse_hover_result(result))
  end)
end

---@param bufnr integer
---@param params table
---@param cb fun(sig: string[]|nil, docs: string[]|nil)
local function fetch_hover(bufnr, params, cb)
  util.std_request(bufnr, "jdtls", "textDocument/hover", params, function(result)
    local sig_lines, doc_lines = parse_hover_result(result)
    if sig_lines then
      cb(sig_lines, doc_lines)
      return
    end

    -- If hover returned nothing because the cursor is on a keyword, bail out
    -- cleanly so main.lua can serve the built-in keyword reference.
    local col       = params.position.character
    local line_nr   = params.position.line
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
    if JAVA_KEYWORDS[word_containing(line_text, col)] then
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

  -- Fast-path for keywords: skip all LSP work and let main.lua serve the
  -- built-in reference. Must happen before any request fires, because
  -- prepareTypeHierarchy can return "Extends Object" even for keyword positions,
  -- which would make data non-empty and bypass the keyword lookup.
  local line_nr   = params.position.line
  local col       = params.position.character
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1] or ""
  if JAVA_KEYWORDS[word_containing(line_text, col)] then
    done({})
    return
  end

  -- Three async results: hover, supertypes, subtypes.
  local data = {}
  local tick = util.barrier(3, function() done(data) end)

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
end

return M
