-- Leader: must come before any <leader> mappings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- nvim-tree replaces netrw (the built-in browser); disable it
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.opt.cursorline = true

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

-- Bootstrap lazy.nvim (clones itself on first launch)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').load()
      -- render-markdown tuned to the approved mockup (One Half Dark palette)
      local function md_hl()
        local set = vim.api.nvim_set_hl
        for i = 1, 6 do
          set(0, 'RenderMarkdownH' .. i, { fg = '#61afef', bold = true })                 -- heading icon
          set(0, '@markup.heading.' .. i .. '.markdown', { fg = '#61afef', bold = true }) -- heading text
          set(0, 'RenderMarkdownH' .. i .. 'Bg', { bg = '#2d3f4e' })                      -- heading bar
        end
        set(0, '@markup.heading.markdown', { fg = '#e5c07b', bold = true })  -- table header text
        set(0, 'RenderMarkdownTableHead', { fg = '#848b98' })               -- header border -> fine light
        set(0, 'RenderMarkdownTableRow', { fg = '#848b98' })                -- body border -> fine light
        set(0, 'RenderMarkdownCodeInline', { fg = '#56b6c2', bg = '#31353f' })
      end
      md_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = md_hl })
    end },
  { 'christoomey/vim-tmux-navigator',
    cmd = { 'TmuxNavigateLeft', 'TmuxNavigateDown', 'TmuxNavigateUp', 'TmuxNavigateRight' },
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<cr>',  desc = 'Window left' },
      { '<C-j>', '<cmd>TmuxNavigateDown<cr>',  desc = 'Window down' },
      { '<C-k>', '<cmd>TmuxNavigateUp<cr>',    desc = 'Window up' },
      { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Window right' },
    } },
  { 'nvim-telescope/telescope.nvim', branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function() require('nvim-tree').setup() end },
  { 'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {} },
  -- Markdown: render in-buffer (headings, bullets, tables, code blocks)
  { 'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    opts = { pipe_table = { padding = 2 } } },
  -- Markdown: live preview in the Windows browser
  { 'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle' },
    ft = 'markdown',
    build = 'cd app && npx --yes yarn install',
    init = function()
      vim.g.mkdp_echo_preview_url = 1
    end },
})

-- Bold window separators (survive colorscheme reloads)
local function win_hl()
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#5c6370', bold = true })
end
win_hl()
vim.api.nvim_create_autocmd('ColorScheme', { callback = win_hl })

-- <leader>z : zoom the current window by toggling it into its own tab
vim.keymap.set('n', '<leader>z', function()
  if vim.fn.tabpagenr('$') > 1 then vim.cmd('tabclose') else vim.cmd('tab split') end
end, { desc = 'Zoom window (toggle, via tab)' })

-- Telescope: fuzzy find + project-wide grep
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep,  { desc = 'Grep project' })
vim.keymap.set('n', '<leader>fb', builtin.buffers,    { desc = 'Open buffers' })

-- File tree sidebar
vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<CR>', { desc = 'File tree' })

-- Markdown preview toggle
vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { desc = 'Markdown preview in browser' })

-- <leader>o : open current file with its default Windows app
vim.keymap.set('n', '<leader>o', function()
  local file = vim.fn.expand('%:p')
  if file == '' then return vim.notify('No file on disk yet', vim.log.levels.WARN) end
  local winpath = vim.fn.system({ 'wslpath', '-w', file }):gsub('%s+$', '')
  vim.fn.jobstart({ 'explorer.exe', winpath }, { detach = true })
end, { desc = 'Open file with Windows default app' })

-- <leader>y : yank entire file to Windows clipboard (normal mode)
vim.keymap.set('n', '<leader>y', function()
  vim.cmd('%y+')
  vim.notify('File copied to clipboard')
end, { desc = 'Yank whole file to clipboard' })

-- <leader>y : yank just the selection (visual mode)
vim.keymap.set('x', '<leader>y', '"+y', { desc = 'Yank selection to clipboard' })

-- <leader>p : replace entire file with clipboard; original stashed in register o
vim.keymap.set('n', '<leader>p', function()
  vim.fn.setreg('o', table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(vim.fn.getreg('+'), '\n', { plain = true }))
end, { desc = 'Replace file with clipboard (original -> "o)' })
