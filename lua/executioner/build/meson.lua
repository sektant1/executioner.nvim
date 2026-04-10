local config = require("executioner.config")

local M = {}

local function project_root()
  return vim.fn.getcwd()
end

---@return string
function M.build_dir()
  local dir = config.options.build.meson.build_dir
  if dir:match("^/") or dir:match("^%a:[/\\]") then
    return dir
  end
  return project_root() .. "/" .. dir
end

---@return boolean
function M.is_configured()
  return vim.fn.filereadable(M.build_dir() .. "/build.ninja") == 1
    or vim.fn.filereadable(M.build_dir() .. "/meson-private/coredata.dat") == 1
end

---@return string[]
function M.configure_cmd()
  local opts = config.options.build.meson
  local cmd = { "meson", "setup", M.build_dir(), project_root() }
  vim.list_extend(cmd, opts.setup_args)
  return cmd
end

---@param target string|nil
---@return string[]
function M.build_cmd(target)
  local opts = config.options.build.meson
  local cmd = { "meson", "compile", "-C", M.build_dir() }
  if target and target ~= "" then
    table.insert(cmd, target)
  end
  vim.list_extend(cmd, opts.compile_args)
  return cmd
end

---Parse targets via `meson introspect --targets`.
---@return string[]
function M.targets()
  if not M.is_configured() then
    return {}
  end
  local raw = vim.fn.system({ "meson", "introspect", "--targets", M.build_dir() })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" then
    return {}
  end
  local result = {}
  for _, entry in ipairs(data) do
    if entry.name and entry.name ~= "" then
      local display = entry.name
      if entry.type then
        display = entry.name .. " (" .. entry.type .. ")"
      end
      table.insert(result, { name = entry.name, display = display })
    end
  end
  table.sort(result, function(a, b)
    return a.name < b.name
  end)
  -- Flatten to name strings for the picker, but keep display info
  return result
end

return M
