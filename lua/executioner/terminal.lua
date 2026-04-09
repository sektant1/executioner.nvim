local config = require 'executioner.config'
local utils = require 'executioner.utils'

local M = {}

local function on_exit_factory(script)
  return function(_, code, _)
    if config.options.on_exit then
      pcall(config.options.on_exit, code, script.path)
    end
    if code == 0 and config.options.terminal.auto_close then
      vim.schedule(function()
        vim.cmd 'close'
      end)
    else
      utils.notify(('%s exited with code %d'):format(script.name, code))
    end
  end
end

local function start_term(buf, cmd, script)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart(cmd, {
      term = true, -- Neovim 0.10+ unified term flag
      on_exit = on_exit_factory(script),
    })
  end)
  vim.keymap.set('n', 'q', function()
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, desc = 'Close Executioner terminal' })
  if config.options.terminal.start_insert then
    vim.cmd 'startinsert'
  end
end

local function run_split(cmd, script)
  local s = config.options.terminal.split
  local mod = s.direction .. (s.vertical and ' vertical' or '')
  vim.cmd(('%s %dnew'):format(mod, s.size))
  local buf = vim.api.nvim_get_current_buf()
  start_term(buf, cmd, script)
end

local function run_float(cmd, script)
  local f = config.options.terminal.float
  local ui = vim.api.nvim_list_uis()[1] or { width = 120, height = 40 }

  local function dim(v, total)
    return v <= 1 and math.floor(total * v) or math.floor(v)
  end

  local w = dim(f.width, ui.width)
  local h = dim(f.height, ui.height)
  local row = math.floor((ui.height - h) / 2)
  local col = math.floor((ui.width - w) / 2)

  local title = f.title
  if type(title) == 'function' then
    title = title(script.name)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = w,
    height = h,
    row = row,
    col = col,
    style = 'minimal',
    border = f.border,
    title = title,
    title_pos = 'center',
  })
  start_term(buf, cmd, script)
end

local function run_toggleterm(cmd, script)
  local ok, tt = pcall(require, 'toggleterm.terminal')
  if not ok then
    utils.warn 'toggleterm.nvim not found, falling back to float'
    return run_float(cmd, script)
  end
  tt.Terminal
    :new({
      cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), ' '),
      direction = 'float',
      close_on_exit = config.options.terminal.auto_close,
    })
    :toggle()
end

function M.run(cmd, script)
  local t = config.options.terminal.type
  if t == 'split' then
    return run_split(cmd, script)
  elseif t == 'float' then
    return run_float(cmd, script)
  elseif t == 'toggleterm' then
    return run_toggleterm(cmd, script)
  else
    utils.err('Unknown terminal.type: ' .. tostring(t))
  end
end

return M
