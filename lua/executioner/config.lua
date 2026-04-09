local M = {}

---@class Executioner.Config
M.defaults = {
  scripts_dir = '.',
  recursive = false,
  max_depth = 3,
  ignore = { 'node_modules', '.git', '.venv', 'target', 'dist' },
  include_executables = true,
  always_prompt_args = true,

  extensions = {
    sh = 'bash',
    bash = 'bash',
    zsh = 'zsh',
    fish = 'fish',
    py = 'python3',
    ps1 = 'pwsh',
    lua = 'nvim -l',
    js = 'node',
    ts = 'tsx',
    rb = 'ruby',
    pl = 'perl',
    bat = 'cmd /c',
    cmd = 'cmd /c',
  },

  terminal = {
    type = 'float', -- "split" | "float" | "toggleterm"
    split = { direction = 'belowright', size = 15, vertical = false },
    float = {
      width = 0.8,
      height = 0.8,
      border = 'rounded',
      title = ' Executioner ',
    },
    auto_close = false,
    start_insert = true,
  },

  telescope = { theme = 'dropdown', preview = true },
  keymaps = { run = false },
  on_exit = nil,
}

M.options = vim.deepcopy(M.defaults)

---Merge user options into defaults (deep).
---@param user table|nil
function M.setup(user)
  M.options = vim.tbl_deep_extend('force', M.defaults, user or {})
  return M.options
end

---Resolve scripts_dir to an absolute path (supports string or function).
---@return string
function M.resolved_scripts_dir()
  local sd = M.options.scripts_dir
  if type(sd) == 'function' then
    sd = sd()
  end
  if sd == '.' or sd == '' then
    sd = vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(sd, ':p'):gsub('/$', '')
end

return M
