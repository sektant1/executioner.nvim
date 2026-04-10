local helpers = require("tests.exec_helpers")

describe("build.cmake", function()
  local cmake

  before_each(function()
    package.loaded["executioner.build.cmake"] = nil
    package.loaded["executioner.config"] = nil
  end)

  it("configure_cmd builds correct args", function()
    helpers.reset_config({ build = { cmake = { build_dir = "build", configure_args = {} } } })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.configure_cmd()
    assert.equals("cmake", cmd[1])
    assert.equals("-B", cmd[2])
    assert.is_true(cmd[3]:match("build$") ~= nil)
    assert.equals("-S", cmd[4])
  end)

  it("configure_cmd includes generator when set", function()
    helpers.reset_config({
      build = { cmake = { build_dir = "build", generator = "Ninja", configure_args = {} } },
    })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.configure_cmd()
    local has_g = false
    for i, v in ipairs(cmd) do
      if v == "-G" and cmd[i + 1] == "Ninja" then
        has_g = true
      end
    end
    assert.is_true(has_g)
  end)

  it("configure_cmd appends extra args", function()
    helpers.reset_config({
      build = { cmake = { build_dir = "build", configure_args = { "-DCMAKE_BUILD_TYPE=Release" } } },
    })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.configure_cmd()
    assert.is_true(vim.tbl_contains(cmd, "-DCMAKE_BUILD_TYPE=Release"))
  end)

  it("build_cmd without target", function()
    helpers.reset_config({ build = { cmake = { build_dir = "build", build_args = {} } } })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.build_cmd(nil)
    assert.equals("cmake", cmd[1])
    assert.equals("--build", cmd[2])
    assert.equals(3, #cmd) -- no --target
  end)

  it("build_cmd with target", function()
    helpers.reset_config({ build = { cmake = { build_dir = "build", build_args = {} } } })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.build_cmd("myapp")
    assert.equals("--target", cmd[4])
    assert.equals("myapp", cmd[5])
  end)

  it("build_cmd appends build_args", function()
    helpers.reset_config({
      build = { cmake = { build_dir = "build", build_args = { "-j8" } } },
    })
    cmake = require("executioner.build.cmake")
    cmake.project_root = vim.fn.getcwd()
    local cmd = cmake.build_cmd("all")
    assert.is_true(vim.tbl_contains(cmd, "-j8"))
  end)

  it("is_configured returns false on empty dir", function()
    local root = helpers.tmpdir()
    helpers.reset_config({ build = { cmake = { build_dir = root .. "/build" } } })
    cmake = require("executioner.build.cmake")
    assert.is_false(cmake.is_configured())
  end)

  it("is_configured returns true when CMakeCache.txt exists", function()
    local root = helpers.tmpdir()
    local bdir = root .. "/build"
    vim.fn.mkdir(bdir, "p")
    helpers.write(bdir .. "/CMakeCache.txt", "# fake cache\n")
    helpers.reset_config({ build = { cmake = { build_dir = bdir } } })
    cmake = require("executioner.build.cmake")
    assert.is_true(cmake.is_configured())
  end)

  it("targets returns empty when not configured", function()
    helpers.reset_config({ build = { cmake = { build_dir = "/nonexistent/xyz" } } })
    cmake = require("executioner.build.cmake")
    assert.same({}, cmake.targets())
  end)
end)
