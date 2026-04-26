-- jlesster.nvim
-- Rich universal hover for Java, Go, C, C++.
-- Brings rust-analyzer-level hover help to jdtls, gopls, and clangd.

local M = {}

---@class JlessterConfig
---@field priority integer          hover.nvim provider priority (default 1010)
---@field border string             float border style (default "single")
---@field max_width integer         max float width (default 80)
---@field max_height integer        max float height (default 30)
---@field pinnable boolean          enable <leader>K to pin float (default true)
---@field debug boolean             log hover results to :messages for diagnosis (default false)
---@field keyword_overrides_path string|nil  path to user keyword override file
---@field sections JlessterSections section enable/disable flags

---@class JlessterSections
---@field signature boolean
---@field docs boolean
---@field hierarchy boolean        extends (class parents)
---@field implements boolean       implements (interface parents, Java only)
---@field implementations boolean  known subtypes / interface impls
---@field fallback boolean

local defaults = {
  priority               = 1010,
  border                 = "single",
  max_width              = 80,
  max_height             = 30,
  pinnable               = true,
  debug                  = false,
  keyword_overrides_path = nil,
  sections               = {
    signature       = true,
    docs            = true,
    hierarchy       = true,
    implements      = true,
    implementations = true,
    fallback        = true,
  },
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  if M.config.keyword_overrides_path then
    local ok, overrides = pcall(dofile, M.config.keyword_overrides_path)
    if ok and type(overrides) == "table" then
      require("linus.keywords").merge_overrides(overrides)
    end
  end

  if M.config.pinnable then
    vim.keymap.set("n", "<leader>K", function()
      require("linus.renderer").pin()
    end, { desc = "Pin hover float" })
  end
end

return M
