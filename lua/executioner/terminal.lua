local config = require("executioner.config")
local utils = require("executioner.utils")

local M = {}

local function start_term(buf, cmd, script, cwd)
  local winid = vim.api.nvim_get_current_win()

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end, { buffer = buf, desc = "Close Executioner terminal" })

  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart(cmd, {
      term = true,
      cwd = cwd,
      on_exit = function(_, code, _)
        vim.schedule(function()
          if config.options.on_exit then
            pcall(config.options.on_exit, code, script.path)
          end
          if code == 0 and config.options.terminal.auto_close then
            if vim.api.nvim_win_is_valid(winid) then
              vim.api.nvim_win_close(winid, true)
            end
          else
            utils.notify(("%s exited with code %d"):format(script.name, code))
          end
        end)
      end,
    })
  end)

  if config.options.terminal.start_insert then
    vim.cmd("startinsert")
  end
end

local function run_split(cmd, script, cwd)
  local s = config.options.terminal.split
  local mod = s.direction .. (s.vertical and " vertical" or "")
  vim.cmd(("%s %dnew"):format(mod, s.size))
  local buf = vim.api.nvim_get_current_buf()
  start_term(buf, cmd, script, cwd)
end

local function run_float(cmd, script, cwd)
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
  if type(title) == "function" then
    title = title(script.name)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    style = "minimal",
    border = f.border,
    title = title,
    title_pos = "center",
  })
  start_term(buf, cmd, script, cwd)
end

local function run_toggleterm(cmd, script, cwd)
  local ok, tt = pcall(require, "toggleterm.terminal")
  if not ok then
    utils.warn("toggleterm.nvim not found, falling back to float")
    return run_float(cmd, script, cwd)
  end
  tt.Terminal
    :new({
      cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " "),
      dir = cwd,
      direction = "float",
      close_on_exit = config.options.terminal.auto_close,
    })
    :toggle()
end

function M.run(cmd, script)
  -- Use explicit cwd from build detection if set, otherwise fall back to Neovim cwd
  local cwd = script.cwd or vim.fn.getcwd()

  local t = config.options.terminal.type
  if t == "split" then
    return run_split(cmd, script, cwd)
  elseif t == "float" then
    return run_float(cmd, script, cwd)
  elseif t == "toggleterm" then
    return run_toggleterm(cmd, script, cwd)
  else
    utils.err("Unknown terminal.type: " .. tostring(t))
  end
end

return M
