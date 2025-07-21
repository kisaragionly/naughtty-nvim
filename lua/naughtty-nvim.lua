local vim = vim

---@class Buffer
---@field buffer integer
---@field active boolean
local Buffer = {}

---@param buffer_number integer
---@return Buffer
function Buffer.new(buffer_number)
  local self = setmetatable({}, { __index = Buffer })
  self.buffer = buffer_number
  self.active = true
  return self
end

---@class BufferManager
---@field buffers Buffer[]
local BufferManager = {}

---@return BufferManager
function BufferManager.new()
  local self = setmetatable({}, { __index = BufferManager })
  self.buffers = {}
  return self
end

---Sets the given buffer as the only active one
---@param buffer_number integer
function BufferManager:set_active(buffer_number)
  for _, b in ipairs(self.buffers) do
    b.active = (b.buffer == buffer_number)
  end
end

---Adds a new buffer and makes it the only active one
---@param buffer_number integer
---@return Buffer
function BufferManager:add_new(buffer_number)
  for _, b in ipairs(self.buffers) do
    b.active = false
  end
  local new_buffer = Buffer.new(buffer_number)
  table.insert(self.buffers, new_buffer)
  return new_buffer
end

---@param buffer_number integer
---@return boolean
function BufferManager:remove(buffer_number)
  for i, buffer in ipairs(self.buffers) do
    if buffer.buffer == buffer_number then
      table.remove(self.buffers, i)
      return true
    end
  end
  return false
end

---@param buffer_number integer
---@return Buffer|nil
function BufferManager:get(buffer_number)
  for _, buffer in ipairs(self.buffers) do
    if buffer.buffer == buffer_number then
      return buffer
    end
  end
  return nil
end

---@return Buffer|nil
function BufferManager:get_first_active()
  for _, buffer in ipairs(self.buffers) do
    if buffer.active then
      return buffer
    end
  end
  return nil
end

---@class M
local M = {}

local last_non_terminal_buffer_number = nil
local terminal_buffer_manager = BufferManager.new()

---Ensures a terminal is managed, if not we manage it, the we get it
---@param buffer_terminal integer
---@return Buffer
local function ensure_is_managed_and_get_terminal(buffer_terminal)
  local terminal = terminal_buffer_manager:get(buffer_terminal)
  if not terminal then
    terminal = terminal_buffer_manager:add_new(buffer_terminal)
  end
  return terminal
end

---Swaps between the last non terminal buffer and the active terminal buffer
M.swap = function()
  local current_buffer_number = vim.fn.bufnr('%')
  local is_terminal = vim.bo[current_buffer_number].buftype == 'terminal'

  if is_terminal then
    ensure_is_managed_and_get_terminal(current_buffer_number)
    -- Return to the non terminal buffer if we have one to return to
    if last_non_terminal_buffer_number and vim.fn.bufexists(last_non_terminal_buffer_number) == 1 then
      vim.cmd('buffer ' .. last_non_terminal_buffer_number)
    end
    return
  end

  -- We are in a normal buffer
  -- save it and find the active terminal to switch to
  last_non_terminal_buffer_number = current_buffer_number
  while true do
    local active_terminal = terminal_buffer_manager:get_first_active()
    if not active_terminal then
      break -- No active terminals
    end

    if vim.fn.bufexists(active_terminal.buffer) == 1 then
      vim.cmd('buffer ' .. active_terminal.buffer)
      return -- Swapped
    else
      -- We got an active buffer that doesn't exist
      -- clean it up and loop again
      terminal_buffer_manager:remove(active_terminal.buffer)
    end
  end

  -- If we haven't swapped yet, create a new terminal
  vim.cmd('term')
  local new_terminal_buffer_number = vim.fn.bufnr('%')
  terminal_buffer_manager:add_new(new_terminal_buffer_number)
end

---Toggles the active state of the current terminal buffer
M.set_unset_current_active = function()
  local current_buffer_number = vim.fn.bufnr('%')
  if vim.bo[current_buffer_number].buftype ~= 'terminal' then
    return
  end

  local terminal = ensure_is_managed_and_get_terminal(current_buffer_number)
  local was_active = terminal.active

  -- Set all terminals to inactive
  for _, b in ipairs(terminal_buffer_manager.buffers) do
    b.active = false
  end

  -- Set the current terminal to the opposite of its previous state
  terminal.active = not was_active
end

M.setup = function(opts)
  local defaults = {
    keymap = {
      escape_terminal_insert_mode = '<Esc>',
      swap = '<C-t><C-t>',
      toggle_active = '<C-t><C-r>',
    },
  }

  local config = vim.tbl_deep_extend('force', defaults, opts or {})

  local keymap_actions = {
    escape_terminal_insert_mode = function(key)
      vim.keymap.set('t', key, '<C-\\><C-n>', { silent = true, desc = "in terminal mode, enter normal mode" })
    end,
    swap = function(key)
      vim.keymap.set({ 'n', 't' }, key, M.swap, { silent = true, desc = 'swap buffers' })
    end,
    toggle_active = function(key)
      vim.keymap.set({ 'n', 't' }, key, M.set_unset_current_active, { silent = true, desc = 'toggle active terminal' })
    end,
  }

  if config.keymap then
    for action, key in pairs(config.keymap) do
      if key and keymap_actions[action] then
        keymap_actions[action](key)
      end
    end
  end
end

return M
