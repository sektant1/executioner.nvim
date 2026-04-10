local M = {}

local makefile_names = { "Makefile", "makefile", "GNUmakefile" }

---Priority: CMake > Meson > Make
---@param root string
---@return string|nil system "cmake"|"make"|"meson"
function M.detect(root)
  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
    return "cmake"
  end
  if vim.fn.filereadable(root .. "/meson.build") == 1 then
    return "meson"
  end
  for _, name in ipairs(makefile_names) do
    if vim.fn.filereadable(root .. "/" .. name) == 1 then
      return "make"
    end
  end
  return nil
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
