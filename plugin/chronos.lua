vim.api.nvim_create_user_command("ChronosOpen", require("chronos").chronos_open, {
  desc = "Open Clock",
})

vim.api.nvim_create_user_command("ChronosClose", require("chronos").chronos_close, {
  desc = "Close Clock",
})
