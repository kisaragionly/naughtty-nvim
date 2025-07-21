
I have made this plugin to streamline how i work with terminals inside neovim, it simplifies switching between your editing environment and a primary terminal while keeping other terminals open for background tasks.

### How It Works

- **Toggle Terminal with a Keymap**: Pressing the designated keymap toggles between your current buffer and a single "active" terminal buffer.
    - If no terminal buffer is marked as active, the plugin creates a new one and sets it as active, then switches to it.
    - Pressing the same keymap swaps back to the previous non-terminal buffer.
- **Deactivating a Terminal**: When in an active terminal buffer, a separate keymap can mark it as inactive.
    - Once inactive, the next toggle will create a new terminal buffer instead of reusing the inactive one.
- **Single Active Terminal**: Only one terminal buffer is active at a time, allowing you to maintain other terminal buffers (e.g., for `npm run dev`) in the background without interference.

The plugin simplifies switching between your editing environment and a primary terminal while keeping other terminals open for background tasks.

### Install

lazy.nvim

```lua
{
  'kisaragionly/naughtty-nvim',
  opts = {},
}
```

### Default config

```lua
opts = {
  keymap = {
    escape_terminal_insert_mode = '<Esc>',
    swap = '<C-t><C-t>',
    toggle_active = '<C-t><C-r>',
  }
}
```

### How will I swap to "inactive" terminal buffers?

I don't know how you will do it, but I use Telescope with the following config.

```lua
vim.keymap.set('n', 'sb', "<cmd>Telescope buffers sort_lastused=true initial_mode=normal<CR>")
```
