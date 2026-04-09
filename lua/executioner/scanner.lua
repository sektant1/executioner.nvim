local config = require 'executioner.config'
local utils = require 'executioner.utils'

local M = {}

local function is_ignored(name, ignore)
  for _, pat in ipairs(ignore) do
    if name == pat then
      return true
    end
  end
  return false
end

local function has_known_ext(name, exts)
  local ext = name:match '%.([^.]+)$'
  return ext and exts[ext:lower()] ~= nil
end

---@return { path: string, name: string, ext: string? }[]
function M.scan()
  local opts = config.options
  local root = config.resolved_scripts_dir()

  if vim.fn.isdirectory(root) == 0 then
    utils.err('scripts_dir does not exist: ' .. root)
    return {}
  end

  local results = {}
  local dir_opts = {
    depth = opts.recursive and opts.max_depth or 1,
    skip = function(dirname)
      return not is_ignored(dirname, opts.ignore)
    end,
  }

  for name, type_ in vim.fs.dir(root, dir_opts) do
    if type_ == 'file' and not is_ignored(vim.fs.basename(name), opts.ignore) then
      local full = vim.fs.joinpath(root, name)
      local ext = name:match '%.([^.]+)$'
      local known = has_known_ext(name, opts.extensions)
      local exec = opts.include_executables and utils.is_executable(full)
      if known or exec then
        table.insert(results, {
          path = full,
          name = utils.display_name(full),
          ext = ext and ext:lower() or nil,
        })
      end
    end
  end

  table.sort(results, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  return results
end

return M
