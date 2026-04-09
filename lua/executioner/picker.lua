local config = require 'executioner.config'
local scanner = require 'executioner.scanner'
local executor = require 'executioner.executor'
local cache = require 'executioner.cache'
local utils = require 'executioner.utils'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local previewers = require 'telescope.previewers'
local themes = require 'telescope.themes'

local M = {}

local function entry_maker(item)
  return {
    value = item,
    display = item.name,
    ordinal = item.name,
    path = item.path,
  }
end

local function resolve_theme(opts)
  local t = config.options.telescope.theme
  if type(t) == 'string' and themes['get_' .. t] then
    return themes['get_' .. t](opts or {})
  elseif type(t) == 'table' then
    return vim.tbl_deep_extend('force', t, opts or {})
  end
  return opts or {}
end

function M.run(opts)
  local scripts = scanner.scan()
  if #scripts == 0 then
    utils.warn('No scripts found in ' .. config.resolved_scripts_dir())
    return
  end

  local picker_opts = resolve_theme(opts)

  pickers
    .new(picker_opts, {
      prompt_title = 'Executioner',
      finder = finders.new_table { results = scripts, entry_maker = entry_maker },
      sorter = conf.generic_sorter(picker_opts),
      previewer = config.options.telescope.preview and conf.file_previewer(picker_opts) or nil,
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end

          local script = selection.value
          if config.options.always_prompt_args then
            local last_args = cache.get(script.path)
            vim.ui.input({ prompt = 'Arguments (optional): ', default = last_args }, function(input)
              if input then
                cache.set(script.path, input)
              end
              executor.run(script, input or '')
            end)
          else
            executor.run(script, '')
          end
        end)
        return true
      end,
    })
    :find()
end

return M
