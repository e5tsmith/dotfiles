-- Leader: must come before any <leader> mappings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- WSL clipboard: wire the + register to the *Windows* clipboard
vim.g.clipboard = {
  name = 'WslClipboard',
  copy = {
    ['+'] = 'clip.exe',
    ['*'] = 'clip.exe',
  },
  paste = {
    ['+'] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ['*'] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}

-- <leader>y : yank entire file to Windows clipboard
vim.keymap.set('n', '<leader>y', '<cmd>%y+<CR>', { desc = 'Yank whole file to clipboard' })

-- <leader>p : replace entire file with clipboard; original stashed in register o
vim.keymap.set('n', '<leader>p', function()
  vim.fn.setreg('o', table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(vim.fn.getreg('+'), '\n', { plain = true }))
end, { desc = 'Replace file with clipboard (original -> "o)' })
