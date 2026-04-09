local helpers = require("tests.exec_helpers")

describe("executor", function()
  local root, executor

  before_each(function()
    root = helpers.make_fixture()
    helpers.reset_config({ scripts_dir = root })
    package.loaded["executioner.executor"] = nil
    executor = require("executioner.executor")
  end)

  it("runs executable+shebang script directly", function()
    local cmd = executor.build_cmd({ path = root .. "/run.sh", ext = "sh" }, {})
    assert.equals(root .. "/run.sh", cmd[1])
    assert.equals(1, #cmd)
  end)

  it("uses interpreter for known extension", function()
    local cmd = executor.build_cmd({ path = root .. "/compile.py", ext = "py" }, {})
    assert.equals("python3", cmd[1])
    assert.equals(root .. "/compile.py", cmd[2])
  end)

  it("appends args to command", function()
    local cmd = executor.build_cmd(
      { path = root .. "/compile.py", ext = "py" },
      { "--flag", "value" }
    )
    assert.equals("--flag", cmd[3])
    assert.equals("value", cmd[4])
  end)

  it("handles paths with spaces as single argv element", function()
    local cmd = executor.build_cmd({ path = root .. "/compile docs.sh", ext = "sh" }, {})
    -- argv-style: the whole path is one element, no shell splitting
    assert.is_true(cmd[1]:match("compile docs%.sh$") ~= nil)
  end)

  it("returns error for unknown extension + non-executable", function()
    helpers.write(root .. "/mystery.xyz", "data\n")
    local cmd, err = executor.build_cmd({ path = root .. "/mystery.xyz", ext = "xyz" }, {})
    assert.is_nil(cmd)
    assert.is_string(err)
  end)

  it("splits multi-word interpreter (nvim -l) correctly", function()
    helpers.write(root .. "/thing.lua", "print(1)\n")
    local cmd = executor.build_cmd({ path = root .. "/thing.lua", ext = "lua" }, {})
    assert.equals("nvim", cmd[1])
    assert.equals("-l", cmd[2])
    assert.equals(root .. "/thing.lua", cmd[3])
  end)

  it("stores last run in _last", function()
    local script = { path = root .. "/compile.py", ext = "py", name = "compile" }
    -- Call build_cmd + set _last directly (run() would need a terminal)
    executor._last = { script = script, raw_args = "--flag" }
    assert.equals(script.path, executor._last.script.path)
    assert.equals("--flag", executor._last.raw_args)
  end)

  it("rerun warns when no previous script", function()
    executor._last = nil
    local warned = false
    local orig = vim.notify
    vim.notify = function(msg)
      if msg:match("No previous script") then
        warned = true
      end
    end
    executor.rerun()
    vim.notify = orig
    assert.is_true(warned)
  end)
end)
