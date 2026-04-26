-- linus/keywords/init.lua
-- Built-in keyword reference tables with user override support.

local M = {}

local _tables = {
  java = require("linus.keywords.java"),
  go   = require("linus.keywords.go"),
  c    = require("linus.keywords.c"),
  cpp  = require("linus.keywords.cpp"),
}

-- Look up a word in the keyword reference table for a language.
-- Returns a string[] ready for the renderer, or nil if not found.
---@param lang string
---@param word string
---@return string[]|nil
function M.lookup(lang, word)
  local tbl = _tables[lang]
  if not tbl then return nil end
  local entry = tbl[word] or tbl[word:lower()]
  if not entry then return nil end
  -- String entries are split once and the result cached back in the table.
  if type(entry) == "string" then
    local lines = vim.split(entry, "\n", { plain = true })
    tbl[word] = lines
    return lines
  end
  return entry
end

-- Merge user-supplied overrides into the built-in tables.
-- overrides = { java = { myword = "markdown text" }, go = { … } }
---@param overrides table
function M.merge_overrides(overrides)
  for lang, words in pairs(overrides) do
    if _tables[lang] then
      for word, desc in pairs(words) do
        _tables[lang][word] = desc
      end
    else
      _tables[lang] = words
    end
  end
end

return M
