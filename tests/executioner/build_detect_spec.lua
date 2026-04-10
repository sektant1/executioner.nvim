local helpers = require("tests.exec_helpers")

describe("build.detect", function()
  local detect

  before_each(function()
    package.loaded["executioner.build.detect"] = nil
    detect = require("executioner.build.detect")
  end)

  it("detects CMakeLists.txt as cmake", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/CMakeLists.txt", "cmake_minimum_required(VERSION 3.20)\n")
    assert.equals("cmake", detect.detect(root))
  end)

  it("detects Makefile as make", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    assert.equals("make", detect.detect(root))
  end)

  it("detects GNUmakefile as make", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/GNUmakefile", "all:\n\techo hi\n")
    assert.equals("make", detect.detect(root))
  end)

  it("detects meson.build as meson", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/meson.build", "project('test', 'c')\n")
    assert.equals("meson", detect.detect(root))
  end)

  it("returns nil when nothing found", function()
    local root = helpers.tmpdir()
    assert.is_nil(detect.detect(root))
  end)

  it("prefers cmake over make when both present", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/CMakeLists.txt", "cmake_minimum_required(VERSION 3.20)\n")
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    assert.equals("cmake", detect.detect(root))
  end)

  it("prefers meson over make when both present", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/meson.build", "project('test', 'c')\n")
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    assert.equals("meson", detect.detect(root))
  end)

  it("finds makefile path", function()
    local root = helpers.tmpdir()
    helpers.write(root .. "/Makefile", "all:\n\techo hi\n")
    assert.equals(root .. "/Makefile", detect.find_makefile(root))
  end)

  it("find_makefile returns nil when absent", function()
    local root = helpers.tmpdir()
    assert.is_nil(detect.find_makefile(root))
  end)
end)
