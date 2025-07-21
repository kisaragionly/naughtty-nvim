local vim = vim

--- @class Buffer
--- @field buffer any|nil
--- @field dirty boolean
local Buffer = {}

--- @return Buffer
function Buffer.new()
  local self = setmetatable({}, { __index = Buffer })
  self.buffer = nil
  self.dirty = false
  return self
end

--- @class BufferManager
--- @field buffers Buffer[]
local BufferManager = {}

--- @return BufferManager
function BufferManager.new()
  local self = setmetatable({}, { __index = BufferManager })
  self.buffers = {}
  return self
end

--- @param buffer Buffer
--- @return boolean
function BufferManager:insert(buffer)
  if buffer == nil then
    return false
  end
  if buffer.buffer == nil then
    return false
  end
  table.insert(self.buffers, buffer)
  return true
end

--- @param buffer_number any
--- @return boolean
function BufferManager:remove(buffer_number)
  for i, buffer in ipairs(self.buffers) do
    if buffer.buffer == buffer_number then
      table.remove(self.buffers, i)
      return true
    end
  end
  return false
end

--- @param buffer_number any
--- @return Buffer|nil
function BufferManager:get(buffer_number)
  for _, buffer in ipairs(self.buffers) do
    if buffer.buffer == buffer_number then
      return buffer
    end
  end
  return nil
end

--- @return Buffer|nil
function BufferManager:get_first_clean()
  for _, buffer in ipairs(self.buffers) do
    if buffer.dirty == false then
      return buffer
    end
  end
  return nil
end

local M = {}

local non_terminal_buffer_number = nil
local terminal_buffer_manager = BufferManager.new()

M.test = function()
  local current_buffer_number = vim.fn.bufnr('%')
  local current_is_terminal_buffer = vim.bo.buftype == 'terminal'

  -- If the current buffer is a terminal and it's not in the terminal_buffers manager we insert it
  if current_is_terminal_buffer then
    local terminal_exist_in_manager = terminal_buffer_manager:get(current_buffer_number)
    if terminal_exist_in_manager == nil then
      local new_buffer = Buffer.new()
      new_buffer.buffer = current_buffer_number
      terminal_buffer_manager:insert(new_buffer)
    end
  end

  -- if we are in a terminal and we came from a non terminal we swap back
  if current_is_terminal_buffer then
    if non_terminal_buffer_number ~= nil then
      vim.cmd('buffer ' .. non_terminal_buffer_number)
    end
    return
  end

  -- if we are not in a terminal we assign it to non_terminal_buffer_number so it can return latter
  -- then we find a terminal that's clean and exists while removing the ones that does not exist
  -- if we got a terminal we swap to it
  if not current_is_terminal_buffer then
    non_terminal_buffer_number = current_buffer_number
    while true do
      local first_clean_terminal = terminal_buffer_manager:get_first_clean()
      if first_clean_terminal == nil then
        break
      end
      if vim.fn.bufexists(first_clean_terminal.buffer) == 1 then
        vim.cmd('buffer ' .. first_clean_terminal.buffer)
        return
      else
        terminal_buffer_manager:remove(first_clean_terminal.buffer)
      end
    end
  end

  -- if we haven't swapped yet, we create a new terminal
  vim.cmd('term')
  local new_terminal_buffer_number = vim.fn.bufnr('%')
  local new_buffer = Buffer.new()
  new_buffer.buffer = new_terminal_buffer_number
  terminal_buffer_manager:insert(new_buffer)
end

M.setup = function()
  -- <Esc> in terminal exit to normal mode
  vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })

  -- n <C-t> t <C-t> swaps
  vim.keymap.set('t', '<C-t>', M.test)
  vim.keymap.set('n', '<C-t>', M.test)
end

return M
