local helpers = require("tests.exec_helpers")

describe("scanner", function()
  local root

  before_each(function()
    root = helpers.make_fixture()
    package.loaded["executioner.scanner"] = nil
  end)

  it("finds scripts by extension and executable bit", function()
    helpers.reset_config({ scripts_dir = root })
    local scripts = require("executioner.scanner").scan()
    local names = vim.tbl_map(function(s)
      return s.name
    end, scripts)
    assert.is_true(vim.tbl_contains(names, "run"))
    assert.is_true(vim.tbl_contains(names, "compile"))
    assert.is_true(vim.tbl_contains(names, "compile docs"))
  end)

  it("strips extensions in display name", function()
    helpers.reset_config({ scripts_dir = root })
    local scripts = require("executioner.scanner").scan()
    for _, s in ipairs(scripts) do
      assert.is_nil(s.name:match("%.[^.]+$"), "name should have no ext: " .. s.name)
    end
  end)

  it("ignores README and plain text", function()
    helpers.reset_config({ scripts_dir = root })
    local names = vim.tbl_map(function(s)
      return s.name
    end, require("executioner.scanner").scan())
    assert.is_false(vim.tbl_contains(names, "README"))
    assert.is_false(vim.tbl_contains(names, "plain"))
  end)

  it("respects ignore list (node_modules)", function()
    helpers.reset_config({ scripts_dir = root, recursive = true, max_depth = 5 })
    local paths = vim.tbl_map(function(s)
      return s.path
    end, require("executioner.scanner").scan())
    for _, p in ipairs(paths) do
      assert.is_nil(p:match("node_modules"), "should skip node_modules: " .. p)
    end
  end)

  it("non-recursive skips nested dirs", function()
    helpers.reset_config({ scripts_dir = root, recursive = false })
    local names = vim.tbl_map(function(s)
      return s.name
    end, require("executioner.scanner").scan())
    assert.is_false(vim.tbl_contains(names, "deep"))
  end)

  it("recursive finds nested scripts", function()
    helpers.reset_config({ scripts_dir = root, recursive = true, max_depth = 3 })
    local names = vim.tbl_map(function(s)
      return s.name
    end, require("executioner.scanner").scan())
    assert.is_true(vim.tbl_contains(names, "deep"))
  end)

  it("returns empty on missing dir without crashing", function()
    helpers.reset_config({ scripts_dir = "/nonexistent/path/xyz" })
    local orig = vim.notify
    vim.notify = function() end
    local result = require("executioner.scanner").scan()
    vim.notify = orig
    assert.same({}, result)
  end)

  it("sorts results alphabetically", function()
    helpers.reset_config({ scripts_dir = root })
    local scripts = require("executioner.scanner").scan()
    for i = 2, #scripts do
      assert.is_true(scripts[i - 1].name:lower() <= scripts[i].name:lower())
    end
  end)
end)
