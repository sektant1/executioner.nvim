describe('utils.split_args', function()
  local utils = require 'executioner.utils'

  it('splits plain args', function()
    assert.same({ 'a', 'b', 'c' }, utils.split_args 'a b c')
  end)

  it('returns empty for nil/empty', function()
    assert.same({}, utils.split_args(nil))
    assert.same({}, utils.split_args '')
  end)

  it('honors double quotes', function()
    assert.same({ '--msg', 'hello world' }, utils.split_args '--msg "hello world"')
  end)

  it('honors single quotes', function()
    assert.same({ 'a', 'b c', 'd' }, utils.split_args "a 'b c' d")
  end)

  it('collapses multiple spaces', function()
    assert.same({ 'a', 'b' }, utils.split_args 'a    b')
  end)
end)

describe('utils.display_name', function()
  local utils = require 'executioner.utils'

  it('strips extension', function()
    assert.equals('run', utils.display_name '/tmp/run.sh')
  end)

  it('keeps spaces', function()
    assert.equals('compile docs', utils.display_name '/tmp/compile docs.sh')
  end)

  it('handles no extension', function()
    assert.equals('Makefile', utils.display_name '/tmp/Makefile')
  end)
end)
