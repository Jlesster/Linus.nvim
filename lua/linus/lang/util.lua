-- linus/lang/util.lua
-- Shared LSP helpers used by all language enrichers.

local M = {}

local function dbg(msg)
  local ok, linus = pcall(require, "linus")
  if ok and linus.config and linus.config.debug then
    vim.notify("[linus] " .. msg, vim.log.levels.WARN)
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
    local ok, linus = pcall(require, "linus")
    if ok and linus.config and linus.config.debug then
      local summary = {}
      for client_id, res in pairs(results) do
        local c   = vim.lsp.get_client_by_id(client_id)
        local tag = res.result ~= nil and "ok" or (res.error and "err" or "nil")
        table.insert(summary, (c and c.name or "id=" .. tostring(client_id)) .. "=" .. tag)
      end
      vim.notify("[linus] " .. method .. " → [" .. table.concat(summary, ", ") .. "]", vim.log.levels.WARN)
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
  local client  = clients[1]
  if not client then
    dbg(method .. ": no client named " .. client_name)
    cb(nil)
    return
  end
  local ok = client:request(method, params, function(err, result)
    if err then cb(nil) else cb(result) end
  end, bufnr)
  if not ok then
    dbg(method .. ": client:request() returned false")
    cb(nil)
  end
end

-- Build standard position params for the current cursor position.
---@param bufnr integer
---@return table
function M.pos_params(bufnr)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then win = 0 end
  local clients  = vim.lsp.get_clients({ bufnr = bufnr })
  local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
  return vim.lsp.util.make_position_params(win, encoding)
end

-- Extract plain text from any LSP hover content shape:
-- MarkupContent {kind, value}, MarkedString scalar, or MarkedString[].
---@param contents any
---@return string
function M.extract_value(contents)
  if not contents then return "" end
  if type(contents) == "string" then return contents end
  if type(contents) == "table" then
    if contents.kind then return contents.value or "" end  -- MarkupContent
    local parts = {}
    for _, item in ipairs(contents) do
      if type(item) == "string" then
        table.insert(parts, item)
      elseif type(item) == "table" and item.value then
        table.insert(parts, item.value)
      end
    end
    return table.concat(parts, "\n")
  end
  return ""
end

-- Split hover markdown at the first closing code fence, returning
-- (signature_text, docs_text). Used by go.lua and c.lua.
---@param text string
---@return string sig, string docs
function M.split_fence(text)
  if not text or text == "" then return "", "" end
  local lines    = vim.split(text, "\n", { plain = true })
  local sig      = {}
  local docs     = {}
  local in_fence = false
  local done_sig = false
  for _, line in ipairs(lines) do
    if not done_sig then
      if line:match("^```") then
        in_fence = not in_fence
        table.insert(sig, line)
        if not in_fence then done_sig = true end
      else
        table.insert(sig, line)
      end
    else
      table.insert(docs, line)
    end
  end
  return table.concat(sig, "\n"), table.concat(docs, "\n")
end

-- Split text into lines, stripping leading and trailing blank lines.
---@param text string
---@return string[]
function M.to_lines(text)
  if not text or text == "" then return {} end
  local lines = vim.split(text, "\n", { plain = true })
  while #lines > 0 and lines[1]:match("^%s*$") do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end
  return lines
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
    if count >= n then done() end
  end
end

return M
