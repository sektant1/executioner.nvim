local helpers = require("tests.exec_helpers")

describe("build.make", function()
  local make, root

  before_each(function()
    package.loaded["executioner.build.make"] = nil
    package.loaded["executioner.build.detect"] = nil
    package.loaded["executioner.config"] = nil
    root = helpers.tmpdir()
  end)

  it("build_cmd without target", function()
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local cmd = make.build_cmd(nil)
    assert.same({ "make" }, cmd)
  end)

  it("build_cmd with target", function()
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local cmd = make.build_cmd("test")
    assert.same({ "make", "test" }, cmd)
  end)

  it("build_cmd includes extra args before target", function()
    helpers.reset_config({ build = { make = { args = { "-j4" } } } })
    make = require("executioner.build.make")
    local cmd = make.build_cmd("all")
    assert.same({ "make", "-j4", "all" }, cmd)
  end)

  it("parses simple targets from Makefile", function()
    helpers.write(
      root .. "/Makefile",
      table.concat({
        ".PHONY: test lint",
        "",
        "all:",
        "\techo all",
        "",
        "test:",
        "\techo test",
        "",
        "lint:",
        "\tstylua --check .",
        "",
        "clean:",
        "\trm -rf build",
      }, "\n")
    )
    -- Chdir so the module finds the Makefile
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local targets = make.targets()
    vim.cmd("cd " .. orig_cwd)

    assert.is_true(vim.tbl_contains(targets, "test"))
    assert.is_true(vim.tbl_contains(targets, "lint"))
    assert.is_true(vim.tbl_contains(targets, "all"))
    assert.is_true(vim.tbl_contains(targets, "clean"))
  end)

  it("skips variable assignments that look like targets", function()
    helpers.write(root .. "/Makefile", "CC := gcc\nall:\n\techo hi\n")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local targets = make.targets()
    vim.cmd("cd " .. orig_cwd)

    assert.is_false(vim.tbl_contains(targets, "CC"))
    assert.is_true(vim.tbl_contains(targets, "all"))
  end)

  it("returns empty when no Makefile", function()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local targets = make.targets()
    vim.cmd("cd " .. orig_cwd)
    assert.same({}, targets)
  end)

  it("deduplicates PHONY and rule targets", function()
    helpers.write(
      root .. "/Makefile",
      table.concat({
        ".PHONY: test",
        "",
        "test:",
        "\techo test",
      }, "\n")
    )
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    local targets = make.targets()
    vim.cmd("cd " .. orig_cwd)

    local count = 0
    for _, t in ipairs(targets) do
      if t == "test" then
        count = count + 1
      end
    end
    assert.equals(1, count)
  end)

  it("has no configure step", function()
    make = require("executioner.build.make")
    assert.is_nil(make.configure_cmd)
    assert.is_nil(make.is_configured)
  end)
end)
