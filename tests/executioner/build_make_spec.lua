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
    make.project_root = "/tmp/project"
    local cmd = make.build_cmd(nil)
    assert.same({ "make", "-C", "/tmp/project" }, cmd)
  end)

  it("build_cmd with target", function()
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    make.project_root = "/tmp/project"
    local cmd = make.build_cmd("test")
    assert.same({ "make", "-C", "/tmp/project", "test" }, cmd)
  end)

  it("build_cmd includes extra args before target", function()
    helpers.reset_config({ build = { make = { args = { "-j4" } } } })
    make = require("executioner.build.make")
    make.project_root = "/tmp/project"
    local cmd = make.build_cmd("all")
    assert.same({ "make", "-C", "/tmp/project", "-j4", "all" }, cmd)
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
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    make.project_root = root
    local targets = make.targets()

    assert.is_true(vim.tbl_contains(targets, "test"))
    assert.is_true(vim.tbl_contains(targets, "lint"))
    assert.is_true(vim.tbl_contains(targets, "all"))
    assert.is_true(vim.tbl_contains(targets, "clean"))
  end)

  it("skips variable assignments that look like targets", function()
    helpers.write(root .. "/Makefile", "CC := gcc\nall:\n\techo hi\n")
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    make.project_root = root
    local targets = make.targets()

    assert.is_false(vim.tbl_contains(targets, "CC"))
    assert.is_true(vim.tbl_contains(targets, "all"))
  end)

  it("returns empty when no Makefile", function()
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    make.project_root = root
    local targets = make.targets()
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
    helpers.reset_config({ build = { make = { args = {} } } })
    make = require("executioner.build.make")
    make.project_root = root
    local targets = make.targets()

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
