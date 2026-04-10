local helpers = require("tests.exec_helpers")

describe("build.meson", function()
  local meson

  before_each(function()
    package.loaded["executioner.build.meson"] = nil
    package.loaded["executioner.config"] = nil
  end)

  it("configure_cmd builds correct args", function()
    helpers.reset_config({ build = { meson = { build_dir = "builddir", setup_args = {} } } })
    meson = require("executioner.build.meson")
    meson.project_root = vim.fn.getcwd()
    local cmd = meson.configure_cmd()
    assert.equals("meson", cmd[1])
    assert.equals("setup", cmd[2])
    assert.is_true(cmd[3]:match("builddir$") ~= nil)
  end)

  it("configure_cmd appends setup_args", function()
    helpers.reset_config({
      build = { meson = { build_dir = "builddir", setup_args = { "--buildtype=release" } } },
    })
    meson = require("executioner.build.meson")
    meson.project_root = vim.fn.getcwd()
    local cmd = meson.configure_cmd()
    assert.is_true(vim.tbl_contains(cmd, "--buildtype=release"))
  end)

  it("build_cmd without target", function()
    helpers.reset_config({ build = { meson = { build_dir = "builddir", compile_args = {} } } })
    meson = require("executioner.build.meson")
    meson.project_root = vim.fn.getcwd()
    local cmd = meson.build_cmd(nil)
    assert.equals("meson", cmd[1])
    assert.equals("compile", cmd[2])
    assert.equals("-C", cmd[3])
    assert.equals(4, #cmd)
  end)

  it("build_cmd with target", function()
    helpers.reset_config({ build = { meson = { build_dir = "builddir", compile_args = {} } } })
    meson = require("executioner.build.meson")
    meson.project_root = vim.fn.getcwd()
    local cmd = meson.build_cmd("myapp")
    assert.equals("myapp", cmd[5])
  end)

  it("build_cmd appends compile_args", function()
    helpers.reset_config({
      build = { meson = { build_dir = "builddir", compile_args = { "-j8" } } },
    })
    meson = require("executioner.build.meson")
    meson.project_root = vim.fn.getcwd()
    local cmd = meson.build_cmd("myapp")
    assert.is_true(vim.tbl_contains(cmd, "-j8"))
  end)

  it("is_configured returns false on empty dir", function()
    helpers.reset_config({ build = { meson = { build_dir = "/nonexistent/xyz" } } })
    meson = require("executioner.build.meson")
    assert.is_false(meson.is_configured())
  end)

  it("is_configured returns true when build.ninja exists", function()
    local root = helpers.tmpdir()
    local bdir = root .. "/builddir"
    vim.fn.mkdir(bdir, "p")
    helpers.write(bdir .. "/build.ninja", "# fake\n")
    helpers.reset_config({ build = { meson = { build_dir = bdir } } })
    meson = require("executioner.build.meson")
    assert.is_true(meson.is_configured())
  end)

  it("targets returns empty when not configured", function()
    helpers.reset_config({ build = { meson = { build_dir = "/nonexistent/xyz" } } })
    meson = require("executioner.build.meson")
    assert.same({}, meson.targets())
  end)
end)
