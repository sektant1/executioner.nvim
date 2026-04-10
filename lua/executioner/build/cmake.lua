local config = require("executioner.config")

local M = {}

--- Set by build/init.lua before calling any backend method.
M.project_root = nil

---@return string
function M.build_dir()
  local dir = config.options.build.cmake.build_dir
  if dir:match("^/") or dir:match("^%a:[/\\]") then
    return dir
  end
  return M.project_root .. "/" .. dir
end

---@return boolean
function M.is_configured()
  return vim.fn.filereadable(M.build_dir() .. "/CMakeCache.txt") == 1
end

---@return string[]
function M.configure_cmd()
  local opts = config.options.build.cmake
  local cmd = { "cmake", "-B", M.build_dir(), "-S", M.project_root }
  if opts.generator and opts.generator ~= "" then
    vim.list_extend(cmd, { "-G", opts.generator })
  end
  vim.list_extend(cmd, opts.configure_args)
  return cmd
end

---@param target string|nil
---@return string[]
function M.build_cmd(target)
  local opts = config.options.build.cmake
  local cmd = { "cmake", "--build", M.build_dir() }
  if target and target ~= "" then
    vim.list_extend(cmd, { "--target", target })
  end
  vim.list_extend(cmd, opts.build_args)
  return cmd
end

---Parse targets from `cmake --build <dir> --target help`.
---@return string[]
function M.targets()
  if not M.is_configured() then
    return {}
  end
  local raw = vim.fn.system({ "cmake", "--build", M.build_dir(), "--target", "help" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local result = {}
  for line in raw:gmatch("[^\n]+") do
    local t = line:match("^%.%.%.%s+(.+)$")
    if t then
      t = t:gsub("%s*%(.*%)%s*$", "")
      t = vim.trim(t)
      if t ~= "" then
        table.insert(result, t)
      end
    end
  end
  table.sort(result)
  return result
end

return M
