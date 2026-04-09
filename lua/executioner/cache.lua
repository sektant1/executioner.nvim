local M = {}

local function cache_path()
  return vim.fn.stdpath 'state' .. '/executioner_args.json'
end

local function read_all()
  local f = io.open(cache_path(), 'r')
  if not f then
    return {}
  end
  local raw = f:read '*a'
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == 'table' then
    return data
  end
  return {}
end

local function write_all(data)
  local dir = vim.fn.fnamemodify(cache_path(), ':h')
  vim.fn.mkdir(dir, 'p')
  local f = io.open(cache_path(), 'w')
  if not f then
    return
  end
  f:write(vim.json.encode(data))
  f:close()
end

function M.get(script_path)
  return read_all()[script_path] or ''
end

function M.set(script_path, args)
  local data = read_all()
  data[script_path] = args
  write_all(data)
end

return M
