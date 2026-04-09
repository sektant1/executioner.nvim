local helpers = require("tests.exec_helpers")

describe("health", function()
  before_each(function()
    package.loaded["executioner.health"] = nil
    package.loaded["executioner.config"] = nil
  end)

  it("check() runs without error", function()
    helpers.reset_config()
    local health = require("executioner.health")
    assert.has_no.errors(function()
      health.check()
    end)
  end)

  it("reports missing scripts_dir as warning", function()
    helpers.reset_config({ scripts_dir = "/nonexistent/xyz" })
    local health = require("executioner.health")
    local reports = {}
    local orig_warn = vim.health.warn
    vim.health.warn = function(msg)
      table.insert(reports, msg)
    end
    health.check()
    vim.health.warn = orig_warn
    local found = false
    for _, msg in ipairs(reports) do
      if msg:match("scripts_dir does not exist") then
        found = true
      end
    end
    assert.is_true(found)
  end)

  it("reports existing scripts_dir as ok", function()
    local root = helpers.tmpdir()
    helpers.reset_config({ scripts_dir = root })
    local health = require("executioner.health")
    local reports = {}
    local orig_ok = vim.health.ok
    vim.health.ok = function(msg)
      table.insert(reports, msg)
    end
    health.check()
    vim.health.ok = orig_ok
    local found = false
    for _, msg in ipairs(reports) do
      if msg:match("scripts_dir exists") then
        found = true
      end
    end
    assert.is_true(found)
  end)
end)
