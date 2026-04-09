local helpers = require("tests.exec_helpers")

describe("terminal", function()
  local terminal

  before_each(function()
    helpers.reset_config()
    package.loaded["executioner.terminal"] = nil
    terminal = require("executioner.terminal")
  end)

  it("errors on unknown terminal type", function()
    helpers.reset_config({ terminal = { type = "bogus" } })
    package.loaded["executioner.terminal"] = nil
    terminal = require("executioner.terminal")

    local errored = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("Unknown terminal%.type") then
        errored = true
      end
    end
    terminal.run({ "echo", "hi" }, { name = "test", path = "/tmp/test.sh" })
    vim.notify = orig
    assert.is_true(errored)
  end)

  it("dispatches to split without error", function()
    helpers.reset_config({ terminal = { start_insert = false } })
    package.loaded["executioner.terminal"] = nil
    terminal = require("executioner.terminal")

    assert.has_no.errors(function()
      terminal.run({ "echo", "hello" }, { name = "test", path = "/tmp/test.sh" })
    end)
    -- cleanup: close the split
    vim.cmd("only")
  end)

  it("binds q keymap on terminal buffer", function()
    helpers.reset_config({ terminal = { start_insert = false } })
    package.loaded["executioner.terminal"] = nil
    terminal = require("executioner.terminal")

    terminal.run({ "echo", "hello" }, { name = "test", path = "/tmp/test.sh" })
    local buf = vim.api.nvim_get_current_buf()
    local maps = vim.api.nvim_buf_get_keymap(buf, "n")
    local has_q = false
    for _, m in ipairs(maps) do
      if m.lhs == "q" then
        has_q = true
      end
    end
    assert.is_true(has_q)
    vim.cmd("only")
  end)

  it("on_exit callback fires", function()
    local exit_code = nil
    helpers.reset_config({
      terminal = { start_insert = false },
      on_exit = function(code)
        exit_code = code
      end,
    })
    package.loaded["executioner.terminal"] = nil
    terminal = require("executioner.terminal")

    terminal.run({ "true" }, { name = "test", path = "/tmp/test.sh" })
    -- wait for job to finish
    vim.wait(2000, function()
      return exit_code ~= nil
    end, 50)
    assert.equals(0, exit_code)
    vim.cmd("only")
  end)
end)
