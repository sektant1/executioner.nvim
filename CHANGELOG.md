# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-09

### Added

- Telescope picker for discovering and running scripts
- Script detection by file extension and executable bit
- Shebang-aware execution (files with `#!` + executable bit run directly)
- Configurable extensions map (`.py` → `python3`, `.sh` → `bash`, etc.)
- Three terminal modes: float, split, and toggleterm
- Argument prompt via `vim.ui.input` before execution
- Per-script args cache persisted across sessions (`vim.fn.stdpath("state")`)
- `:Executioner` command to open the picker
- `:ExecutionerRerun` command to re-run the last script without the picker
- `q` mapping in terminal buffers to close quickly
- `:Telescope executioner` and `:Telescope executioner scripts` integration
- Recursive directory scanning with configurable depth and ignore patterns
- `:checkhealth executioner` for dependency and config validation
- `on_exit` callback hook (runs in `vim.schedule` — safe for API calls)
- Full vimdoc (`:help executioner`)
