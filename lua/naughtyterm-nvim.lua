local vim = vim

local M = {}

-- Function to toggle the terminal
M.test = function()
  print("AAA\nBBB\nCCC")
end

-- Setup function to configure the plugin
M.setup = function()
  -- Map <leader>t to toggle the terminal
  vim.keymap.set('n', '<leader>t', function()
    M.test()
  end)
end

return M
