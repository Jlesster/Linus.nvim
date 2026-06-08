-- linus/keywords/init.lua
-- Built-in keyword reference tables with user override support.

local M = {}

local function safe_require(mod)
  local ok, tbl = pcall(require, mod)
  if ok then return tbl end
  return nil
end

-- C/C++ fallback chain — checked in order after the main c/cpp table.
-- Add new library keyword files here to make them available for C/C++ hover.
local C_FALLBACK = {
  "posix",
  "ncurses",
  "sdl",
  "opengl",
  "vulkan",
  "raylib",
  "wayland",
  "gtk",
  "sqlite",
  "readline",
}

local _tables = {
  java  = safe_require("linus.keywords.java"),
  go    = safe_require("linus.keywords.go"),
  c     = safe_require("linus.keywords.c"),
  cpp   = safe_require("linus.keywords.cpp"),
}

-- Load C_FALLBACK tables into _tables for easy access
for _, name in ipairs(C_FALLBACK) do
  _tables[name] = safe_require("linus.keywords." .. name)
end

-- Look up a word in the keyword reference table for a language.
-- Returns a string[] ready for the renderer, or nil if not found.
---@param lang string
---@param word string
---@return string[]|nil
function M.lookup(lang, word)
  local tbl = _tables[lang]
  if not tbl then return nil end
  local entry = tbl[word] or tbl[word:lower()]
  -- Fall back through the C_FALLBACK chain for C-family languages
  if not entry and (lang == "c" or lang == "cpp") then
    for _, name in ipairs(C_FALLBACK) do
      local ftbl = _tables[name]
      if ftbl then
        entry = ftbl[word] or ftbl[word:lower()]
        if entry then break end
      end
    end
  end
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
