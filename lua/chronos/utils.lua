local M = {}

M.notify = function(msg, type, opts)
  opts = opts or {}
  vim.schedule(function()
    vim.notify(msg, type, vim.tbl_extend("force", { title = "chronos.nvim" }, opts))
  end)
end

return M
