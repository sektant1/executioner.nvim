local config = require("executioner.config")

local M = {}

function M.setup(user_opts)
  config.setup(user_opts)

  local km = config.options.keymaps.run
  if type(km) == "string" and km ~= "" then
    vim.keymap.set("n", km, function()
      M.run_scripts()
    end, { desc = "Executioner: run script" })
  end
end

function M.run_scripts(opts)
  require("executioner.picker").run(opts)
end

function M.rerun()
  require("executioner.executor").rerun()
end

function M.configure()
  require("executioner.build").configure()
end

function M.build(opts, target)
  require("executioner.build").build(opts, target)
end

function M.build_last()
  require("executioner.build").build_last()
end

return M
