-- Nanosecond timestamp of the earliest point we can measure, used by the
-- dashboard footer to report startup time (lazy.nvim used to provide this)
local start_time = vim.uv.hrtime()

-- Set <space> as the leader key
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line (mini.statusline)
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>xq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Remove Neovim's default LSP mappings (`:help lsp-defaults`). This config has
-- no language servers, so all they do is fail with "no client" and shadow the
-- `gr`/`grx` motions. `gO` is deliberately kept: the |vim.pack| update buffer
-- and help files use it for their outline.
for _, lhs in ipairs { 'grn', 'grr', 'gri', 'grt', 'grx' } do
  pcall(vim.keymap.del, 'n', lhs)
end
pcall(vim.keymap.del, { 'n', 'x' }, 'gra')
pcall(vim.keymap.del, { 'i', 's' }, '<C-S>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Same from inside a terminal. `<C-\><C-n>` leaves terminal mode first.
-- NOTE: this takes <C-h> away from the shell, where it is a backspace.
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Move focus to the left window' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Move focus to the right window' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Move focus to the lower window' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
vim.keymap.set('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
vim.keymap.set('n', '<leader>bD', '<cmd>:bd<cr>', { desc = 'Delete Buffer and Window' })
vim.keymap.set('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit All' })
vim.keymap.set('n', '<leader>wd', '<C-W>c', { desc = 'Delete Window Buffer' })
vim.keymap.set('n', '<leader>-', '<C-W>s', { desc = 'Split Window Below' })
vim.keymap.set('n', '<leader>|', '<C-W>v', { desc = 'Split Window Right' })

-- Plugin manager keymaps (`:help vim.pack`)
vim.keymap.set('n', '<leader>l', function()
  vim.pack.update()
end, { desc = 'Update plugins (vim.pack)' })
vim.keymap.set('n', '<leader>L', function()
  vim.pack.update(nil, { offline = true })
end, { desc = 'List plugins (vim.pack, offline)' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('nvim-light-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Plugins ]]
--  Managed by the built-in plugin manager, `vim.pack` (Neovim 0.12+).
--  See `:help vim.pack`. Plugins live in `site/pack/core/opt` under `stdpath('data')`
--  and their revisions are tracked in `nvim-pack-lock.json` next to this file.

local function gh(repo)
  return 'https://github.com/' .. repo
end

-- Build hooks. Must be registered *before* the first `vim.pack.add()` so they
-- also fire on the initial install. See `:help vim.pack-events`.
vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Run plugin build steps after install/update',
  group = vim.api.nvim_create_augroup('nvim-light-pack-build', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then
      return
    end

    -- Treesitter parsers need to be rebuilt against the new plugin version
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd 'nvim-treesitter'
      end
      require('nvim-treesitter').update()
    end
  end,
})

vim.pack.add({
  -- Big collection of QoL plugins. Provides the `Snacks` global, so keep it first.
  gh 'folke/snacks.nvim',

  -- Detect tabstop and shiftwidth automatically
  gh 'NMAC427/guess-indent.nvim',

  -- Git signs in the gutter, plus utilities for managing changes
  gh 'lewis6991/gitsigns.nvim',

  -- Yank ring
  gh 'gbprod/yanky.nvim',

  -- Shows pending keybinds
  gh 'folke/which-key.nvim',

  -- Required by todo-comments.nvim
  gh 'nvim-lua/plenary.nvim',

  -- Autocompletion
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },

  gh 'folke/todo-comments.nvim',

  -- Library of independent modules: mini.ai, mini.surround, mini.statusline, ...
  gh 'nvim-mini/mini.nvim',

  -- Highlight, edit, and navigate code
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },

  gh 'folke/persistence.nvim',

  gh 'akinsho/bufferline.nvim',
}, { confirm = false })

-- [[ Plugin configuration ]]
-- With `vim.pack` there is no lazy-loading layer: every plugin is on the
-- runtimepath already, so we just call `setup()` and define keymaps directly.

-- snacks.nvim
require('snacks').setup {
  bigfile = { enabled = true },
  dashboard = {
    preset = {
      header = [[
                                        ___                __      __      
                __                     /\_ \    __        /\ \    /\ \__   
  ___   __  __ /\_\    ___ ___         \//\ \  /\_\     __\ \ \___\ \ ,_\  
/' _ `\/\ \/\ \\/\ \ /' __` __`\  _______\ \ \ \/\ \  /'_ `\ \  _ `\ \ \/  
/\ \/\ \ \ \_/ |\ \ \/\ \/\ \/\ \/\______\\_\ \_\ \ \/\ \L\ \ \ \ \ \ \ \_ 
\ \_\ \_\ \___/  \ \_\ \_\ \_\ \_\/______//\____\\ \_\ \____ \ \_\ \_\ \__\
 \/_/\/_/\/__/    \/_/\/_/\/_/\/_/        \/____/ \/_/\/___L\ \/_/\/_/\/__/
                                                        /\____/            
                                                        \_/__/             
 ]],
      -- stylua: ignore
      ---@type snacks.dashboard.Item[]
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = "󰒲 ", key = "l", desc = "Plugins", action = ":lua vim.pack.update()" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1 },
      { title = 'Recent Files', section = 'recent_files', indent = 2, padding = { 2, 2 } },
      -- NOTE: snacks' built-in `startup` section calls `require('lazy.stats')`,
      -- which does not exist without lazy.nvim. Report `vim.pack` numbers instead.
      function()
        local plugins = vim.pack.get(nil, { info = false })
        local loaded = 0
        for _, p in ipairs(plugins) do
          loaded = loaded + (p.active and 1 or 0)
        end
        local ms = math.floor((vim.uv.hrtime() - start_time) / 1e4 + 0.5) / 100
        return {
          align = 'center',
          text = {
            { '⚡ Neovim loaded ', hl = 'footer' },
            { loaded .. '/' .. #plugins, hl = 'special' },
            { ' plugins in ', hl = 'footer' },
            { ms .. 'ms', hl = 'special' },
          },
        }
      end,
    },
  },
  explorer = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  picker = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
}

-- stylua: ignore start
-- Top Pickers & Explorer
vim.keymap.set('n', '<leader><space>', function() Snacks.picker.smart() end, { desc = 'Smart Find Files' })
vim.keymap.set('n', '<leader>,', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>/', function() Snacks.picker.grep() end, { desc = 'Grep' })
vim.keymap.set('n', '<leader>:', function() Snacks.picker.command_history() end, { desc = 'Command History' })
vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File Explorer' })
-- find
vim.keymap.set('n', '<leader>fb', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fc', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = 'Find Config File' })
vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', function() Snacks.picker.git_files() end, { desc = 'Find Git Files' })
vim.keymap.set('n', '<leader>fp', function() Snacks.picker.projects() end, { desc = 'Projects' })
vim.keymap.set('n', '<leader>fr', function() Snacks.picker.recent() end, { desc = 'Recent' })
-- git
vim.keymap.set('n', '<leader>gb', function() Snacks.picker.git_branches() end, { desc = 'Git Branches' })
vim.keymap.set('n', '<leader>gl', function() Snacks.picker.git_log() end, { desc = 'Git Log' })
vim.keymap.set('n', '<leader>gL', function() Snacks.picker.git_log_line() end, { desc = 'Git Log Line' })
vim.keymap.set('n', '<leader>gs', function() Snacks.picker.git_status() end, { desc = 'Git Status' })
vim.keymap.set('n', '<leader>gS', function() Snacks.picker.git_stash() end, { desc = 'Git Stash' })
vim.keymap.set('n', '<leader>gd', function() Snacks.picker.git_diff() end, { desc = 'Git Diff (Hunks)' })
vim.keymap.set('n', '<leader>gf', function() Snacks.picker.git_log_file() end, { desc = 'Git Log File' })
vim.keymap.set({ 'n', 'v' }, '<leader>gB', function() Snacks.gitbrowse() end, { desc = 'Git Browse' })
vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit() end, { desc = 'Lazygit' })
-- Grep
vim.keymap.set('n', '<leader>sB', function() Snacks.picker.grep_buffers() end, { desc = 'Grep Open Buffers' })
vim.keymap.set({ 'n', 'x' }, '<leader>sw', function() Snacks.picker.grep_word() end, { desc = 'Visual selection or word' })
-- search
vim.keymap.set('n', '<leader>s"', function() Snacks.picker.registers() end, { desc = 'Registers' })
vim.keymap.set('n', '<leader>s/', function() Snacks.picker.search_history() end, { desc = 'Search History' })
vim.keymap.set('n', '<leader>sa', function() Snacks.picker.autocmds() end, { desc = 'Autocmds' })
vim.keymap.set('n', '<leader>sb', function() Snacks.picker.lines() end, { desc = 'Buffer Lines' })
vim.keymap.set('n', '<leader>sc', function() Snacks.picker.command_history() end, { desc = 'Command History' })
vim.keymap.set('n', '<leader>sC', function() Snacks.picker.commands() end, { desc = 'Commands' })
vim.keymap.set('n', '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Buffer Diagnostics' })
vim.keymap.set('n', '<leader>sH', function() Snacks.picker.highlights() end, { desc = 'Highlights' })
vim.keymap.set('n', '<leader>si', function() Snacks.picker.icons() end, { desc = 'Icons' })
vim.keymap.set('n', '<leader>sj', function() Snacks.picker.jumps() end, { desc = 'Jumps' })
vim.keymap.set('n', '<leader>sl', function() Snacks.picker.loclist() end, { desc = 'Location List' })
vim.keymap.set('n', '<leader>sm', function() Snacks.picker.marks() end, { desc = 'Marks' })
vim.keymap.set('n', '<leader>sM', function() Snacks.picker.man() end, { desc = 'Man Pages' })
vim.keymap.set('n', '<leader>sq', function() Snacks.picker.qflist() end, { desc = 'Quickfix List' })
vim.keymap.set('n', '<leader>sR', function() Snacks.picker.resume() end, { desc = 'Resume' })
vim.keymap.set('n', '<leader>su', function() Snacks.picker.undo() end, { desc = 'Undo History' })
vim.keymap.set('n', '<leader>uC', function() Snacks.picker.colorschemes() end, { desc = 'Colorschemes' })
vim.keymap.set('n', '<leader>sh', function() Snacks.picker.help() end, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() Snacks.picker.files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sg', function() Snacks.picker.grep() end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', function() Snacks.picker.diagnostics() end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>s.', function() Snacks.picker.recent() end, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
vim.keymap.set('n', '<leader>ss', function() Snacks.picker.treesitter() end, { desc = 'Treesitter Symbols' })
-- Other
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Toggle Zen Mode' })
vim.keymap.set('n', '<leader>Z', function() Snacks.zen.zoom() end, { desc = 'Toggle Zoom' })
vim.keymap.set('n', '<leader>.', function() Snacks.scratch() end, { desc = 'Toggle Scratch Buffer' })
vim.keymap.set('n', '<leader>S', function() Snacks.scratch.select() end, { desc = 'Select Scratch Buffer' })
vim.keymap.set('n', '<leader>n', function() Snacks.notifier.show_history() end, { desc = 'Notification History' })
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Delete Buffer' })
vim.keymap.set('n', '<leader>cR', function() Snacks.rename.rename_file() end, { desc = 'Rename File' })
vim.keymap.set('n', '<leader>un', function() Snacks.notifier.hide() end, { desc = 'Dismiss All Notifications' })
-- Terminal mode too, or the toggle only works one way. `<C-_>` is what some
-- terminals send for <C-/>.
vim.keymap.set({ 'n', 't' }, '<c-/>', function() Snacks.terminal() end, { desc = 'Toggle Terminal' })
vim.keymap.set({ 'n', 't' }, '<c-_>', function() Snacks.terminal() end, { desc = 'which_key_ignore' })
vim.keymap.set({ 'n', 't' }, ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next Reference' })
vim.keymap.set({ 'n', 't' }, '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Prev Reference' })
-- stylua: ignore end

-- gitsigns.nvim
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

-- guess-indent.nvim
-- NOTE: no `plugin/` directory, so the autocmds only exist after `setup()`
require('guess-indent').setup()

-- yanky.nvim
-- NOTE: must be set up *after* snacks.nvim so it can register its own picker source
require('yanky').setup {
  highlight = { timer = 150 },
}

-- stylua: ignore start
vim.keymap.set({ 'n', 'x' }, '<leader>p', function() Snacks.picker.yanky() end, { desc = 'Open Yank History' })
vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = 'Yank Text' })
vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Put Text After Cursor' })
vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Put Text Before Cursor' })
vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)', { desc = 'Put Text After Selection' })
vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)', { desc = 'Put Text Before Selection' })
vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)', { desc = 'Cycle Forward Through Yank History' })
vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)', { desc = 'Cycle Backward Through Yank History' })
vim.keymap.set('n', ']p', '<Plug>(YankyPutIndentAfterLinewise)', { desc = 'Put Indented After Cursor (Linewise)' })
vim.keymap.set('n', '[p', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = 'Put Indented Before Cursor (Linewise)' })
vim.keymap.set('n', ']P', '<Plug>(YankyPutIndentAfterLinewise)', { desc = 'Put Indented After Cursor (Linewise)' })
vim.keymap.set('n', '[P', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = 'Put Indented Before Cursor (Linewise)' })
vim.keymap.set('n', '>p', '<Plug>(YankyPutIndentAfterShiftRight)', { desc = 'Put and Indent Right' })
vim.keymap.set('n', '<p', '<Plug>(YankyPutIndentAfterShiftLeft)', { desc = 'Put and Indent Left' })
vim.keymap.set('n', '>P', '<Plug>(YankyPutIndentBeforeShiftRight)', { desc = 'Put Before and Indent Right' })
vim.keymap.set('n', '<P', '<Plug>(YankyPutIndentBeforeShiftLeft)', { desc = 'Put Before and Indent Left' })
vim.keymap.set('n', '=p', '<Plug>(YankyPutAfterFilter)', { desc = 'Put After Applying a Filter' })
vim.keymap.set('n', '=P', '<Plug>(YankyPutBeforeFilter)', { desc = 'Put Before Applying a Filter' })
-- stylua: ignore end

