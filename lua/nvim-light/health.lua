--[[
--
-- Checks that the external tools this config depends on are actually present.
-- Run with `:checkhealth nvim-light`. See `:help nvim-light-requirements`.
--
--]]

local check_version = function()
  local verstr = tostring(vim.version())
  if vim.version.ge(vim.version(), '0.12.0') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. `vim.pack` needs 0.12.0 or later", verstr))
  end
end

-- Without these, something is broken rather than merely missing
local required = {
  { 'git', '`vim.pack` clones and updates every plugin with it' },
  { 'tree-sitter', "nvim-treesitter's `main` branch builds every parser with the CLI" },
  { 'cc', 'compiles the treesitter parsers' },
}

-- Nice to have; each one degrades a single feature
local optional = {
  { 'rg', 'the grep pickers, like `<leader>sg`' },
  { 'fd', 'faster file pickers' },
  { 'lazygit', '`<leader>gg`' },
}

local check_external_reqs = function()
  for _, spec in ipairs(required) do
    local exe, why = spec[1], spec[2]
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.error(string.format("Could not find executable: '%s' - %s", exe, why))
    end
  end

  for _, spec in ipairs(optional) do
    local exe, why = spec[1], spec[2]
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s' - needed for %s", exe, why))
    end
  end
end

return {
  check = function()
    vim.health.start 'nvim-light'
    vim.health.info('System Information: ' .. vim.inspect(vim.uv.os_uname()))

    check_version()
    check_external_reqs()
  end,
}
