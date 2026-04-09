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
end)
