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

  it("rerun replays last script and args", function()
    local script = { path = root .. "/compile.py", ext = "py", name = "compile" }
    -- Stub terminal.run to capture what gets passed
    local captured_cmd, captured_script
    local terminal = require("executioner.terminal")
    local orig_run = terminal.run
    terminal.run = function(cmd, s)
      captured_cmd = cmd
      captured_script = s
    end

    executor.run(script, "--release")
    -- _last should be set
    assert.is_not_nil(executor._last)
    assert.equals("--release", executor._last.raw_args)

    -- Reset captures and rerun
    captured_cmd = nil
    captured_script = nil
    executor.rerun()

    assert.is_not_nil(captured_cmd)
    assert.equals("python3", captured_cmd[1])
    assert.equals(root .. "/compile.py", captured_cmd[2])
    assert.equals("--release", captured_cmd[3])
    assert.equals(script.path, captured_script.path)

    terminal.run = orig_run
  end)

  it("rerun updates _last on each run", function()
    local script_a = { path = root .. "/compile.py", ext = "py", name = "compile" }
    local script_b = { path = root .. "/run.sh", ext = "sh", name = "run" }

    -- Stub terminal
    local terminal = require("executioner.terminal")
    local orig_run = terminal.run
    terminal.run = function() end

    executor.run(script_a, "first")
    assert.equals(script_a.path, executor._last.script.path)
    assert.equals("first", executor._last.raw_args)

    executor.run(script_b, "second")
    assert.equals(script_b.path, executor._last.script.path)
    assert.equals("second", executor._last.raw_args)

    terminal.run = orig_run
  end)
end)
