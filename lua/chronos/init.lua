local Clock = require("chronos.clock").Clock
local notify = require("chronos.utils").notify

local M = {
  ---@type Clock
  _clock = nil,
  config = {
    loc_preset = "center",
    style = "normal",
    win = {
      relative = "editor",
      anchor = "NW",
      style = "minimal",
      border = "rounded",
    },
    alarm_opts = {
      alarm_path = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "/chronos.nvim/sound/mixkit-morning-clock-alarm-1003.wav"
      ),
      alarm_text = "󰀠 ALARM!",
    },
  },
}

---@param user_config Config
M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
  local alarm_path = M.config.alarm_opts.alarm_path
  local alarm_dir = vim.fs.dirname(alarm_path)
  if vim.fn.isdirectory(alarm_dir) == 0 then
    vim.fn.mkdir(alarm_dir, "p", "0o755")
  end

  M._clock = Clock:new(M.config)
end

M.chronos_open = function()
  if M._clock == nil then
    notify("Clock is nil! It seems that setup() method is not called.", vim.log.levels.ERROR)
    return
  end
  M._clock:start()
end

M.chronos_close = function()
  if M._clock == nil then
    notify("Clock is nil! It seems that setup() method is not called.", vim.log.levels.ERROR)
    return
  end
  M._clock:close()
end

M.chronos_alarm_at = function(opts)
  if M._clock == nil then
    notify("Clock is nil! It seems that setup() method is not called.", vim.log.levels.ERROR)
    return
  end
  local args = opts.args:gsub("%s+", " ")
  local args_splited = vim.split(args, " ", { trimempty = true })
  assert(#args_splited <= 1, "At most one argument is allowed")
  M._clock:set_alarm_at(args_splited[1])
end

M.chronos_show = function ()
  if M._clock == nil then
    notify("Clock is nil! It seems that setup() method is not called.", vim.log.levels.ERROR)
    return
  end
  M._clock:show()
end

M.chronos_hide = function ()
  if M._clock == nil then
    notify("Clock is nil! It seems that setup() method is not called.", vim.log.levels.ERROR)
    return
  end
  M._clock:hide()
end

return M
