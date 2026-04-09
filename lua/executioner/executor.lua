local config = require 'executioner.config'
local utils = require 'executioner.utils'
local terminal = require 'executioner.terminal'

local M = {}

M._last = nil -- { script, raw_args }

---Build the command list to run the script.
---@param script { path: string, ext: string? }
---@param args string[]
---@return string[]|nil cmd, string? err
function M.build_cmd(script, args)
  local opts = config.options

  -- 1. Executable + shebang → run directly
  if utils.is_executable(script.path) and utils.read_shebang(script.path) then
    local cmd = { script.path }
    vim.list_extend(cmd, args)
    return cmd
  end

  -- 2. Known extension → interpreter
  if script.ext and opts.extensions[script.ext] then
    local interp = opts.extensions[script.ext]
    local cmd = vim.split(interp, ' ', { trimempty = true })
    table.insert(cmd, script.path)
    vim.list_extend(cmd, args)
    return cmd
  end

  -- 3. Bare executable (no shebang, no ext)
  if utils.is_executable(script.path) then
    local cmd = { script.path }
    vim.list_extend(cmd, args)
    return cmd
  end

  return nil, 'Cannot determine how to run: ' .. script.path
end

function M.run(script, raw_args)
  M._last = { script = script, raw_args = raw_args }
  local args = utils.split_args(raw_args)
  local cmd, err = M.build_cmd(script, args)
  if not cmd then
    utils.err(err)
    return
  end
  terminal.run(cmd, script)
end

function M.rerun()
  if not M._last then
    utils.warn 'No previous script to rerun'
    return
  end
  M.run(M._last.script, M._last.raw_args)
end

return M
