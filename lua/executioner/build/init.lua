local config = require("executioner.config")
local utils = require("executioner.utils")
local terminal = require("executioner.terminal")
local detect = require("executioner.build.detect")

local M = {}

M._last = nil

local backends = {
  cmake = function()
    return require("executioner.build.cmake")
  end,
  make = function()
    return require("executioner.build.make")
  end,
  meson = function()
    return require("executioner.build.meson")
  end,
}

---@param system string
---@return table|nil
local function get_backend(system)
  local loader = backends[system]
  return loader and loader() or nil
end

---Normalize a mixed target list into { name, display } entries.
---Backends may return plain strings or { name, display } tables.
---@param raw (string|table)[]
---@return { name: string, display: string }[]
local function normalize_targets(raw)
  local out = {}
  for _, t in ipairs(raw) do
    if type(t) == "string" then
      table.insert(out, { name = t, display = t })
    elseif type(t) == "table" and t.name then
      table.insert(out, { name = t.name, display = t.display or t.name })
    end
  end
  return out
end

---@return string|nil system, table|nil backend
local function detect_system()
  local system = detect.detect(vim.fn.getcwd())
  if not system then
    utils.warn("No build system detected (looked for CMakeLists.txt, Makefile, meson.build)")
    return nil, nil
  end
  local backend = get_backend(system)
  if not backend then
    utils.err("No backend for build system: " .. system)
    return nil, nil
  end
  return system, backend
end

---@param label string
---@return table
local function make_script(label)
  return { name = label, path = vim.fn.getcwd() }
end

-- Public API

function M.configure()
  local system, backend = detect_system()
  if not system then
    return
  end
  if not backend.configure_cmd then
    utils.notify(system .. " does not have a configure step (just run :ExecutionerBuild)")
    return
  end
  local cmd = backend.configure_cmd()
  utils.notify("Configuring with " .. system .. "…")
  terminal.run(cmd, make_script(system .. " configure"))
end

---@param opts table|nil Telescope picker overrides
---@param target string|nil build this target directly (skip picker)
function M.build(opts, target)
  local system, backend = detect_system()
  if not system then
    return
  end

  if backend.is_configured and not backend.is_configured() then
    utils.warn(system .. " is not configured. Run :ExecutionerConfigure first")
    return
  end

  if target and target ~= "" then
    M._last = { system = system, target = target }
    local cmd = backend.build_cmd(target)
    terminal.run(cmd, make_script(system .. " build: " .. target))
    return
  end

  local raw = backend.targets()
  local targets = normalize_targets(raw)

  -- No targets found -> run default build
  if #targets == 0 then
    M._last = { system = system, target = nil }
    local cmd = backend.build_cmd(nil)
    terminal.run(cmd, make_script(system .. " build"))
    return
  end

  M._pick_target(system, backend, targets, opts)
end

function M.build_last()
  if not M._last then
    utils.warn("No previous build target to rerun")
    return
  end
  local backend = get_backend(M._last.system)
  if not backend then
    utils.err("Build system " .. M._last.system .. " backend unavailable")
    return
  end
  local label = M._last.system .. " build"
  if M._last.target then
    label = label .. ": " .. M._last.target
  end
  local cmd = backend.build_cmd(M._last.target)
  terminal.run(cmd, make_script(label))
end

---@return string[]
function M.complete_targets()
  local system = detect.detect(vim.fn.getcwd())
  if not system then
    return {}
  end
  local backend = get_backend(system)
  if not backend then
    return {}
  end
  if backend.is_configured and not backend.is_configured() then
    return {}
  end
  local raw = backend.targets()
  local targets = normalize_targets(raw)
  return vim.tbl_map(function(t)
    return t.name
  end, targets)
end

function M._pick_target(system, backend, targets, opts)
  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    utils.err("telescope.nvim is required for the target picker")
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local themes = require("telescope.themes")

  local function resolve_theme(o)
    local t = config.options.telescope.theme
    if type(t) == "string" and themes["get_" .. t] then
      return themes["get_" .. t](o or {})
    elseif type(t) == "table" then
      return vim.tbl_deep_extend("force", t, o or {})
    end
    return o or {}
  end

  local picker_opts = resolve_theme(opts)

  pickers
    .new(picker_opts, {
      prompt_title = "Executioner Build (" .. system .. ")",
      finder = finders.new_table({
        results = targets,
        entry_maker = function(item)
          return {
            value = item.name,
            display = item.display,
            ordinal = item.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(picker_opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          local selected = selection.value
          M._last = { system = system, target = selected }
          local cmd = backend.build_cmd(selected)
          terminal.run(cmd, make_script(system .. " build: " .. selected))
        end)
        return true
      end,
    })
    :find()
end

return M
