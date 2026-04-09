local M = {}

local uv = vim.uv or vim.loop

function M.tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  return dir
end

function M.write(path, contents, executable)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = assert(io.open(path, 'w'))
  f:write(contents)
  f:close()
  if executable then
    uv.fs_chmod(path, 493) -- 0755
  end
end

function M.make_fixture()
  local root = M.tmpdir()
  M.write(root .. '/run.sh', '#!/usr/bin/env bash\necho run\n', true)
  M.write(root .. '/compile.py', "print('compile')\n")
  M.write(root .. '/compile docs.sh', '#!/bin/bash\necho docs\n', true)
  M.write(root .. '/README.md', '# readme\n')
  M.write(root .. '/plain.txt', 'nope\n')
  M.write(root .. '/node_modules/bad.sh', '#!/bin/sh\n', true)
  M.write(root .. '/nested/deep.py', "print('deep')\n")
  return root
end

function M.reset_config(overrides)
  package.loaded['executioner.config'] = nil
  local config = require 'executioner.config'
  config.setup(overrides or {})
  return config
end

return M
