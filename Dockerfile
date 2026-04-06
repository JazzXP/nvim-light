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
  curl -OL "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-${ARCH}.tar.gz" && \
  tar -xzf "nvim-linux-${ARCH}.tar.gz" && \
  mv "nvim-linux-${ARCH}" /opt/nvim && \
  ln -s /opt/nvim/bin/nvim /usr/bin/nvim && \
  rm "nvim-linux-${ARCH}.tar.gz"

WORKDIR /root

COPY . /root/.config/nvim

RUN nvim --headless "+Lazy! sync" +qa && \
  nvim --headless "+TSUpdate" +qa

ENV TERM=xterm-256color
CMD ["nvim"]
