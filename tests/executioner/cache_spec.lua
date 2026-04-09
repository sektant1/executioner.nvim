local helpers = require("tests.exec_helpers")

describe("cache", function()
  local cache
  local cache_file

  before_each(function()
    package.loaded["executioner.cache"] = nil
    cache = require("executioner.cache")
    cache_file = vim.fn.stdpath("state") .. "/executioner_args.json"
    if vim.fn.filereadable(cache_file) == 1 then
      os.remove(cache_file)
    end
  end)

  after_each(function()
    if vim.fn.filereadable(cache_file) == 1 then
      os.remove(cache_file)
    end
  end)

  it("returns empty string for unknown script", function()
    assert.equals("", cache.get("/nonexistent/script.sh"))
  end)

  it("persists and retrieves args", function()
    cache.set("/tmp/run.sh", "--verbose --dry-run")
    assert.equals("--verbose --dry-run", cache.get("/tmp/run.sh"))
  end)

  it("stores args per script independently", function()
    cache.set("/tmp/a.sh", "arg-a")
    cache.set("/tmp/b.sh", "arg-b")
    assert.equals("arg-a", cache.get("/tmp/a.sh"))
    assert.equals("arg-b", cache.get("/tmp/b.sh"))
  end)

  it("overwrites previous args for same script", function()
    cache.set("/tmp/run.sh", "old")
    cache.set("/tmp/run.sh", "new")
    assert.equals("new", cache.get("/tmp/run.sh"))
  end)

  it("survives module reload (reads from disk)", function()
    cache.set("/tmp/run.sh", "persisted")
    package.loaded["executioner.cache"] = nil
    local fresh = require("executioner.cache")
    assert.equals("persisted", fresh.get("/tmp/run.sh"))
  end)

  it("handles corrupted cache file gracefully", function()
    vim.fn.mkdir(vim.fn.fnamemodify(cache_file, ":h"), "p")
    local f = io.open(cache_file, "w")
    f:write("not valid json{{{")
    f:close()
    assert.equals("", cache.get("/tmp/anything.sh"))
  end)
end)
