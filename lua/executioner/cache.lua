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

local MAX_ENTRIES = 200

local function trim(data)
  local keys = vim.tbl_keys(data)
  if #keys <= MAX_ENTRIES then
    return
  end
  table.sort(keys)
  for i = 1, #keys - MAX_ENTRIES do
    data[keys[i]] = nil
  end
end

function M.set(script_path, args)
  local data = read_all()
  data[script_path] = args
  trim(data)
  write_all(data)
end

return M
