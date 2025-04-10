local clock = require("chronos.clock").clock

M = {}

M.chronos_open = function()
  clock:start()
end

M.chronos_close = function()
  clock:cancle()
end

return M
