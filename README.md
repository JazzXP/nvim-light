# NVIM-Light

My lightweight Neovim config for running on servers, not a full IDE, just some niceties for myself. Based on kickstart.nvim

No LSP, no AI, just the basics.

The whole config is a single `init.lua`, and plugins are managed by Neovim's built-in `vim.pack` — no plugin manager to bootstrap.

## Requirements

- Neovim 0.12.0 or later (`vim.pack` does not exist before 0.12)
- `git`
- the `tree-sitter` CLI (0.26.1+) and a C compiler — nvim-treesitter's `main` branch builds every parser locally
- `rg`, and optionally `fd`, `fzf`, `lazygit`

`./install.sh` installs Neovim and the tree-sitter CLI for your package manager and adds an `nvim-light` shell alias. `:checkhealth nvim-light` verifies the rest.

## Usage

`:help nvim-light` documents the keymaps and how to add or remove a plugin.

Plugins install themselves on first start. `<leader>l` opens the update review buffer — `:w` applies, `:q` discards, then `:restart`. Revisions are pinned in `nvim-pack-lock.json`, which is worth committing.

## Docker

```bash
docker run --rm -it -v .:/src ghcr.io/jazzxp/nvim-light nvim /src
```

The image ships with all plugins and treesitter parsers already built.
