local M = {}

function M.notify(msg, level)
  vim.notify('[executioner] ' .. msg, level or vim.log.levels.INFO)
end

function M.err(msg)
  M.notify(msg, vim.log.levels.ERROR)
end
function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

---Strip extension & parent dirs: "/a/b/compile docs.sh" -> "compile docs"
function M.display_name(path)
  local name = vim.fn.fnamemodify(path, ':t')
  return (name:gsub('%.[^.]+$', ''))
end

---True if file has +x (Unix) or is a known script on Windows.
function M.is_executable(path)
  return vim.fn.executable(path) == 1
end

---Read first line to detect shebang.
function M.read_shebang(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local line = f:read '*l' or ''
  f:close()
  return line:match '^#!' and line or nil
end

---Split a raw args string into a list, honoring quotes.
function M.split_args(str)
  if not str or str == '' then
    return {}
  end
  local out, cur, in_q = {}, {}, nil
  for c in str:gmatch '.' do
    if in_q then
      if c == in_q then
        in_q = nil
      else
        table.insert(cur, c)
      end
    elseif c == '"' or c == "'" then
      in_q = c
    elseif c == ' ' then
      if #cur > 0 then
        table.insert(out, table.concat(cur))
        cur = {}
      end
    else
      table.insert(cur, c)
    end
  end
  if #cur > 0 then
    table.insert(out, table.concat(cur))
  end
  return out
end

return M
