local M = {}

---@class Executioner.Config
M.defaults = {
  scripts_dir = ".",
  recursive = true,
  max_depth = 3,
  ignore = { "node_modules", ".git", ".venv", "target", "dist" },
  include_executables = true,
  always_prompt_args = true,

  extensions = {
    sh = "bash",
    bash = "bash",
    zsh = "zsh",
    fish = "fish",
    py = "python3",
    ps1 = "pwsh",
    lua = "nvim -l",
    js = "node",
    ts = "tsx",
    rb = "ruby",
    pl = "perl",
    bat = "cmd /c",
    cmd = "cmd /c",
  },

  terminal = {
    type = "split", -- "split" | "float" | "toggleterm"
    split = { direction = "belowright", size = 15, vertical = false },
    float = {
      width = 0.8,
      height = 0.8,
      border = "rounded",
      title = " Executioner ",
    },
    auto_close = false,
    start_insert = true,
  },

  telescope = { theme = "dropdown", preview = true },
  keymaps = { run = false },
  on_exit = nil,
}

M.options = vim.deepcopy(M.defaults)

---Validate a single field using the new or legacy vim.validate signature.
local has_new_validate = vim.fn.has("nvim-0.11") == 1

local function v(name, value, validator)
  if value == nil then
    return
  end
  if has_new_validate then
    -- New signature: vim.validate(name, value, validator, optional_or_message)
    vim.validate(name, value, validator, true)
  else
    -- Legacy signature: vim.validate({ [name] = { value, validator, optional } })
    vim.validate({ [name] = { value, validator, true } })
  end
end

---Validate top-level user options.
---@param user table
local function validate(user)
  v("scripts_dir", user.scripts_dir, { "string", "function" })
  v("recursive", user.recursive, "boolean")
  v("max_depth", user.max_depth, "number")
  v("ignore", user.ignore, "table")
  v("extensions", user.extensions, "table")
  v("include_executables", user.include_executables, "boolean")
  v("always_prompt_args", user.always_prompt_args, "boolean")
  v("terminal", user.terminal, "table")
  v("telescope", user.telescope, "table")
  v("keymaps", user.keymaps, "table")
  v("on_exit", user.on_exit, "function")

  if user.terminal then
    v("terminal.type", user.terminal.type, "string")
    v("terminal.split", user.terminal.split, "table")
    v("terminal.float", user.terminal.float, "table")
    v("terminal.auto_close", user.terminal.auto_close, "boolean")
    v("terminal.start_insert", user.terminal.start_insert, "boolean")
  end
end
---Merge user options into defaults (deep).
---@param user table|nil
function M.setup(user)
  if user then
    validate(user)
  end
  M.options = vim.tbl_deep_extend("force", M.defaults, user or {})
  return M.options
end

---Resolve scripts_dir to an absolute path (supports string or function).
---@return string
function M.resolved_scripts_dir()
  local sd = M.options.scripts_dir
  if type(sd) == "function" then
    sd = sd()
  end
  if sd == "." or sd == "" then
    sd = vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(sd, ":p"):gsub("/$", "")
end

return M
