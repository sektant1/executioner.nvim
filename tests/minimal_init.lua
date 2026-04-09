local M = {}

local function ensure(name, url)
  local path = "/tmp/executioner-deps/" .. name
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.system({ "git", "clone", "--depth=1", url, path })
  end
  vim.opt.runtimepath:prepend(path)
end

ensure("plenary.nvim", "https://github.com/nvim-lua/plenary.nvim")
ensure("telescope.nvim", "https://github.com/nvim-telescope/telescope.nvim")

vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.swapfile = false

package.path = table.concat({
  vim.fn.getcwd() .. "/?.lua",
  vim.fn.getcwd() .. "/?/init.lua",
  package.path,
}, ";")

vim.cmd("runtime plugin/plenary.vim")
vim.cmd("runtime plugin/executioner.lua")

require("plenary.busted")
return M
