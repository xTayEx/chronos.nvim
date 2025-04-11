vim.api.nvim_create_user_command("ChronosOpen", require("chronos").chronos_open, {
  desc = "Open Clock",
})

vim.api.nvim_create_user_command("ChronosClose", require("chronos").chronos_close, {
  desc = "Close Clock",
})

vim.api.nvim_create_user_command("ChronosSetAlarmAt", require("chronos").chronos_alarm_at, {
  desc = "Set alarm at specified time. Format should be '%H:%M'.",
  nargs = "*",
})

