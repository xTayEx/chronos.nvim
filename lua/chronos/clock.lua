local M = {}

local Symbol = require("chronos.clock_symbols").Symbol

---@param time_str string
---@return table
local build_clock_symbols = function(time_str)
  local time_symbols = {}
  for i = 1, #time_str do
    local ch = time_str:sub(i, i)
    time_symbols[#time_symbols + 1] = Symbol:new(ch, {})
  end

  local max_height = 1
  for _, symbol in ipairs(time_symbols) do
    local dimension = symbol:get_dimensions()
    max_height = vim.fn.max({max_height, dimension.height})
  end

  for _, symbol in ipairs(time_symbols) do
    local dimension = symbol:get_dimensions()
    local width = dimension.width

    symbol:pad_to_cell(width, max_height)
  end


end

---@class ClockOpts
---@field time_format string
---@filed style string

---@class Clock
local Clock = {}

function Clock:new(o)
  ---@type ClockOpts
  self.opts = o or {
    time_format = "%H:%M",
    style = "normal",
  }
  o = o or {}
  self.__index = self
  return setmetatable(o, self)
end

---@param time_symbols string[]
---@param clock_opts ClockOpts
---@return boolean ok
---@return integer win_id
---@return integer buf_id
function Clock:open_clock_win(time_symbols, win_width, win_height, clock_opts)
  local buf_id = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]

  -- the window should be unmodifiable and readonly
  ---@diagnostic disable-next-line: param-type-mismatch
  local ok, win_id = pcall(vim.api.nvim_open_win, buf_id, false, {
    relative = "editor",
    width = win_width,
    height = win_height,
    col = ui.width / 2 - win_width / 2,
    row = ui.height / 2 - win_height / 2,
    anchor = "NW",
    style = "minimal",
    border = "rounded",
  })

  if not ok then
    return false, -1, -1
  end

  -- vim.print("lines: " .. lines)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, time_symbols)

  return true, win_id, buf_id
end

---@param buf_id integer
function Clock:update_clock_win(buf_id)
  if not vim.api.nvim_buf_is_valid(buf_id) then
    return
  end

  local lines = build_clock_symbols(tostring(os.date(self.opts.time_format)))
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)
end

function Clock:cancle()
  if self.timer ~= nil then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
    vim.api.nvim_win_close(self.win_id, true)
    vim.api.nvim_buf_delete(self.buf_id, { force = true })
  end
end

function Clock:start()
  local time_symbols, win_width, win_height =
      build_clock_symbols(tostring(os.date(self.opts.time_format)))
  local ok, win_id, buf_id = self:open_clock_win(time_symbols, win_width, win_height, self.opts)
  self.win_id = win_id
  self.buf_id = buf_id

  if not ok then
    vim.notify("Failed to open clock window", vim.log.levels.ERROR, { title = "Chronos.nvim" })
  end
  local uv = vim.uv or vim.loop
  self.timer = uv.new_timer()
  self.timer:start(
    (60 - tonumber(os.date("%S"))) * 1000,
    60000,
    vim.schedule_wrap(function()
      self:update_clock_win(buf_id)
    end)
  )
end

local clock = Clock:new()

M.clock = clock

return M
