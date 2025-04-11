local Clock = require("chronos.clock").Clock
local notify = require("chronos.utils").notify

local M = {
  ---@type Clock
  _clock = nil,
  config = {
    win = {
      relative = "editor",
      anchor = "NW",
      style = "minimal",
      border = "rounded",
    },
  },
}

---@param user_config Config
M.setup = function(user_config)
  M.config = vim.tbl_extend("force", M.config, user_config or {})
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

return M
