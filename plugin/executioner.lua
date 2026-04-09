if vim.g.loaded_executioner == 1 then
  return
end
vim.g.loaded_executioner = 1

if vim.fn.has 'nvim-0.12' == 0 then
  vim.notify('executioner.nvim requires Neovim 0.12+', vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command('Executioner', function()
  require('executioner').run_scripts()
end, { desc = 'Open Executioner script picker' })

vim.api.nvim_create_user_command('ExecutionerRerun', function()
  require('executioner').rerun()
end, { desc = 'Re-run last Executioner script' })
