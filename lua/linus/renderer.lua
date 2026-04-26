-- linus/renderer.lua
-- Assembles markdown output from enriched data and manages the pinned float.

local M = {}

local _stashed    = nil  -- lines from the last hover, available for pinning
local _pinned_win = nil

local SEP = "---"

---@param out string[]
---@param heading string|nil
---@param lines string[]
local function append_section(out, heading, lines)
  if not lines or #lines == 0 then return end
  if #out > 0 then table.insert(out, SEP) end
  if heading then
    table.insert(out, "**" .. heading .. "**")
    table.insert(out, "")
  end
  for _, l in ipairs(lines) do table.insert(out, l) end
end

---@param out string[]
---@param heading string
---@param items string[]
---@param icon string
local function append_list(out, heading, items, icon)
  if not items or #items == 0 then return end
  if #out > 0 then table.insert(out, SEP) end
  table.insert(out, "**" .. heading .. "**")
  table.insert(out, "")
  for _, item in ipairs(items) do table.insert(out, icon .. " " .. item) end
end

-- Build the final list of markdown lines from the enriched data table.
---@param data table
---@param cfg table
---@return string[]
function M.build(data, cfg)
  local out = {}
  local s   = cfg.sections

  if s.signature       then append_section(out, nil,            data.signature)       end
  if s.docs            then append_section(out, nil,            data.docs)            end
  if data.extra        then append_section(out, nil,            data.extra)           end
  if s.hierarchy       then append_list(out, "Extends",         data.hierarchy,       "↑") end
  if s.implements      then append_list(out, "Implements",      data.implements,      "~") end
  if s.implementations then append_list(out, "Known Subtypes",  data.implementations, "↓") end

  return out
end

-- Stash the last rendered lines so they can be re-opened as a pinned float.
---@param lines string[]
function M.stash(lines)
  _stashed = lines
end

-- Toggle a pinned (non-auto-closing) float showing the last hover content.
function M.pin()
  if not _stashed or #_stashed == 0 then
    vim.notify("[linus] nothing to pin", vim.log.levels.INFO)
    return
  end

  if _pinned_win and vim.api.nvim_win_is_valid(_pinned_win) then
    vim.api.nvim_win_close(_pinned_win, true)
    _pinned_win = nil
    return
  end

  local cfg  = require("linus").config
  local buf  = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype   = "markdown"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, _stashed)
  vim.bo[buf].modifiable = false

  local width  = math.min(cfg.max_width,  vim.o.columns - 4)
  local height = math.min(cfg.max_height, #_stashed + 2)

  local win = vim.api.nvim_open_win(buf, false, {
    relative  = "cursor",
    row       = 1,
    col       = 0,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = cfg.border,
    title     = " Linus (pinned) ",
    title_pos = "center",
  })
  _pinned_win = win

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
  end

  map("q",     function() vim.api.nvim_win_close(win, true) end)
  map("<Esc>", function() vim.api.nvim_win_close(win, true) end)
  map("y",     function()
    vim.fn.setreg("+", table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    vim.notify("[linus] copied to clipboard", vim.log.levels.INFO)
  end)

  vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave" }, {
    once     = true,
    callback = function()
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        _pinned_win = nil
      end
    end,
  })
end

return M
