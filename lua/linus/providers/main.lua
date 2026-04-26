-- linus/providers/main.lua
-- hover.nvim provider (priority 1010 > built-in LSP at 1000).
-- Dispatches to the per-language enricher, then renders the result.

local renderer = require("linus.renderer")

local ft_to_lang = {
  java = "java",
  go   = "go",
  c    = "c",
  cpp  = "cpp",
}

local lang_clients = {
  java = { "jdtls" },
  go   = { "gopls" },
  c    = { "clangd" },
  cpp  = { "clangd" },
}

local function get_lang(bufnr)
  return ft_to_lang[vim.bo[bufnr].filetype]
end

local function has_client(bufnr, names)
  for _, name in ipairs(names) do
    if #vim.lsp.get_clients({ bufnr = bufnr, name = name }) > 0 then return true end
  end
  return false
end

local M = {}

M.name     = "Linus"
M.priority = 1010

M.enabled = function(bufnr)
  local lang = get_lang(bufnr)
  return lang ~= nil and has_client(bufnr, lang_clients[lang])
end

M.execute = function(opts, done)
  local bufnr = vim.api.nvim_get_current_buf()
  local lang  = get_lang(bufnr)
  if not lang then done(false) return end

  local cfg  = require("linus").config
  local word = cfg.sections.fallback and vim.fn.expand("<cword>") or nil

  require("linus.lang." .. lang).enrich(bufnr, opts, function(data)
    if not data or vim.tbl_isempty(data) then
      if word then
        local kw_lines = require("linus.keywords").lookup(lang, word)
        if kw_lines then
          done({ lines = kw_lines, filetype = "markdown" })
          return
        end
      end
      done(false)
      return
    end

    local lines = renderer.build(data, cfg)
    if #lines == 0 then done(false) return end

    renderer.stash(lines)
    done({ lines = lines, filetype = "markdown" })
  end)
end

return M
