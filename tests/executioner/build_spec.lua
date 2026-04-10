local helpers = require("tests.exec_helpers")

describe("build", function()
  local build

  before_each(function()
    package.loaded["executioner.build"] = nil
    package.loaded["executioner.build.detect"] = nil
    package.loaded["executioner.build.cmake"] = nil
    package.loaded["executioner.build.make"] = nil
    package.loaded["executioner.build.meson"] = nil
    package.loaded["executioner.config"] = nil
    package.loaded["executioner.terminal"] = nil
    helpers.reset_config()
    build = require("executioner.build")
  end)

  it("configure warns when no build system detected", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local warned = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("No build system detected") then
        warned = true
      end
    end
    build.configure()
    vim.notify = orig
    vim.cmd("cd " .. orig_cwd)
    assert.is_true(warned)
  end)

  it("configure notifies for make (no configure step)", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local notified = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("does not have a configure step") then
        notified = true
      end
    end
    build.configure()
    vim.notify = orig
    vim.cmd("cd " .. orig_cwd)
    assert.is_true(notified)
  end)

  it("build warns when no build system detected", function()
    local root = helpers.tmpdir()
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)

    local warned = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("No build system detected") then
        warned = true
      end
    end
    build.build()
    vim.notify = orig
    vim.cmd("cd " .. orig_cwd)
    assert.is_true(warned)
  end)

  it("build_last warns when no previous target", function()
    build._last = nil
    local warned = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("No previous build target") then
        warned = true
      end
    end
    build.build_last()
    vim.notify = orig
    assert.is_true(warned)
  end)

  it("build with direct target runs immediately", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", "all:\n\techo hi\ntest:\n\techo test\n")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config()
    package.loaded["executioner.build"] = nil
    build = require("executioner.build")

    -- Stub terminal.run
    local captured_cmd
    local term = require("executioner.terminal")
    local orig_run = term.run
    term.run = function(cmd)
      captured_cmd = cmd
    end

    build.build(nil, "test")

    term.run = orig_run
    vim.cmd("cd " .. orig_cwd)

    assert.is_not_nil(captured_cmd)
    assert.equals("make", captured_cmd[1])
    assert.equals("test", captured_cmd[2])
  end)

  it("build_last replays last target", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config()
    package.loaded["executioner.build"] = nil
    build = require("executioner.build")

    -- Stub terminal.run
    local captured_cmds = {}
    local term = require("executioner.terminal")
    local orig_run = term.run
    term.run = function(cmd)
      table.insert(captured_cmds, cmd)
    end

    build.build(nil, "all")
    assert.is_not_nil(build._last)
    assert.equals("all", build._last.target)

    build.build_last()
    assert.equals(2, #captured_cmds)
    assert.equals("make", captured_cmds[2][1])
    assert.equals("all", captured_cmds[2][2])

    term.run = orig_run
    vim.cmd("cd " .. orig_cwd)
  end)

  it("complete_targets returns list of strings", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", ".PHONY: test lint\ntest:\n\techo t\nlint:\n\techo l\n")
    local orig_cwd = vim.fn.getcwd()
    vim.cmd("cd " .. root)
    helpers.reset_config()
    package.loaded["executioner.build"] = nil
    build = require("executioner.build")

    local targets = build.complete_targets()
    vim.cmd("cd " .. orig_cwd)

    assert.is_table(targets)
    assert.is_true(vim.tbl_contains(targets, "test"))
    assert.is_true(vim.tbl_contains(targets, "lint"))
  end)
end)
