local M = {}

function M.check()
  vim.health.start("executioner.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim " .. tostring(vim.version()))
  else
    vim.health.error("Neovim 0.10+ required")
  end

  if pcall(require, "telescope") then
    vim.health.ok("telescope.nvim found")
  else
    vim.health.error("telescope.nvim not found (required)")
  end

  if pcall(require, "plenary") then
    vim.health.ok("plenary.nvim found")
  else
    vim.health.warn("plenary.nvim not found (recommended)")
  end

  if pcall(require, "toggleterm") then
    vim.health.ok("toggleterm.nvim found (optional)")
  else
    vim.health.info("toggleterm.nvim not installed (optional)")
  end

  local config = require("executioner.config")
  local dir = config.resolved_scripts_dir()
  if vim.fn.isdirectory(dir) == 1 then
    vim.health.ok("scripts_dir exists: " .. dir)
  else
    vim.health.warn("scripts_dir does not exist: " .. dir)
  end

  local interpreters = { "bash", "python3", "node", "pwsh" }
  for _, bin in ipairs(interpreters) do
    if vim.fn.executable(bin) == 1 then
      vim.health.ok(bin .. " available")
    else
      vim.health.info(bin .. " not on PATH")
    end
  end
end

return M
