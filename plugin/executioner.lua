if vim.g.loaded_executioner == 1 then
  return
end
vim.g.loaded_executioner = 1

if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("executioner.nvim requires Neovim 0.10+", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("Executioner", function()
  require("executioner").run_scripts()
end, { desc = "Open Executioner script picker" })

vim.api.nvim_create_user_command("ExecutionerRerun", function()
  require("executioner").rerun()
end, { desc = "Re-run last Executioner script" })

vim.api.nvim_create_user_command("ExecutionerConfigure", function()
  require("executioner").configure()
end, { desc = "Configure project (CMake/Meson)" })

vim.api.nvim_create_user_command("ExecutionerBuild", function(cmd_opts)
  local target = cmd_opts.args ~= "" and cmd_opts.args or nil
  require("executioner").build(nil, target)
end, {
  desc = "Build target (pick from Telescope or pass as argument)",
  nargs = "?",
  complete = function()
    local ok, build = pcall(require, "executioner.build")
    if ok then
      return build.complete_targets()
    end
    return {}
  end,
})

vim.api.nvim_create_user_command("ExecutionerBuildLast", function()
  require("executioner").build_last()
end, { desc = "Re-run last Executioner build target" })

vim.api.nvim_create_user_command("CreateProject", function()
  require("executioner").create_project()
end, { desc = "Create a new C/C++ project (CMake/Make/Meson)" })
