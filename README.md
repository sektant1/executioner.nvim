<div align="center">

<img src="assets/logo.png" alt="executioner.nvim" width="600" />


Telescope-powered script runner for Neovim 0.10+

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-green.svg?logo=neovim)](https://neovim.io)
[![LuaRocks](https://img.shields.io/luarocks/v/sektant1/executioner.nvim?logo=lua&color=purple)](https://luarocks.org/modules/sektant1/executioner.nvim)

Fuzzy find scripts or binaries in your project, pick one, and run it in a terminal buffer.

![demo](assets/demo.gif)

</div>

## Features

- **Telescope picker** with fuzzy search and file preview
- **Auto-detection** by file extension or executable bit
- **Shebang support** — executable files with shebangs run directly
- **Argument prompt** via `vim.ui.input` before execution
- **Args memory** — last-used arguments per script are remembered across sessions
- **Quick rerun** — `:ExecutionerRerun` re-runs the last script without the picker
- **Terminal modes** — floating window, split, or toggleterm
- **Quick close** — press `q` in the terminal buffer to close it
- **Configurable** — extensions map, ignore patterns, recursive scan, depth limit
- **Lazy-loaded** — nothing runs until you open the picker

## Requirements

- Neovim >= 0.10
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

Optional:
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) — only needed when `terminal.type = "toggleterm"`

## Installation

### lazy.nvim

```lua
{
  "sektant1/executioner.nvim",
  cmd = { "Executioner", "ExecutionerRerun" },
  keys = {
    { "<leader>er", function() require("executioner").run_scripts() end, desc = "Executioner: run script" },
  },
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  opts = {},
  config = function(_, opts)
    require("executioner").setup(opts)
    require("telescope").load_extension("executioner")
  end,
}
```

### packer.nvim

```lua
use {
  "sektant1/executioner.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("executioner").setup()
    require("telescope").load_extension("executioner")
  end,
}
```

### rocks.nvim
```vim
:Rocks install executioner.nvim
```

## Usage

```vim
:Executioner
```

Or from Lua:

```lua
require("executioner").run_scripts()
```

Select a script, optionally enter arguments, and it runs in a terminal buffer.
The args prompt is pre-filled with the last-used arguments for that script.
Press `q` in the terminal buffer (normal mode) to close it.

To re-run the last script without the picker:

```vim
:ExecutionerRerun
```

## Configuration

Defaults are shown below.

```lua
require("executioner").setup({
  scripts_dir = ".",              -- string or function(): string
  recursive = true,
  max_depth = 3,
  ignore = { "node_modules", ".git", ".venv", "target", "dist" },
  include_executables = true,
  always_prompt_args = true,

  extensions = {
    sh   = "bash",
    bash = "bash",
    zsh  = "zsh",
    fish = "fish",
    py   = "python3",
    ps1  = "pwsh",
    lua  = "nvim -l",
    js   = "node",
    ts   = "tsx",
    rb   = "ruby",
    pl   = "perl",
    bat  = "cmd /c",
    cmd  = "cmd /c",
  },

  terminal = {
    type = "split",               -- "split" | "float" | "toggleterm"
    split = {
      direction = "belowright",
      size = 15,
      vertical = false,
    },
    float = {
      width  = 0.8,
      height = 0.8,
      border = "rounded",
      title  = " Executioner ",
    },
    auto_close   = false,
    start_insert = true,
  },

  telescope = {
    theme   = "dropdown",
    preview = true,
  },
  keymaps = { run = false },      -- set to e.g. "<leader>er" for a global mapping
  on_exit = nil,                  -- function(code, script_path)
})
```

## Recipes

### Run scripts from a `scripts/` directory

```lua
require("executioner").setup({
  scripts_dir = "scripts",
  recursive = true,
})
```

### Horizontal split instead of float

```lua
require("executioner").setup({
  terminal = { type = "split", split = { size = 20 } },
})
```

### Auto-close on success

```lua
require("executioner").setup({
  terminal = { auto_close = true },
})
```

### Add a custom extension

```lua
require("executioner").setup({
  extensions = { rs = "cargo run --" },
})
```

### Dynamic scripts directory

```lua
require("executioner").setup({
  scripts_dir = function()
    return vim.fn.getcwd() .. "/bin"
  end,
})
```

### Skip argument prompt

```lua
require("executioner").setup({
  always_prompt_args = false,
})
```

## Health Check

```vim
:checkhealth executioner
```

Verifies dependencies (telescope, plenary, toggleterm), Neovim version, `scripts_dir` existence, and common interpreter availability.

## FAQ

**Q: How does executioner decide which interpreter to use?**
A: First it checks for a shebang (`#!`) + executable bit — if both exist, the file runs directly. Otherwise it looks up the file extension in the `extensions` map. Bare executables without a shebang or known extension also run directly.

**Q: Can I use this without Telescope?**
A: No. Telescope is a required dependency for the picker UI.

**Q: Does it work on Windows?**
A: The `bat` and `cmd` extensions map to `cmd /c`. Path handling uses `vim.fn.fnamemodify`. It should work for basic cases but is primarily tested on Unix.

**Q: How do I add support for a new language?**
A: Add the extension to the `extensions` table: `extensions = { go = "go run" }`.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Run tests: `make test` or `nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"`
4. Ensure `stylua` passes
5. Open a PR

## License

MIT
