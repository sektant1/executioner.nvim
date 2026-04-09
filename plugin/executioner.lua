if vim.g.loaded_executioner == 1 then
  return
end
vim.g.loaded_executioner = 1

if vim.fn.has 'nvim-0.10' == 0 then
  vim.notify('executioner.nvim requires Neovim 0.10+', vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command('Executioner', function()
  require('executioner').run_scripts()
end, { desc = 'Open Executioner script picker' })
