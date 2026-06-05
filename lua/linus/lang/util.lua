-- linus/lang/util.lua
-- Shared LSP helpers used by all language enrichers.

local M = {}

local function dbg(msg)
  local ok, linus = pcall(require, 'linus')
  if ok and linus.config and linus.config.debug then
    vim.notify('[linus] ' .. msg, vim.log.levels.WARN)
  end
end

-- Send a standard LSP request via buf_request_all, filtered to one named client.
-- buf_request_all fires its callback exactly once regardless of how many clients
-- are attached, avoiding the double-tick bug that buf_request causes with barriers.
-- Use for methods advertised in serverCapabilities (hover, prepareTypeHierarchy…).
---@param bufnr integer
---@param client_name string
---@param method string
---@param params table
---@param cb fun(result: any)
function M.std_request(bufnr, client_name, method, params, cb)
  vim.lsp.buf_request_all(bufnr, method, params, function(results)
    -- Build the summary string only when debug logging is on; the table
    -- allocation is non-trivial and happens on every hover otherwise.
    local ok, linus = pcall(require, 'linus')
    if ok and linus.config and linus.config.debug then
      local summary = {}
      for client_id, res in pairs(results) do
        local c = vim.lsp.get_client_by_id(client_id)
        local tag = res.result ~= nil and 'ok' or (res.error and 'err' or 'nil')
        table.insert(
          summary,
          (c and c.name or 'id=' .. tostring(client_id)) .. '=' .. tag
        )
      end
      vim.notify(
        '[linus] ' .. method .. ' → [' .. table.concat(summary, ', ') .. ']',
        vim.log.levels.WARN
      )
    end

    for client_id, res in pairs(results) do
      local c = vim.lsp.get_client_by_id(client_id)
      if c and c.name == client_name then
        cb(not res.error and res.result or nil)
        return
      end
    end
    cb(nil)
  end)
end

-- Send a request directly via client:request(), bypassing Neovim's capability
-- check. Required for follow-up methods not declared in serverCapabilities:
-- typeHierarchy/supertypes, typeHierarchy/subtypes.
---@param bufnr integer
---@param client_name string
---@param method string
---@param params table
---@param cb fun(result: any)
function M.client_request(bufnr, client_name, method, params, cb)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = client_name })
  local client = clients[1]
  if not client then
    dbg(method .. ': no client named ' .. client_name)
    cb(nil)
    return
  end
  local ok = client:request(method, params, function(err, result)
    if err then
      cb(nil)
    else
      cb(result)
    end
  end, bufnr)
  if not ok then
    dbg(method .. ': client:request() returned false')
    cb(nil)
  end
end

-- Build standard position params for the current cursor position.
---@param bufnr integer
---@return table
function M.pos_params(bufnr)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    win = 0
  end
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local encoding = clients[1] and clients[1].offset_encoding or 'utf-16'
  return vim.lsp.util.make_position_params(win, encoding)
end

-- Extract plain text from any LSP hover content shape:
-- MarkupContent {kind, value}, MarkedString scalar, or MarkedString[].
---@param contents any
---@return string
function M.extract_value(contents)
  if not contents then
    return ''
  end
  if type(contents) == 'string' then
    return contents
  end
  if type(contents) == 'table' then
    if contents.kind then
      return contents.value or ''
    end -- MarkupContent
    local parts = {}
    for _, item in ipairs(contents) do
      if type(item) == 'string' then
        table.insert(parts, item)
      elseif type(item) == 'table' and item.value then
        table.insert(parts, item.value)
      end
    end
    return table.concat(parts, '\n')
  end
  return ''
end

-- Return the identifier whose character span contains col (0-indexed).
---@param line_text string
---@param col integer
---@param pattern string
---@return string|nil
function M.word_containing(line_text, col, pattern)
  pattern = pattern or '[%a_%][%w_]*'
  local pos = 1
  while true do
    local s, e = line_text:find(pattern, pos)
    if not s then
      return nil
    end
    if col >= s - 1 and col <= e - 1 then
      return line_text:sub(s, e)
    end
    if s - 1 > col then
      return nil
    end
    pos = e + 1
  end
end