-- which-key.nvim
require('which-key').setup {
  preset = 'helix',
  -- delay between pressing a key and opening which-key (milliseconds)
  -- this setting is independent of vim.o.timeoutlen
  delay = 0,
  icons = {
    -- set icon mappings to true if you have a Nerd Font
    mappings = vim.g.have_nerd_font,
    -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
    -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
    keys = vim.g.have_nerd_font and {} or {
      Up = '<Up> ',
      Down = '<Down> ',
      Left = '<Left> ',
      Right = '<Right> ',
      C = '<C-…> ',
      M = '<M-…> ',
      D = '<D-…> ',
      S = '<S-…> ',
      CR = '<CR> ',
      Esc = '<Esc> ',
      ScrollWheelDown = '<ScrollWheelDown> ',
      ScrollWheelUp = '<ScrollWheelUp> ',
      NL = '<NL> ',
      BS = '<BS> ',
      Space = '<Space> ',
      Tab = '<Tab> ',
      F1 = '<F1>',
      F2 = '<F2>',
      F3 = '<F3>',
      F4 = '<F4>',
      F5 = '<F5>',
      F6 = '<F6>',
      F7 = '<F7>',
      F8 = '<F8>',
      F9 = '<F9>',
      F10 = '<F10>',
      F11 = '<F11>',
      F12 = '<F12>',
    },
  },

  -- Document existing key chains
  spec = {
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
  },
}

