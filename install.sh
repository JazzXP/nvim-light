#!/bin/bash
install_neovim() {
	if command -v brew >/dev/null 2>&1; then
		brew install neovim
	elif command -v apk >/dev/null 2>&1; then
		sudo apk add --no-cache neovim
	elif command -v apt >/dev/null 2>&1; then
		sudo apt update && sudo apt install -y neovim
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y neovim
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y neovim
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper install -y neovim
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm neovim
	else
		echo "No supported package manager found. Please install Neovim manually."
		exit 1
	fi
}

uninstall_neovim() {
	if command -v brew >/dev/null 2>&1; then
		brew uninstall --ignore-dependencies neovim || true
	elif command -v apk >/dev/null 2>&1; then
		sudo apk del neovim || true
	elif command -v apt >/dev/null 2>&1; then
		sudo apt remove -y neovim || true
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf remove -y neovim || true
	elif command -v yum >/dev/null 2>&1; then
		sudo yum remove -y neovim || true
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper remove -y neovim || true
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Rns --noconfirm neovim || true
	fi
	if [ "$(uname)" = "Darwin" ]; then
		ARCH=$(uname -m)
		if [ "$ARCH" = "arm64" ]; then
			NVIM_TAR="nvim-macos-arm64.tar.gz"
		else
			NVIM_TAR="nvim-macos-x86_64.tar.gz"
		fi
		curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"
		tar xzf "$NVIM_TAR"
		sudo mv nvim-macos/bin/nvim /usr/local/bin/nvim
		rm -rf nvim-macos "$NVIM_TAR"
	elif [ "$(uname)" = "Linux" ]; then
		ARCH=$(uname -m)
		if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
			NVIM_TAR="nvim-linux-arm64.tar.gz"
			NVIM_DIR="nvim-linux-arm64"
		else
			NVIM_TAR="nvim-linux-x86_64.tar.gz"
			NVIM_DIR="nvim-linux64"
		fi
		curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"
		tar xzf "$NVIM_TAR"
		sudo mkdir -p /usr/local/bin /usr/local/lib /usr/local/share
		sudo cp -r "$NVIM_DIR"/bin/* /usr/local/bin/
		sudo cp -r "$NVIM_DIR"/lib/* /usr/local/lib/
		sudo cp -r "$NVIM_DIR"/share/* /usr/local/share/
		rm -rf "$NVIM_DIR" "$NVIM_TAR"
		# Ensure /usr/local/bin is in PATH
		if ! echo "$PATH" | grep -q "/usr/local/bin"; then
			SHELL_NAME=$(basename "$SHELL")
			if [ "$SHELL_NAME" = "zsh" ]; then
				CONFIG_FILE="$HOME/.zshrc"
			elif [ "$SHELL_NAME" = "bash" ]; then
				CONFIG_FILE="$HOME/.bashrc"
			else
				CONFIG_FILE="$HOME/.profile"
			fi
			echo 'export PATH="/usr/local/bin:$PATH"' >>"$CONFIG_FILE"
			echo "/usr/local/bin was not in your PATH. Added to $CONFIG_FILE. Please restart your shell or run: source $CONFIG_FILE"
		fi
	fi
}

install_treesitter() {
	if command -v tree-sitter >/dev/null 2>&1; then
		echo "tree-sitter already installed"
		return 0
	fi
	if command -v brew >/dev/null 2>&1; then
		brew install tree-sitter
	elif command -v apk >/dev/null 2>&1; then
		sudo apk add --no-cache tree-sitter tree-sitter-cli
	elif command -v apt >/dev/null 2>&1; then
		sudo apt install -y tree-sitter-cli
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y tree-sitter-cli
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y tree-sitter-cli
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper install -y tree-sitter-cli
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm tree-sitter-cli
	else
		echo "No known package manager found for tree-sitter"
	fi
}

# Main installation
echo "Installing Neovim..."
if command -v nvim >/dev/null 2>&1; then
	echo "Neovim found, upgrading to latest version..."
	uninstall_neovim
else
	echo "Installing Neovim from latest release..."
	uninstall_neovim
fi

echo "Installing tree-sitter CLI..."
install_treesitter

# Setup alias if not in standard config location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/nvim"

if [ "$SCRIPT_DIR" != "$CONFIG_DIR" ]; then
	echo "Setting up 'nvim-light' alias..."
	
	SHELL_NAME=$(basename "$SHELL")
	if [ "$SHELL_NAME" = "zsh" ]; then
		CONFIG_FILE="$HOME/.zshrc"
	elif [ "$SHELL_NAME" = "bash" ]; then
		CONFIG_FILE="$HOME/.bashrc"
	else
		CONFIG_FILE="$HOME/.profile"
	fi
	
	ALIAS_LINE="alias nvim-light='NVIM_APPNAME=nvim-light XDG_CONFIG_HOME=\"$(dirname "$SCRIPT_DIR")\" nvim'"
	
	# Check if alias already exists
	if ! grep -q "alias nvim-light=" "$CONFIG_FILE" 2>/dev/null; then
		echo "" >> "$CONFIG_FILE"
		echo "# nvim-light alias" >> "$CONFIG_FILE"
		echo "$ALIAS_LINE" >> "$CONFIG_FILE"
		echo "Added 'nvim-light' alias to $CONFIG_FILE"
		echo "Please restart your shell or run: source $CONFIG_FILE"
	else
		echo "'nvim-light' alias already exists in $CONFIG_FILE"
	fi
fi

echo "Installation complete!"
if [ "$SCRIPT_DIR" != "$CONFIG_DIR" ]; then
	echo "Run 'nvim-light' to start Neovim with this config (after restarting shell)."
else
	echo "Run 'nvim' to start Neovim."
fi
