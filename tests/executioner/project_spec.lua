local helpers = require("tests.exec_helpers")

describe("project", function()
  local project

  before_each(function()
    package.loaded["executioner.project"] = nil
    package.loaded["executioner.project.templates"] = nil
    project = require("executioner.project")
  end)

  it("_generate creates src/ dir and files for executable", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "mytest",
      build_system = "CMake",
      language = "C++",
      project_type = "Executable",
      standard = "c++17",
      gitignore = true,
      git_init = false,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.isdirectory(root .. "/mytest"))
    assert.equals(1, vim.fn.isdirectory(root .. "/mytest/src"))
    assert.equals(1, vim.fn.filereadable(root .. "/mytest/CMakeLists.txt"))
    assert.equals(1, vim.fn.filereadable(root .. "/mytest/src/main.cpp"))
    assert.equals(1, vim.fn.filereadable(root .. "/mytest/.gitignore"))
  end)

  it("_generate creates include/ and src/ for Make static library", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "makeproj",
      build_system = "Make",
      language = "C",
      project_type = "Static Library",
      standard = "c17",
      gitignore = false,
      git_init = false,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.filereadable(root .. "/makeproj/Makefile"))
    assert.equals(1, vim.fn.isdirectory(root .. "/makeproj/src"))
    assert.equals(1, vim.fn.isdirectory(root .. "/makeproj/include"))
    assert.equals(1, vim.fn.filereadable(root .. "/makeproj/src/makeproj.c"))
    assert.equals(1, vim.fn.filereadable(root .. "/makeproj/include/makeproj.h"))
  end)

  it("_generate creates only include/ for header-only library", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "hdrlib",
      build_system = "CMake",
      language = "C++",
      project_type = "Header-only Library",
      standard = "c++20",
      gitignore = false,
      git_init = false,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.isdirectory(root .. "/hdrlib/include"))
    assert.equals(1, vim.fn.filereadable(root .. "/hdrlib/include/hdrlib.hpp"))
    assert.equals(0, vim.fn.isdirectory(root .. "/hdrlib/src"))
  end)

  it("_generate creates include/ and src/ for Meson shared library", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "mesonproj",
      build_system = "Meson",
      language = "C++",
      project_type = "Shared Library",
      standard = "c++20",
      gitignore = false,
      git_init = false,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.filereadable(root .. "/mesonproj/meson.build"))
    assert.equals(1, vim.fn.filereadable(root .. "/mesonproj/src/mesonproj.cpp"))
    assert.equals(1, vim.fn.filereadable(root .. "/mesonproj/include/mesonproj.hpp"))
  end)

  it("_generate creates both src/ entries for lib+exe", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "combo",
      build_system = "CMake",
      language = "C",
      project_type = "Library + Executable",
      standard = "c17",
      gitignore = false,
      git_init = false,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.filereadable(root .. "/combo/CMakeLists.txt"))
    assert.equals(1, vim.fn.filereadable(root .. "/combo/include/combo.h"))
    assert.equals(1, vim.fn.filereadable(root .. "/combo/src/combo.c"))
    assert.equals(1, vim.fn.filereadable(root .. "/combo/src/main.c"))
  end)

  it("_generate warns on existing directory", function()
    local root = helpers.tmpdir()
    vim.fn.mkdir(root .. "/existing", "p")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local warned = false
    local orig_notify = vim.notify
    vim.notify = function(msg)
      if msg:match("already exists") then
        warned = true
      end
    end

    project._generate({
      name = "existing",
      build_system = "CMake",
      language = "C",
      project_type = "Executable",
      standard = "c17",
      gitignore = false,
      git_init = false,
    })

    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)
    assert.is_true(warned)
  end)

  it("_generate initializes git when requested", function()
    if vim.fn.executable("git") ~= 1 then
      return
    end

    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local orig_select = vim.ui.select
    vim.ui.select = function(_, _, cb)
      cb("No")
    end
    local orig_notify = vim.notify
    vim.notify = function() end

    project._generate({
      name = "gitproj",
      build_system = "CMake",
      language = "C++",
      project_type = "Executable",
      standard = "c++17",
      gitignore = true,
      git_init = true,
    })

    vim.ui.select = orig_select
    vim.notify = orig_notify
    vim.cmd("cd " .. orig_cwd)

    assert.equals(1, vim.fn.isdirectory(root .. "/gitproj/.git"))
  end)
end)
