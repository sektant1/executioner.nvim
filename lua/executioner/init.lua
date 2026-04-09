local config = require 'executioner.config'

local M = {}

function M.setup(user_opts)
  config.setup(user_opts)

  local km = config.options.keymaps.run
  if type(km) == 'string' and km ~= '' then
    vim.keymap.set('n', km, function()
      M.run_scripts()
    end, { desc = 'Executioner: run script' })
  end
end

function M.run_scripts(opts)
  require('executioner.picker').run(opts)
end

return M
