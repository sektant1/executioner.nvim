local M = {}

local makefile_names = { "Makefile", "makefile", "GNUmakefile" }

---Check a single directory for a build system file.
---@param dir string
---@return string|nil system "cmake"|"make"|"meson"
local function detect_in(dir)
  if vim.fn.filereadable(dir .. "/CMakeLists.txt") == 1 then
    return "cmake"
  end
  if vim.fn.filereadable(dir .. "/meson.build") == 1 then
    return "meson"
  end
  for _, name in ipairs(makefile_names) do
    if vim.fn.filereadable(dir .. "/" .. name) == 1 then
      return "make"
    end
  end
  return nil
end

---Walk upward from `start` to find a build system file.
---Priority at each level: CMake > Meson > Make.
---@param start string starting directory
---@return string|nil system, string|nil root
function M.detect(start)
  local dir = start
  while true do
    local system = detect_in(dir)
    if system then
      return system, dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil, nil
end

---@param root string
---@return string|nil
function M.find_makefile(root)
  for _, name in ipairs(makefile_names) do
    local path = root .. "/" .. name
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

return M