-- blink.cmp
--- @module 'blink.cmp'
--- @type blink.cmp.Config
require('blink.cmp').setup {
  keymap = {
    preset = 'super-tab',
  },

  appearance = {
    nerd_font_variant = 'mono',
  },

  completion = {
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },

  sources = {
    default = { 'path' },
    providers = {},
  },

  fuzzy = { implementation = 'lua' },

  signature = { enabled = true },
}

-- todo-comments.nvim
require('todo-comments').setup { signs = false }

-- mini.nvim
-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup { n_lines = 500 }

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - gsaiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - gsd'   - [S]urround [D]elete [']quotes
-- - gsr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup {
  mappings = {
    add = 'gsa', -- Add surrounding in Normal and Visual modes
    delete = 'gsd', -- Delete surrounding
    find = 'gsf', -- Find surrounding (to the right)
    find_left = 'gsF', -- Find surrounding (to the left)
    highlight = 'gsh', -- Highlight surrounding
    replace = 'gsr', -- Replace surrounding
    update_n_lines = 'gsn', -- Update `n_lines`
  },
}

require('mini.move').setup()

-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local statusline = require 'mini.statusline'
-- set use_icons to true if you have a Nerd Font
statusline.setup { use_icons = vim.g.have_nerd_font }

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end

-- ... and there is more!
--  Check out: https://github.com/echasnovski/mini.nvim

