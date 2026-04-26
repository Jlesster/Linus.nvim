# jlesster.nvim

Rich universal hover for Java, Go, C, and C++. Brings rust-analyzer-level hover
help to jdtls, gopls, and clangd — type hierarchy, docs, implementations, and
a bundled keyword reference as a fallback when LSP returns nothing.

## Requirements

- [hover.nvim](https://github.com/lewis6991/hover.nvim)
- One or more of: `jdtls`, `gopls`, `clangd` attached to a buffer

## Installation

```lua
{
  dir = "~/projects/jlesster.nvim",
  name = "jlesster",
  dependencies = { "lewis6991/hover.nvim" },
  ft = { "java", "go", "c", "cpp" },
  config = function()
    require("jlesster").setup()
  end,
}
```

## Configuration

All options with defaults:

```lua
require("jlesster").setup({
  priority               = 1010,    -- hover.nvim provider priority (> LSP default 1000)
  border                 = "single",
  max_width              = 80,
  max_height             = 30,
  pinnable               = true,    -- enables <leader>K to pin/unpin the float
  keyword_overrides_path = nil,     -- path to a Lua file returning override table

  sections = {
    signature       = true,
    docs            = true,
    hierarchy       = true,
    implementations = true,
    fallback        = true,         -- keyword reference when LSP returns nothing
  },
})
```

## Keyword overrides

Point `keyword_overrides_path` at a Lua file that returns a table:

```lua
-- ~/.config/nvim/jlesster-overrides.lua
return {
  java = {
    MyAnnotation = "**`@MyAnnotation`** — does something specific to this project.",
  },
  go = {
    myPkg = "**`myPkg`** — internal package for X.",
  },
}
```

## Keymaps

| Key | Action |
|-----|--------|
| `K` | Hover (via hover.nvim) |
| `gK` | Cycle to previous provider |
| `<leader>K` | Pin / unpin the last hover float |

Inside a pinned float:

| Key | Action |
|-----|--------|
| `q` / `<Esc>` | Close |
| `y` | Copy contents to system clipboard |

## What each language gets

| Feature | Java | Go | C | C++ |
|---------|------|----|---|-----|
| Signature | ✓ jdtls extended | ✓ gopls | ✓ clangd | ✓ clangd |
| Javadoc / godoc | ✓ | ✓ | ✓ (doxygen) | ✓ (doxygen) |
| Type hierarchy | ✓ supertypes + subtypes | — | ✓ supertypes | ✓ supertypes |
| Implementations | ✓ | ✓ | — | — |
| Macro info | — | — | ✓ | ✓ |
| Keyword fallback | ✓ | ✓ | ✓ | ✓ (+ C) |
