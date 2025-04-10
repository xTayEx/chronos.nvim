local M = {}

local Symbol = require("chronos.clock_symbols").Symbol
local concat_symbols = require("chronos.clock_symbols").concat_symbols
local digits = require("chronos.clock_symbols").digits
local colon = require("chronos.clock_symbols").colon
local DIGITS_MAX_WIDTH = require("chronos.clock_symbols").DIGITS_MAX_WIDTH

---@param time_str string
---@return table
---@return integer win_width
---@return integer win_height
local build_clock_display = function(time_str)
  local time_symbols = {}
  for i = 1, #time_str do
    local ch = time_str:sub(i, i)
    time_symbols[#time_symbols + 1] = Symbol:new(ch, digits, colon)
  end

  local max_height = 1
  for _, symbol in ipairs(time_symbols) do
    local dimension = symbol:get_dimensions()
    max_height = vim.fn.max({ max_height, dimension.height })
  end

  local win_width = 0
  for _, symbol in ipairs(time_symbols) do
    local dimension = symbol:get_dimensions()
    local symbol_width = dimension.width

    if DIGITS_MAX_WIDTH == symbol_width then
      symbol_width = symbol_width + 1
    else
      symbol_width = DIGITS_MAX_WIDTH
    end
    if symbol.ori_symbol ~= ":" then
      win_width = win_width + symbol_width
      symbol:pad_to_cell(symbol_width, max_height)
    else
      win_width = win_width + dimension.width + 1
      symbol:pad_to_cell(dimension.width + 1, max_height)
    end
  end
  local lines = concat_symbols(time_symbols)

  return lines, win_width, max_height
end

---@class ClockOpts
---@field time_format string
---@filed style string

---@class Clock
local Clock = {}

function Clock:new(o)
  ---@type ClockOpts
  self.opts = o or {
    time_format = "%H:%M:%S",
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

  --- TODO: the window should be unmodifiable and readonly
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

  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, time_symbols)

  return true, win_id, buf_id
end

---@param buf_id integer
function Clock:update_clock_win(buf_id)
  if not vim.api.nvim_buf_is_valid(buf_id) then
    return
  end

  local lines, _, _ = build_clock_display(tostring(os.date(self.opts.time_format)))
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)
end

function Clock:cancle()
  if self.timer ~= nil then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end

  if vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
  end

  if vim.api.nvim_buf_is_valid(self.buf_id) then
    vim.api.nvim_buf_delete(self.buf_id, { force = true })
  end
end

function Clock:start()
  local display, win_width, win_height =
    build_clock_display(tostring(os.date(self.opts.time_format)))
  local ok, win_id, buf_id = self:open_clock_win(display, win_width, win_height, self.opts)
  self.win_id = win_id
  self.buf_id = buf_id

  if not ok then
    vim.notify("Failed to open clock window", vim.log.levels.ERROR, { title = "Chronos.nvim" })
  end
  local uv = vim.uv or vim.loop
  self.timer = uv.new_timer()
  self.timer:start(
    0,
    -- (60 - tonumber(os.date("%S"))) * 1000,
    1000,
    vim.schedule_wrap(function()
      self:update_clock_win(buf_id)
    end)
  )
end

local clock = Clock:new()

M.clock = clock

return M
