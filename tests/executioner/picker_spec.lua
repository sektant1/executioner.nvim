local helpers = require("tests.exec_helpers")

describe("picker", function()
  before_each(function()
    package.loaded["executioner.picker"] = nil
    package.loaded["executioner.scanner"] = nil
    package.loaded["executioner.config"] = nil
  end)

  it("loads without error when telescope is available", function()
    helpers.reset_config()
    assert.has_no.errors(function()
      require("executioner.picker")
    end)
  end)

  it("warns on empty scripts dir", function()
    local root = helpers.tmpdir()
    helpers.reset_config({ scripts_dir = root })
    local picker = require("executioner.picker")

    local warned = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("No scripts found") then
        warned = true
      end
    end
    picker.run()
    vim.notify = orig
    assert.is_true(warned)
  end)

  it("returns empty table when telescope is missing", function()
    -- Temporarily poison telescope require
    local orig = package.loaded["telescope"]
    local orig_preload = package.preload["telescope"]
    package.loaded["telescope"] = nil
    package.loaded["executioner.picker"] = nil
    package.preload["telescope"] = function()
      error("not found")
    end

    local errored = false
    local orig_notify = vim.notify
    vim.notify = function(msg)
      if msg:match("telescope.nvim is required") then
        errored = true
      end
    end

    local result = require("executioner.picker")
    vim.notify = orig_notify

    assert.is_table(result)
    assert.is_nil(result.run)
    assert.is_true(errored)

    -- Restore
    package.loaded["telescope"] = orig
    package.preload["telescope"] = orig_preload
    package.loaded["executioner.picker"] = nil
  end)
end)
