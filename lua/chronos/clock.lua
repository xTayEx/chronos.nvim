local M = {}

local Symbol = require("chronos.clock_symbols").Symbol
local concat_symbols = require("chronos.clock_symbols").concat_symbols
local digits = require("chronos.clock_symbols").digits
local colon = require("chronos.clock_symbols").colon
local DIGITS_MAX_WIDTH = require("chronos.clock_symbols").DIGITS_MAX_WIDTH
local notify = require("chronos.utils").notify
local parse_time = require("chronos.utils").parse_time

---@param timer uv.uv_timer_t|nil
---@return nil
local stop_and_close_timer = function(timer)
  if timer ~= nil then
    timer:stop()
    timer:close()
  end

  return nil
end

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

---@class AlarmOpts
---@field alarm_path string
---@field alarm_text string

---@class ClockOpts
---@filed style string
---@field loc_preset string
---@field win table
---@field alarm_opts AlarmOpts

---@class Clock
---@field opts ClockOpts
---@field buf_id integer|nil
---@field win_id integer|nil
---@field win_width integer|nil
---@field win_height integer|nil
---@field win_config table|nil
---@field timer uv.uv_timer_t|nil
---@field alarm_time integer|nil
---@field alarm_opts AlarmOpts|nil
local Clock = {}

---@param o? table
---@param opts? ClockOpts
function Clock:new(opts, o)
  o = o or {}
  opts = opts or {}
  o.opts = opts
  o.buf_id = nil
  o.win_id = nil
  o.timer = nil
  o.win_width = nil
  o.win_height = nil
  o.win_config = nil
  o.alarm_time = nil
  o.alarm_opts = opts.alarm_opts
  self.__index = self
  return setmetatable(o, { __index = Clock })
end

---@param win_width integer
---@param win_height integer
---@param ui_width integer
---@param ui_height integer
local get_win_loc_presets = function(win_width, win_height, ui_width, ui_height)
  return {
    center = {
      col = ui_width / 2 - win_width / 2,
      row = ui_height / 2 - win_height / 2,
    },
    top_left = {
      col = 0,
      row = 0,
    },
    bottom_left = {
      col = 0,
      row = ui_height - win_height,
    },
    top_right = {
      col = ui_width - win_width,
      row = 0,
    },
    bottom_right = {
      col = ui_width - win_width,
      row = ui_height - win_height,
    },
  }
end

---@param time_symbols string[]
---@param win_width integer
---@param win_height integer
---@return boolean ok
---@return integer win_id
---@return integer buf_id
function Clock:open_init_clock_win(time_symbols, win_width, win_height)
  local buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_keymap(buf_id, "n", "q", "", {
    desc = "Hide the window",
    callback = function()
      self:hide()
    end,
  })

  local ui = vim.api.nvim_list_uis()[1]

  -- `win_width` and `win_height` should not be set by user
  -- to avoid incorrect display.
  self.opts.win.width = win_width
  self.opts.win.height = win_height
  self.opts.win.anchor = "NW"

  local loc_preset =
    get_win_loc_presets(win_width, win_height, ui.width, ui.height)[self.opts.loc_preset]
  local win_config = vim.tbl_deep_extend("force", {
    relative = "editor",
    width = win_width,
    height = win_height,
    col = loc_preset.col,
    row = loc_preset.row,
    anchor = "NW",
    style = "minimal",
    border = "rounded",
  }, self.opts.win)
  self.win_config = win_config

  ---@diagnostic disable-next-line: param-type-mismatch
  local ok, win_id = pcall(vim.api.nvim_open_win, buf_id, false, win_config)

  if not ok then
    return false, -1, -1
  end

  vim.api.nvim_set_option_value("readonly", false, { buf = buf_id })
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, time_symbols)
  vim.api.nvim_set_option_value("readonly", true, { buf = buf_id })

  return true, win_id, buf_id
end

---@param buf_id integer
function Clock:update_clock_win(buf_id)
  if not vim.api.nvim_buf_is_valid(buf_id) then
    return
  end

  local lines, _, _ = build_clock_display(tostring(os.date("%H:%M:%S")))

  vim.api.nvim_set_option_value("readonly", false, { buf = buf_id })
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)
  vim.api.nvim_set_option_value("readonly", true, { buf = buf_id })
end

function Clock:close()
  self.timer = stop_and_close_timer(self.timer)

  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
  end

  if self.win_id and vim.api.nvim_buf_is_valid(self.buf_id) then
    vim.api.nvim_buf_delete(self.buf_id, { force = true })
  end
end

function Clock:new_timer()
  self.timer = stop_and_close_timer(self.timer)

  local uv = vim.uv or vim.loop
  self.timer = uv.new_timer()
end

function Clock:start()
  -- guard
  -- close previous window, buffer and timer if exist.
  -- there should always only one buffer, window and timer.
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
  end

  if self.buf_id and vim.api.nvim_buf_is_valid(self.buf_id) then
    vim.api.nvim_buf_delete(self.buf_id, { force = true })
  end

  self.timer = stop_and_close_timer(self.timer)

  local display, win_width, win_height = build_clock_display(tostring(os.date("%H:%M:%S")))
  self.win_width = win_width
  self.win_height = win_height

  local ok, win_id, buf_id = self:open_init_clock_win(display, win_width, win_height)
  self.win_id = win_id
  self.buf_id = buf_id

  if not ok then
    notify("Failed to open clock window", vim.log.levels.ERROR)
    self.win_id = nil
    self.buf_id = nil
    return
  end

  self:new_timer()
  if not self.timer then
    notify("Failed to start timer", vim.log.levels.ERROR)
    return
  end

  self.timer:start(
    0,
    1000,
    vim.schedule_wrap(function()
      self:update_clock_win(buf_id)
      self:check_alarm()
    end)
  )
end

function Clock:hide()
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
    self.win_id = nil
  end
end

function Clock:show()
  local win_id = vim.api.nvim_open_win(self.buf_id, false, self.win_config)
  self.win_id = win_id
end

---@param alarm_time string
function Clock:set_alarm_at(alarm_time)
  local pattern = "^(%d+):(%d+)$"
  local hour, min = alarm_time:match(pattern)
  if not hour or not min then
    notify("Invalid time format! Use %H:%M", vim.log.levels.ERROR)
    return
  end

  hour, min = tonumber(hour), tonumber(min)
  if hour < 0 or hour >= 24 or min < 0 or min >= 60 then
    notify("Invalid time format!", vim.log.levels.ERROR)
  end

  self.alarm_time = parse_time(alarm_time)
end

function Clock:check_alarm()
  if self.alarm_time == nil then
    return
  end
  local current = os.time()
  local diff = current - self.alarm_time
  if diff >= 0 and diff <= 3 then
    notify(self.alarm_opts.alarm_text, vim.log.levels.INFO)
    vim.system({ "mpv", self.alarm_opts.alarm_path }, {}, function(obj)
      if obj.code ~= 0 then
        notify("Failed to play the alarm sound using mpv!", vim.log.levels.ERROR)
      end
    end)
    self.alarm_time = nil
  end
end

M.Clock = Clock

return M
