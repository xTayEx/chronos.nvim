local M = {}

M.notify = function(msg, type, opts)
  opts = opts or {}
  vim.schedule(function()
    vim.notify(msg, type, vim.tbl_extend("force", { title = "chronos.nvim" }, opts))
  end)
end

---@param time string
M.parse_time = function(time)
  local pattern = "^(%d+):(%d+)$"
  local hour, min = time:match(pattern)

  if not hour or not min then
    M.notify("Invalid time format. Use HH:MM", vim.log.levels.ERROR)
    return nil
  end

  hour, min = tonumber(hour), tonumber(min)

  if hour < 0 or hour >= 24 or min < 0 or min >= 60 then
    M.notify("Invalid time value", vim.log.levels.ERROR)
    return nil
  end

  local now = os.date("*t")
  local ret = os.time({
    year = now.year,
    month = now.month,
    day = now.day,
    hour = hour,
    min = min,
    sec = 0,
  })
  vim.print("after parse: " .. ret)
  return ret
end

return M
