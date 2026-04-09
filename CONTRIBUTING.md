# Contributing to executioner.nvim

Thanks for your interest in contributing!

## Getting started

1. Fork the repo and clone your fork
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes

## Running tests

```bash
make test
```

Or manually:

```bash
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/executioner/ { minimal_init = 'tests/minimal_init.lua' }"
```

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted runner. Dependencies are cloned automatically to `/tmp/executioner-deps/` on first run.

## Linting

```bash
make lint
```

This runs [StyLua](https://github.com/JohnnyMorganz/StyLua) against `lua/` and `tests/`. The project uses the config in `.stylua.toml`.

## Submitting a PR

1. Ensure all tests pass (`make test`)
2. Ensure stylua passes (`make lint`)
3. Add tests for new functionality
4. Update `doc/executioner.txt` if adding user-facing features
5. Open a PR against `main`

## Code style

- Follow existing patterns in the codebase
- One module = one responsibility
- Keep modules small and focused
- Use `vim.notify` via `utils.notify/warn/err` for user-facing messages

## Reporting bugs

Open an issue with:
- Neovim version (`:version`)
- Plugin version or commit hash
- Minimal config to reproduce
- Steps to reproduce
- Expected vs actual behavior
