FROM debian:trixie-slim AS release

RUN apt-get update && apt-get install -y \
  curl git fzf fd-find ripgrep build-essential ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
  ARCH="arm64"; \
  else \
  ARCH="x86_64"; \
  fi && \
  curl -OL "https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-${ARCH}.tar.gz" && \
  tar -xzf "nvim-linux-${ARCH}.tar.gz" && \
  mv "nvim-linux-${ARCH}" /opt/nvim && \
  ln -s /opt/nvim/bin/nvim /usr/bin/nvim && \
  rm "nvim-linux-${ARCH}.tar.gz"

# nvim-treesitter's `main` branch builds every parser with the tree-sitter CLI
ARG TREE_SITTER_VERSION=v0.27.0
RUN if [ "$TARGETARCH" = "arm64" ]; then \
  TS_ARCH="arm64"; \
  else \
  TS_ARCH="x64"; \
  fi && \
  curl -L "https://github.com/tree-sitter/tree-sitter/releases/download/${TREE_SITTER_VERSION}/tree-sitter-linux-${TS_ARCH}.gz" \
  | gunzip > /usr/local/bin/tree-sitter && \
  chmod +x /usr/local/bin/tree-sitter && \
  tree-sitter --version

WORKDIR /root

COPY . /root/.config/nvim

# Install plugins, then install the treesitter parsers synchronously so the
# image ships with them ready to use
RUN nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa && \
  nvim --headless "+lua require('nvim-treesitter').install(vim.g.ts_parsers):wait(600000)" +qa

ENV TERM=xterm-256color
CMD ["nvim"]