-- nvim-treesitter
--  The `main` branch dropped `nvim-treesitter.configs`: parsers are installed
--  imperatively and highlighting/indenting are enabled per buffer.
--  Exposed on `vim.g` so the Docker build can install the same set headlessly.
local ts_parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
vim.g.ts_parsers = ts_parsers

require('nvim-treesitter').setup()

-- Install any parser that isn't on disk yet. Runs asynchronously and is a no-op
-- once everything is present, so it costs nothing on a normal startup.
local ts_missing = vim.tbl_filter(function(lang)
  return not vim.tbl_contains(require('nvim-treesitter.config').get_installed 'parsers', lang)
end, ts_parsers)
if #ts_missing > 0 then
  require('nvim-treesitter').install(ts_missing)
end

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter highlighting and indenting',
  group = vim.api.nvim_create_augroup('nvim-light-treesitter', { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not (lang and vim.tbl_contains(ts_parsers, lang)) then
      return
    end
    -- `pcall`: the parser may still be installing on a fresh config
    if pcall(vim.treesitter.start, ev.buf, lang) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- persistence.nvim
require('persistence').setup()

-- stylua: ignore start
vim.keymap.set('n', '<leader>qs', function() require('persistence').load() end, { desc = 'Restore Session' })
vim.keymap.set('n', '<leader>qS', function() require('persistence').select() end, { desc = 'Select Session' })
vim.keymap.set('n', '<leader>ql', function() require('persistence').load { last = true } end, { desc = 'Restore Last Session' })
vim.keymap.set('n', '<leader>qd', function() require('persistence').stop() end, { desc = "Don't Save Current Session" })
-- stylua: ignore end

-- bufferline.nvim
require('bufferline').setup {
  options = {
    -- stylua: ignore
    close_command = function(n) Snacks.bufdelete(n) end,
    -- stylua: ignore
    right_mouse_command = function(n) Snacks.bufdelete(n) end,
    always_show_bufferline = false,
    offsets = {
      {
        filetype = 'snacks_picker_list',
        text = 'Explorer',
        highlight = 'Directory',
        text_align = 'left',
      },
      {
        filetype = 'snacks_layout_box',
      },
    },
  },
}

-- Fix bufferline when restoring a session
vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
  group = vim.api.nvim_create_augroup('nvim-light-bufferline-session', { clear = true }),
  callback = function()
    vim.schedule(function()
      pcall(nvim_bufferline)
    end)
  end,
})

-- stylua: ignore start
vim.keymap.set('n', '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', { desc = 'Toggle Pin' })
vim.keymap.set('n', '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', { desc = 'Delete Non-Pinned Buffers' })
vim.keymap.set('n', '<leader>br', '<Cmd>BufferLineCloseRight<CR>', { desc = 'Delete Buffers to the Right' })
vim.keymap.set('n', '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', { desc = 'Delete Buffers to the Left' })
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev Buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next Buffer' })
vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev Buffer' })
vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next Buffer' })
vim.keymap.set('n', '[B', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer prev' })
vim.keymap.set('n', ']B', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer next' })
-- stylua: ignore end

-- NOTE: To add a plugin, add its source to the `vim.pack.add()` call above and
-- its `setup()` call plus keymaps down here.

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
