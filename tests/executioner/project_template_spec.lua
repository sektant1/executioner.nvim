local helpers = require("tests.exec_helpers")

describe("project.templates", function()
  local templates

  before_each(function()
    package.loaded["executioner.project.templates"] = nil
    templates = require("executioner.project.templates")
  end)

  local function base_opts(overrides)
    return vim.tbl_deep_extend("force", {
      name = "testproj",
      build_system = "CMake",
      language = "C++",
      project_type = "Executable",
      standard = "c++17",
      gitignore = false,
    }, overrides or {})
  end

  -- ── CMake ─────────────────────────────────────────────────────

  describe("cmake", function()
    it("generates CMakeLists.txt for executable", function()
      local fname, content = templates.cmake.exe(base_opts())
      assert.equals("CMakeLists.txt", fname)
      assert.is_true(content:find("add_executable") ~= nil)
      assert.is_true(content:find("src/main%.cpp") ~= nil)
      assert.is_true(content:find("CXX_STANDARD 17") ~= nil)
    end)

    it("generates CMakeLists.txt for static library with include dir", function()
      local fname, content = templates.cmake.static(base_opts())
      assert.equals("CMakeLists.txt", fname)
      assert.is_true(content:find("add_library%(testproj STATIC src/testproj") ~= nil)
      assert.is_true(content:find("include_directories.-/include") ~= nil)
    end)

    it("generates CMakeLists.txt for shared library with include dir", function()
      local _, content = templates.cmake.shared(base_opts())
      assert.is_true(content:find("add_library%(testproj SHARED src/testproj") ~= nil)
      assert.is_true(content:find("include_directories.-/include") ~= nil)
      assert.is_true(content:find("POSITION_INDEPENDENT_CODE") ~= nil)
    end)

    it("generates CMakeLists.txt for header-only library with include dir", function()
      local _, content = templates.cmake.header_only(base_opts())
      assert.is_true(content:find("add_library%(testproj INTERFACE") ~= nil)
      assert.is_true(content:find("include_directories.-/include") ~= nil)
    end)

    it("generates CMakeLists.txt for lib+exe with src and include", function()
      local _, content = templates.cmake.lib_exe(base_opts())
      assert.is_true(content:find("add_library.-STATIC src/testproj") ~= nil)
      assert.is_true(content:find("add_executable.-src/main") ~= nil)
      assert.is_true(content:find("target_link_libraries") ~= nil)
      assert.is_true(content:find("include_directories.-/include") ~= nil)
    end)

    it("uses C language settings for C projects", function()
      local _, content = templates.cmake.exe(base_opts({ language = "C", standard = "c17" }))
      assert.is_true(content:find("LANGUAGES C") ~= nil)
      assert.is_true(content:find("C_STANDARD 17") ~= nil)
      assert.is_true(content:find("src/main%.c") ~= nil)
    end)
  end)

  -- ── Make ──────────────────────────────────────────────────────

  describe("make", function()
    it("generates Makefile for executable with src/", function()
      local fname, content = templates.make.exe(base_opts())
      assert.equals("Makefile", fname)
      assert.is_true(content:find("src/main%.cpp") ~= nil)
    end)

    it("generates Makefile for static library with -Iinclude", function()
      local _, content = templates.make.static(base_opts())
      assert.is_true(content:find("%-Iinclude") ~= nil)
      assert.is_true(content:find("src/testproj%.cpp") ~= nil)
      assert.is_true(content:find("ar rcs") ~= nil)
    end)

    it("generates Makefile for shared library with -Iinclude and -fPIC", function()
      local _, content = templates.make.shared(base_opts())
      assert.is_true(content:find("%-Iinclude") ~= nil)
      assert.is_true(content:find("%-fPIC") ~= nil)
      assert.is_true(content:find("src/testproj%.cpp") ~= nil)
    end)

    it("generates Makefile for header-only with include/ path", function()
      local _, content = templates.make.header_only(base_opts())
      assert.is_true(content:find("include/testproj%.hpp") ~= nil)
      assert.is_true(content:find("install") ~= nil)
    end)

    it("generates Makefile for lib+exe with -Iinclude and src/", function()
      local _, content = templates.make.lib_exe(base_opts())
      assert.is_true(content:find("%-Iinclude") ~= nil)
      assert.is_true(content:find("src/testproj%.cpp") ~= nil)
      assert.is_true(content:find("src/main%.cpp") ~= nil)
    end)

    it("uses CC/CFLAGS for C projects", function()
      local _, content = templates.make.exe(base_opts({ language = "C", standard = "c17" }))
      assert.is_true(content:find("CC ") ~= nil)
      assert.is_true(content:find("CFLAGS") ~= nil)
      assert.is_true(content:find("src/main%.c") ~= nil)
    end)
  end)

  -- ── Meson ─────────────────────────────────────────────────────

  describe("meson", function()
    it("generates meson.build for executable with src/", function()
      local fname, content = templates.meson.exe(base_opts())
      assert.equals("meson.build", fname)
      assert.is_true(content:find("executable%(") ~= nil)
      assert.is_true(content:find("src/main%.cpp") ~= nil)
    end)

    it("generates meson.build for static library with include dir", function()
      local _, content = templates.meson.static(base_opts())
      assert.is_true(content:find("static_library%(") ~= nil)
      assert.is_true(content:find("include_directories%('include'%)") ~= nil)
      assert.is_true(content:find("src/testproj%.cpp") ~= nil)
    end)

    it("generates meson.build for shared library with include dir", function()
      local _, content = templates.meson.shared(base_opts())
      assert.is_true(content:find("shared_library%(") ~= nil)
      assert.is_true(content:find("include_directories%('include'%)") ~= nil)
    end)

    it("generates meson.build for header-only with include dir", function()
      local _, content = templates.meson.header_only(base_opts())
      assert.is_true(content:find("include_directories%('include'%)") ~= nil)
      assert.is_true(content:find("install_headers%('include/testproj") ~= nil)
    end)

    it("uses c language for C projects", function()
      local _, content = templates.meson.exe(base_opts({ language = "C", standard = "c17" }))
      assert.is_true(content:find("'c',") ~= nil)
      assert.is_true(content:find("src/main%.c") ~= nil)
    end)
  end)

  -- ── Source files ──────────────────────────────────────────────

  describe("source_files", function()
    it("puts main.cpp in src/ for C++ executable", function()
      local files = templates.source_files(base_opts())
      assert.is_not_nil(files["src/main.cpp"])
      assert.is_nil(files["main.cpp"])
      assert.is_true(files["src/main.cpp"]:find("iostream") ~= nil)
    end)

    it("puts main.c in src/ for C executable", function()
      local files = templates.source_files(base_opts({ language = "C", standard = "c17" }))
      assert.is_not_nil(files["src/main.c"])
      assert.is_true(files["src/main.c"]:find("stdio") ~= nil)
    end)

    it("puts header in include/ and source in src/ for static library", function()
      local files = templates.source_files(base_opts({ project_type = "Static Library" }))
      assert.is_not_nil(files["include/testproj.hpp"])
      assert.is_not_nil(files["src/testproj.cpp"])
      assert.is_nil(files["testproj.hpp"])
      assert.is_nil(files["testproj.cpp"])
      assert.is_true(files["include/testproj.hpp"]:find("TESTPROJ_HPP") ~= nil)
    end)

    it("puts header in include/ for header-only library", function()
      local files = templates.source_files(base_opts({ project_type = "Header-only Library" }))
      assert.is_not_nil(files["include/testproj.hpp"])
      assert.is_nil(files["src/testproj.cpp"])
      assert.is_true(files["include/testproj.hpp"]:find("inline") ~= nil)
    end)

    it("generates stb-style header in include/ for C header-only", function()
      local files = templates.source_files(base_opts({
        language = "C",
        standard = "c17",
        project_type = "Header-only Library",
      }))
      assert.is_not_nil(files["include/testproj.h"])
      assert.is_true(files["include/testproj.h"]:find("IMPLEMENTATION") ~= nil)
    end)

    it("puts lib in include/+src/ and main in src/ for lib+exe", function()
      local files = templates.source_files(base_opts({ project_type = "Library + Executable" }))
      assert.is_not_nil(files["include/testproj.hpp"])
      assert.is_not_nil(files["src/testproj.cpp"])
      assert.is_not_nil(files["src/main.cpp"])
      assert.is_true(files["src/main.cpp"]:find('#include "testproj.hpp"') ~= nil)
    end)
  end)

  -- ── Full generate ─────────────────────────────────────────────

  describe("generate", function()
    it("includes .gitignore when requested", function()
      local files = templates.generate(base_opts({ gitignore = true }))
      assert.is_not_nil(files[".gitignore"])
    end)

    it("excludes .gitignore when not requested", function()
      local files = templates.generate(base_opts({ gitignore = false }))
      assert.is_nil(files[".gitignore"])
    end)

    it("returns 3 files for executable without gitignore", function()
      local files = templates.generate(base_opts())
      local count = 0
      for _ in pairs(files) do
        count = count + 1
      end
      -- CMakeLists.txt + src/main.cpp + .clangd
      assert.equals(3, count)
    end)

    it("returns 4 files for static library without gitignore", function()
      local files = templates.generate(base_opts({ project_type = "Static Library" }))
      local count = 0
      for _ in pairs(files) do
        count = count + 1
      end
      -- CMakeLists.txt + include/testproj.hpp + src/testproj.cpp + .clangd
      assert.equals(4, count)
    end)

    it("returns 5 files for lib+exe without gitignore", function()
      local files = templates.generate(base_opts({ project_type = "Library + Executable" }))
      local count = 0
      for _ in pairs(files) do
        count = count + 1
      end
      -- CMakeLists.txt + include/testproj.hpp + src/testproj.cpp + src/main.cpp + .clangd
      assert.equals(5, count)
    end)
  end)
end)
