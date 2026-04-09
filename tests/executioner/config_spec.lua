local helpers = require("tests.exec_helpers")

describe("config", function()
  before_each(function()
    package.loaded["executioner.config"] = nil
  end)

  it("loads defaults without user opts", function()
    local c = require("executioner.config")
    c.setup()
    assert.equals("float", c.options.terminal.type)
    assert.equals(false, c.options.recursive)
    assert.is_table(c.options.extensions)
  end)

  it("deep-merges user opts", function()
    local c = require("executioner.config")
    c.setup({ terminal = { type = "split" }, extensions = { rs = "cargo run --" } })
    assert.equals("split", c.options.terminal.type)
    assert.equals("rounded", c.options.terminal.float.border) -- preserved
    assert.equals("cargo run --", c.options.extensions.rs)
    assert.equals("bash", c.options.extensions.sh) -- preserved
  end)

  it("resolves '.' to cwd", function()
    local c = helpers.reset_config({ scripts_dir = "." })
    assert.equals(
      vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", ""),
      c.resolved_scripts_dir()
    )
  end)

  it("resolves function scripts_dir", function()
    local c = helpers.reset_config({
      scripts_dir = function()
        return "/tmp"
      end,
    })
    assert.equals("/tmp", c.resolved_scripts_dir())
  end)
end)
