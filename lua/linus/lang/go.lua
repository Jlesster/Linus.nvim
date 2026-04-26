-- linus/lang/go.lua
-- gopls enricher: hover + interface implementations.
-- gopls returns rich, well-structured markdown natively, so no doc reformatting needed.

local util = require("linus.lang.util")

local M = {}

-- Resolve a short display label from a gopls implementation location.
---@param loc table  LSP Location or LocationLink
---@return string
local function loc_display(loc)
  local uri  = loc.uri or loc.targetUri or ""
  local base = vim.fn.fnamemodify(vim.uri_to_fname(uri), ":t:r")
  local line = (loc.range or loc.targetSelectionRange or { start = { line = 0 } }).start.line
  return base ~= "" and (base .. ":" .. (line + 1)) or "?"
end

---@param bufnr integer
---@param params table
---@param cb fun(impls: string[])
local function fetch_implementations(bufnr, params, cb)
  util.std_request(bufnr, "gopls", "textDocument/implementation", params, function(result)
    if not result then cb({}) return end
    local seen  = {}
    local names = {}
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

---@param bufnr integer
---@param opts table
---@param done fun(data: table)
function M.enrich(bufnr, opts, done)
  local params = util.pos_params(bufnr)
  local cfg    = require("linus").config
  local data   = {}
  local tick   = util.barrier(2, function() done(data) end)

  util.std_request(bufnr, "gopls", "textDocument/hover", params, function(result)
    if result then
      local raw      = util.extract_value(result.contents)
      local sig, doc = util.split_fence(raw)
      if sig ~= "" then data.signature = util.to_lines(sig) end
      if doc ~= "" then data.docs      = util.to_lines(doc) end
    end
    tick()
  end)

  if cfg.sections.implementations then
    fetch_implementations(bufnr, params, function(impls)
      if #impls > 0 then data.implementations = impls end
      tick()
    end)
  else
    tick()
  end
end

return M