-- Split hover markdown at the first closing code fence, returning
-- (signature_text, docs_text).
---@param text string
---@return string sig, string docs
function M.split_sig_docs(text)
  if not text or text == '' then
    return '', ''
  end

  local lines = vim.split(text, '\n', { plain = true })

  -- Detect heading-style hover (no code fence): clangd sends
  -- "### TypeName" as the signature line instead of a fenced block.
  if lines[1] and lines[1]:match('^###%s') then
    -- First non-blank line after the heading block is the sig.
    -- Everything from the first doxygen tag onward is docs.
    local sig_parts = {}
    local doc_parts = {}
    local in_docs = false
    for _, line in ipairs(lines) do
      if
        not in_docs
        and (
          line:match('^%s*[@\\]brief')
          or line:match('^%s*[@\\]param')
          or line:match('^%s*[@\\]tparam')
          or line:match('^%s*[@\\]return')
          or line:match('^%s*[@\\]note')
          or line:match('^%s*[@\\]warning')
          or line:match('^%s*[@\\]throws?')
          or line:match('^%s*[@\\]exception')
          or line:match('^%s*[@\\]deprecated')
        )
      then
        in_docs = true
      end
      if in_docs then
        table.insert(doc_parts, line)
      else
        table.insert(sig_parts, line)
      end
    end
    return table.concat(sig_parts, '\n'), table.concat(doc_parts, '\n')
  end

  -- Standard fenced block handling.
  local sig_parts = {}
  local doc_parts = {}
  local in_fence = false
  local past_fence = false

  for _, line in ipairs(lines) do
    if line:match('^```') then
      in_fence = not in_fence
      if not in_fence then
        past_fence = true
      end
      table.insert(sig_parts, line)
    elseif in_fence then
      table.insert(sig_parts, line)
    elseif past_fence then
      table.insert(doc_parts, line)
    else
      table.insert(sig_parts, line)
    end
  end

  if not past_fence then
    return '', text
  end

  return table.concat(sig_parts, '\n'), table.concat(doc_parts, '\n')
end

-- Split text into lines, stripping leading and trailing blank lines.
---@param text string
---@return string[]
function M.to_lines(text)
  if not text or text == '' then
    return {}
  end
  local lines = vim.split(text, '\n', { plain = true })
  while #lines > 0 and lines[1]:match('^%s*$') do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match('^%s*$') do
    table.remove(lines)
  end
  return lines
end

-- Parse any LSP hover result shape into (sig_lines, doc_lines).
-- This generic handler supports MarkupContent, MarkedString scalars, and MarkedString arrays.
---@param result table|nil
---@param ft string
---@param format_docs_fn fun(string): string[]|nil
---@return string[]|nil sig_lines, string[]|nil doc_lines
function M.parse_hover_result(result, ft, format_docs_fn)
  if not result then
    return nil, nil
  end
  local contents = result.contents
  if not contents then
    return nil, nil
  end

  if type(contents) == 'table' and contents.kind then
    local raw = contents.value or ''
    if raw == '' then
      return nil, nil
    end
    local sig_text, docs_text = M.split_sig_docs(raw)
    -- Convert "### Foo" heading sig to a plain line for consistency
    if sig_text:match('^###%s') then
      sig_text = sig_text:gsub('^###%s+', '')
    end
    return sig_text ~= '' and M.to_lines(sig_text) or nil,
      format_docs_fn(docs_text)
  end

  if type(contents) == 'string' then
    -- MarkedString scalar
    if contents == '' then
      return nil, nil
    end
    local sig_text, docs_text = M.split_sig_docs(contents)
    return sig_text ~= '' and M.to_lines(sig_text) or nil,
      format_docs_fn(docs_text)
  end

  if type(contents) == 'table' then
    -- MarkedString[]
    local sig_lines = {}
    local doc_parts = {}
    for _, item in ipairs(contents) do
      if type(item) == 'table' and item.value and item.value ~= '' then
        table.insert(sig_lines, '```' .. (item.language or ft or 'text'))
        for _, l in ipairs(vim.split(item.value, '\n', { plain = true })) do
          table.insert(sig_lines, l)
        end
        table.insert(sig_lines, '```')
      elseif type(item) == 'string' and item ~= '' then
        table.insert(doc_parts, item)
      end
    end
    while #sig_lines > 0 and sig_lines[#sig_lines]:match('^%s*$') do
      table.remove(sig_lines)
    end
    local doc_lines = #doc_parts > 0
        and format_docs_fn(table.concat(doc_parts, '\n'))
      or nil
    return #sig_lines > 0 and sig_lines or nil, doc_lines
  end

  return nil, nil
end

-- Create a countdown barrier: returns a tick() function that calls done()
-- after it has been called n times.
---@param n integer
---@param done fun()
---@return fun() tick
function M.barrier(n, done)
  local count = 0
  return function()
    count = count + 1
    if count >= n then
      done()
    end
  end
end

return M
