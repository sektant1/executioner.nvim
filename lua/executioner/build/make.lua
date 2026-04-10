local config = require("executioner.config")
local detect = require("executioner.build.detect")

local M = {}

--- Set by build/init.lua before calling any backend method.
M.project_root = nil

---@return string[]
function M.build_cmd(target)
  local opts = config.options.build.make
  local cmd = { "make", "-C", M.project_root }
  vim.list_extend(cmd, opts.args)
  if target and target ~= "" then
    table.insert(cmd, target)
  end
  return cmd
end

---Parse targets from the Makefile by matching `target:` lines.
---Skips pattern rules (%), special targets (.), and variable assignments.
---@return string[]
function M.targets()
  local path = detect.find_makefile(M.project_root)
  if not path then
    return {}
  end
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()

  local seen = {}
  local result = {}

  for phony_line in content:gmatch("%.PHONY%s*:%s*([^\n]+)") do
    for t in phony_line:gmatch("%S+") do
      if not seen[t] then
        seen[t] = true
        table.insert(result, t)
      end
    end
  end

  for line in content:gmatch("[^\n]+") do
    local t = line:match("^([a-zA-Z_][a-zA-Z0-9_%-]*)%s*:")
    if t and not seen[t] then
      -- Skip if line contains = (variable assignment like `CC := gcc`)
      if not line:match("=") then
        seen[t] = true
        table.insert(result, t)
      end
    end
  end

  table.sort(result)
  return result
end

M.configure_cmd = nil
M.is_configured = nil

return M
