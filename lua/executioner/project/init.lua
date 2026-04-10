local utils = require("executioner.utils")
local templates = require("executioner.project.templates")

local M = {}

local build_systems = { "CMake", "Make", "Meson" }
local languages = { "C", "C++" }
local project_types = {
  "Executable",
  "Static Library",
  "Shared Library",
  "Header-only Library",
  "Library + Executable",
}
local c_standards = { "c11", "c17", "c23" }
local cpp_standards = { "c++17", "c++20", "c++23" }

-- Prompt helpers

local function cancelled()
  utils.notify("Project creation cancelled")
end

local function ask(items, prompt, cb)
  vim.ui.select(items, { prompt = prompt }, function(choice)
    if not choice then
      return cancelled()
    end
    cb(choice)
  end)
end

local function ask_yn(prompt, cb)
  vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
    if not choice then
      return cancelled()
    end
    cb(choice == "Yes")
  end)
end

-- File writer

---Write all generated files into the target directory.
---@param dir string absolute path
---@param files table<string, string>
---@return integer count
local function write_files(dir, files)
  local count = 0
  for path, content in pairs(files) do
    local full = dir .. "/" .. path
    vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
    local f = io.open(full, "w")
    if f then
      f:write(content)
      f:close()
      count = count + 1
    else
      utils.warn("Failed to write: " .. full)
    end
  end
  return count
end

-- Core generation

---@param opts table collected wizard answers
function M._generate(opts)
  local dir = vim.fn.getcwd() .. "/" .. opts.name

  if vim.fn.isdirectory(dir) == 1 then
    utils.warn("Directory already exists: " .. opts.name)
    return
  end

  vim.fn.mkdir(dir, "p")

  local files = templates.generate(opts)
  local count = write_files(dir, files)

  if opts.git_init then
    vim.fn.system({ "git", "init", dir })
  end

  utils.notify(
    ("Created %s %s project '%s' (%d files)"):format(
      opts.build_system,
      opts.language,
      opts.name,
      count
    )
  )

  ask_yn("Change to project directory?", function(yes)
    if yes then
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      vim.cmd("edit .")
    end
  end)
end

-- Wizard

function M.create()
  -- 1. Project name
  vim.ui.input({ prompt = "Project name: " }, function(raw)
    if not raw or raw == "" then
      return cancelled()
    end

    local name = raw:gsub("%s+", "_"):gsub("[^%w_%-]", "")
    if name == "" then
      utils.warn("Invalid project name")
      return
    end

    -- 2. Build system
    ask(build_systems, "Build system:", function(system)
      -- 3. Language
      ask(languages, "Language:", function(lang)
        -- 4. Project type
        ask(project_types, "Project type:", function(ptype)
          -- 5. Standard
          local standards = lang == "C" and c_standards or cpp_standards
          ask(standards, "Language standard:", function(std)
            -- 7. .gitignore
            ask_yn("Add .gitignore?", function(gitignore)
              -- 6. Git init
              ask_yn("Initialize git repository?", function(git_init)
                M._generate({
                  name = name,
                  build_system = system,
                  language = lang,
                  project_type = ptype,
                  standard = std,
                  gitignore = gitignore,
                  git_init = git_init,
                })
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

return M
