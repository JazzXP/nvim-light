#!/usr/bin/env bash
#
# Installs the latest Neovim and the latest tree-sitter CLI, then (optionally)
# sets up an `nvim-light` alias that points at this config directory.
#
# Usage: ./install.sh [--user] [--prefix=DIR] [-h|--help]
#   --user         Install into ~/.local instead of /usr/local (no sudo needed)
#   --prefix=DIR   Install into DIR (binaries go in DIR/bin)
#
# Strategy (each step falls through to the next on failure):
#   Neovim:       brew (macOS) -> official release -> neovim-releases (old glibc)
#                 -> build from source -> distro package
#   tree-sitter:  brew (macOS) -> release binary -> npm -> cargo -> distro package

set -u
set -o pipefail

OS="$(uname -s)"
ARCH_RAW="$(uname -m)"
FAILED=0
APT_UPDATED=0
PM=""
SUDO=""
PKG_SUDO=""
EXTRA_PATH_DIRS=""
PREFIX="${PREFIX:-}"
USER_INSTALL=0

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
	sed -n '2,13p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
	case "$arg" in
	--user) USER_INSTALL=1 ;;
	--prefix=*) PREFIX="${arg#--prefix=}" ;;
	-h | --help)
		usage
		exit 0
		;;
	*) die "unknown option: $arg" ;;
	esac
done

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

case "$ARCH_RAW" in
x86_64 | amd64) ARCH="x86_64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*) ARCH="$ARCH_RAW" ;;
esac

is_musl() {
	[ "$OS" = "Linux" ] || return 1
	if have ldd && ldd --version 2>&1 | grep -qi musl; then
		return 0
	fi
	ls /lib/ld-musl-* >/dev/null 2>&1
}

detect_pm() {
	local p
	for p in apt-get dnf yum zypper pacman apk; do
		if have "$p"; then
			PM="$p"
			return 0
		fi
	done
	return 1
}

setup_privileges() {
	if [ -z "$PREFIX" ]; then
		if [ "$USER_INSTALL" -eq 1 ]; then
			PREFIX="$HOME/.local"
		elif [ "$(id -u)" -eq 0 ] || have sudo; then
			PREFIX="/usr/local"
		else
			PREFIX="$HOME/.local"
		fi
	fi

	if mkdir -p "$PREFIX/bin" 2>/dev/null && [ -w "$PREFIX/bin" ]; then
		SUDO=""
	elif [ "$(id -u)" -ne 0 ] && have sudo; then
		SUDO="sudo"
		$SUDO mkdir -p "$PREFIX/bin" || die "cannot create $PREFIX/bin"
	else
		die "cannot write to $PREFIX/bin (try --user or run as root)"
	fi

	if [ "$(id -u)" -eq 0 ]; then
		PKG_SUDO=""
	elif have sudo; then
		PKG_SUDO="sudo"
	fi
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# download URL DEST   (DEST may be "-" for stdout)
download() {
	if have curl; then
		curl -fsSL --retry 3 --connect-timeout 20 -o "$2" "$1"
	elif have wget; then
		wget -q -O "$2" "$1"
	else
		return 1
	fi
}

# latest_tag owner/repo -> prints the latest release tag
latest_tag() {
	local repo="$1" url tag=""
	if have curl; then
		url="$(curl -fsSL --retry 3 --connect-timeout 20 -o /dev/null -w '%{url_effective}' \
			"https://github.com/$repo/releases/latest" 2>/dev/null)" && tag="${url##*/}"
	fi
	if ! printf '%s' "$tag" | grep -Eq '^v?[0-9]+\.[0-9]+'; then
		tag="$(download "https://api.github.com/repos/$repo/releases/latest" - 2>/dev/null |
			grep -m1 '"tag_name"' |
			sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
	fi
	printf '%s' "$tag" | grep -Eq '^v?[0-9]+\.[0-9]+' || return 1
	printf '%s\n' "$tag"
}

# ver_lt A B -> success if A < B (numeric, dot separated, up to 3 parts)
ver_lt() {
	local IFS=.
	local -a a=($1) b=($2)
	local i x y
	for i in 0 1 2; do
		x="${a[i]:-0}"
		y="${b[i]:-0}"
		x=$((10#$x))
		y=$((10#$y))
		[ "$x" -lt "$y" ] && return 0
		[ "$x" -gt "$y" ] && return 1
	done
	return 1
}

nvim_version() {
	local v=""
	if have nvim; then
		v="$(nvim --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
	fi
	printf '%s\n' "${v:-0.0.0}"
}

ts_version() {
	local v=""
	if have tree-sitter; then
		v="$(tree-sitter --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
	fi
	printf '%s\n' "${v:-0.0.0}"
}

pm_install() {
	case "$PM" in
	apt-get)
		if [ "$APT_UPDATED" -eq 0 ]; then
			$PKG_SUDO apt-get update || warn "apt-get update failed (old/EOL release?)"
			APT_UPDATED=1
		fi
		$PKG_SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
		;;
	dnf) $PKG_SUDO dnf install -y "$@" ;;
	yum) $PKG_SUDO yum install -y "$@" ;;
	zypper) $PKG_SUDO zypper --non-interactive install "$@" ;;
	pacman) $PKG_SUDO pacman -S --noconfirm --needed "$@" ;;
	apk) $PKG_SUDO apk add --no-cache "$@" ;;
	*) return 1 ;;
	esac
}

# Install the basics needed to download/extract things, and a C compiler
# (nvim-treesitter compiles parsers).
ensure_basic_deps() {
	[ "$OS" = "Linux" ] || return 0
	detect_pm || {
		warn "no supported package manager found; skipping dependency install"
		return 0
	}
	local missing=()
	have curl || have wget || missing+=("curl" "ca-certificates")
	have tar || missing+=("tar")
	have gzip || missing+=("gzip")
	have git || missing+=("git")
	if ! have cc && ! have gcc; then
		if [ "$PM" = "apk" ]; then
			missing+=("gcc" "musl-dev" "make")
		else
			missing+=("gcc" "make")
		fi
	fi
	if [ "${#missing[@]}" -gt 0 ]; then
		log "Installing missing dependencies: ${missing[*]}"
		pm_install "${missing[@]}" || warn "could not install: ${missing[*]}"
	fi
	have curl || have wget || die "need curl or wget to download releases"
	have tar || die "tar is required"
	have gzip || die "gzip is required"
}

# ---------------------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------------------

# Extract a Neovim release tarball and install it under $PREFIX/lib/neovim,
# with a symlink in $PREFIX/bin. Fails (without touching anything) if the
# binary cannot run on this system, e.g. because the glibc is too old.
install_nvim_tarball() {
	local url="$1" tmp top
	tmp="$(mktemp -d)" || return 1
	if ! download "$url" "$tmp/nvim.tar.gz"; then
		rm -rf "$tmp"
		return 1
	fi
	if ! tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"; then
		rm -rf "$tmp"
		return 1
	fi
	top="$(cd "$tmp" && ls -d nvim-*/ 2>/dev/null | head -n 1)"
	top="${top%/}"
	if [ -z "$top" ] || ! "$tmp/$top/bin/nvim" --version >/dev/null 2>&1; then
		rm -rf "$tmp"
		return 1
	fi
	$SUDO rm -rf "$PREFIX/lib/neovim"
	$SUDO mkdir -p "$PREFIX/lib" "$PREFIX/bin"
	$SUDO mv "$tmp/$top" "$PREFIX/lib/neovim" || {
		rm -rf "$tmp"
		return 1
	}
	$SUDO ln -sf "$PREFIX/lib/neovim/bin/nvim" "$PREFIX/bin/nvim"
	rm -rf "$tmp"
}

install_build_deps() {
	detect_pm || return 1
	case "$PM" in
	apt-get) pm_install ninja-build gettext cmake unzip curl build-essential ;;
	dnf | yum) pm_install ninja-build cmake gcc gcc-c++ make unzip gettext curl ;;
	zypper) pm_install ninja cmake gcc-c++ make gettext-tools unzip curl ;;
	pacman) pm_install base-devel cmake unzip ninja curl ;;
	apk) pm_install build-base cmake coreutils curl gettext-dev unzip ninja ;;
	*) return 1 ;;
	esac
}

build_nvim_from_source() {
	local tag="$1" tmp src
	log "Building Neovim $tag from source (this can take several minutes)..."
	install_build_deps || warn "could not install all build dependencies"
	have cmake || return 1
	have make || return 1
	tmp="$(mktemp -d)" || return 1
	if ! download "https://github.com/neovim/neovim/archive/refs/tags/$tag.tar.gz" "$tmp/src.tar.gz" ||
		! tar -xzf "$tmp/src.tar.gz" -C "$tmp"; then
		rm -rf "$tmp"
		return 1
	fi
	src="$(cd "$tmp" && ls -d neovim-*/ 2>/dev/null | head -n 1)"
	src="$tmp/${src%/}"
	if ! (cd "$src" && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$PREFIX") ||
		! (cd "$src" && $SUDO make install); then
		rm -rf "$tmp"
		return 1
	fi
	rm -rf "$tmp"
}

install_neovim() {
	local tag ver cur asset
	cur="$(nvim_version)"
	if ! tag="$(latest_tag neovim/neovim)"; then
		if [ "$cur" != "0.0.0" ]; then
			warn "could not determine the latest Neovim release; keeping $cur"
			return 0
		fi
		warn "could not determine the latest Neovim release"
		FAILED=1
		return 1
	fi
	ver="${tag#v}"
	log "Neovim: installed=$cur latest=$ver"

	if ! ver_lt "$cur" "$ver"; then
		log "Neovim is up to date"
		return 0
	fi

	if [ "$OS" = "Darwin" ]; then
		if have brew; then
			if brew list neovim >/dev/null 2>&1; then
				brew upgrade neovim || true
			else
				brew install neovim || true
			fi
			ver_lt "$(nvim_version)" "$ver" || return 0
		fi
		if [ "$ARCH" = "arm64" ]; then asset="nvim-macos-arm64"; else asset="nvim-macos-x86_64"; fi
		log "Installing Neovim $ver from GitHub releases..."
		install_nvim_tarball "https://github.com/neovim/neovim/releases/download/$tag/$asset.tar.gz" && return 0
		warn "failed to install Neovim on macOS"
		FAILED=1
		return 1
	fi

	if [ "$OS" = "Linux" ]; then
		case "$ARCH" in
		x86_64 | arm64)
			asset="nvim-linux-$ARCH"
			if ! is_musl; then
				log "Installing Neovim $ver from official release..."
				install_nvim_tarball "https://github.com/neovim/neovim/releases/download/$tag/$asset.tar.gz" && return 0
				warn "official build did not run here (glibc too old?); trying neovim-releases build for older glibc..."
				install_nvim_tarball "https://github.com/neovim/neovim-releases/releases/download/$tag/$asset.tar.gz" && return 0
			fi
			;;
		esac

		warn "no usable prebuilt Neovim for this system ($OS $ARCH_RAW$(is_musl && printf ' musl')); falling back to source build"
		build_nvim_from_source "$tag" && return 0

		warn "source build failed; falling back to the distro package (may be older than $ver)"
		if detect_pm && pm_install neovim; then
			return 0
		fi
	fi

	warn "Neovim installation failed. Install it manually: https://github.com/neovim/neovim/releases"
	FAILED=1
	return 1
}

# ---------------------------------------------------------------------------
# tree-sitter CLI
# ---------------------------------------------------------------------------

install_ts_release() {
	local tag="$1" plat tmp
	case "$OS-$ARCH" in
	Linux-x86_64) plat="linux-x64" ;;
	Linux-arm64) plat="linux-arm64" ;;
	Darwin-x86_64) plat="macos-x64" ;;
	Darwin-arm64) plat="macos-arm64" ;;
	*) return 1 ;;
	esac
	is_musl && return 1
	tmp="$(mktemp -d)" || return 1
	if ! download "https://github.com/tree-sitter/tree-sitter/releases/download/$tag/tree-sitter-$plat.gz" "$tmp/ts.gz" ||
		! gzip -dc "$tmp/ts.gz" >"$tmp/tree-sitter"; then
		rm -rf "$tmp"
		return 1
	fi
	chmod +x "$tmp/tree-sitter"
	if ! "$tmp/tree-sitter" --version >/dev/null 2>&1; then
		rm -rf "$tmp"
		return 1
	fi
	$SUDO mkdir -p "$PREFIX/bin"
	$SUDO install -m 755 "$tmp/tree-sitter" "$PREFIX/bin/tree-sitter"
	local rc=$?
	rm -rf "$tmp"
	return $rc
}

install_treesitter() {
	local tag ver cur
	cur="$(ts_version)"
	if ! tag="$(latest_tag tree-sitter/tree-sitter)"; then
		if [ "$cur" != "0.0.0" ]; then
			warn "could not determine the latest tree-sitter release; keeping $cur"
			return 0
		fi
		warn "could not determine the latest tree-sitter release"
		FAILED=1
		return 1
	fi
	ver="${tag#v}"
	log "tree-sitter CLI: installed=$cur latest=$ver"

	if ! ver_lt "$cur" "$ver"; then
		log "tree-sitter CLI is up to date"
		return 0
	fi

	if [ "$OS" = "Darwin" ] && have brew; then
		brew install tree-sitter-cli 2>/dev/null || brew upgrade tree-sitter-cli 2>/dev/null ||
			brew install tree-sitter 2>/dev/null || true
		ver_lt "$(ts_version)" "$ver" || return 0
	fi

	log "Installing tree-sitter CLI $ver from GitHub releases..."
	install_ts_release "$tag" && return 0

	if have npm; then
		warn "release binary unusable here; trying npm..."
		$SUDO npm install -g --prefix "$PREFIX" tree-sitter-cli && have tree-sitter && return 0
	fi

	if have cargo; then
		warn "trying cargo (this compiles from source)..."
		if cargo install tree-sitter-cli --locked; then
			EXTRA_PATH_DIRS="$EXTRA_PATH_DIRS $HOME/.cargo/bin"
			return 0
		fi
	fi

	if [ "$OS" = "Linux" ] && detect_pm; then
		warn "falling back to the distro package (may be older than $ver)"
		pm_install tree-sitter-cli && return 0
	fi

	warn "tree-sitter CLI installation failed. See https://github.com/tree-sitter/tree-sitter/releases"
	FAILED=1
	return 1
}

# ---------------------------------------------------------------------------
# Shell configuration
# ---------------------------------------------------------------------------

shell_rc_file() {
	case "$(basename "${SHELL:-}")" in
	zsh) echo "$HOME/.zshrc" ;;
	bash)
		if [ "$OS" = "Darwin" ]; then echo "$HOME/.bash_profile"; else echo "$HOME/.bashrc"; fi
		;;
	fish) echo "$HOME/.config/fish/config.fish" ;;
	*) echo "$HOME/.profile" ;;
	esac
}

ensure_path() {
	local dir rc
	rc="$(shell_rc_file)"
	for dir in "$PREFIX/bin" $EXTRA_PATH_DIRS; do
		[ -d "$dir" ] || continue
		case ":$PATH:" in
		*":$dir:"*) continue ;;
		esac
		mkdir -p "$(dirname "$rc")"
		if ! grep -qF "$dir" "$rc" 2>/dev/null; then
			if [ "$(basename "${SHELL:-}")" = "fish" ]; then
				printf '\nfish_add_path "%s"\n' "$dir" >>"$rc"
			else
				printf '\nexport PATH="%s:$PATH"\n' "$dir" >>"$rc"
			fi
			log "$dir was not in your PATH. Added it to $rc (restart your shell or: source $rc)"
		fi
		export PATH="$dir:$PATH"
	done
}

setup_alias() {
	local script_path script_dir config_dir rc name parent alias_line tmp
	script_path="${BASH_SOURCE[0]:-$0}"
	[ -f "$script_path" ] || return 0 # e.g. piped through curl | bash
	script_dir="$(cd "$(dirname "$script_path")" && pwd -P)"
	config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
	ALIAS_INSTALLED=0
	# Only set up the alias when this config is NOT already installed at
	# $XDG_CONFIG_HOME/nvim (default ~/.config/nvim), resolving symlinks so a
	# symlink to this dir counts.
	if [ -d "$config_dir" ]; then
		local resolved
		resolved="$(cd "$config_dir" && pwd -P)"
		if [ "$script_dir" = "$resolved" ]; then
			log "Config is installed at $config_dir; skipping 'nvim-light' alias"
			return 0
		fi
	fi

	name="$(basename "$script_dir")"
	parent="$(dirname "$script_dir")"
	rc="$(shell_rc_file)"
	alias_line="alias nvim-light='env NVIM_APPNAME=\"$name\" XDG_CONFIG_HOME=\"$parent\" nvim'"

	mkdir -p "$(dirname "$rc")"
	touch "$rc"
	# Replace any previous nvim-light alias so a moved checkout gets fixed.
	tmp="$(mktemp)"
	grep -v -e '^alias nvim-light=' -e '^# nvim-light alias$' "$rc" >"$tmp" || true
	cat "$tmp" >"$rc"
	rm -f "$tmp"
	{
		printf '\n# nvim-light alias\n'
		printf '%s\n' "$alias_line"
	} >>"$rc"
	log "Set up 'nvim-light' alias in $rc (restart your shell or: source $rc)"
	ALIAS_INSTALLED=1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

ALIAS_INSTALLED=0

main() {
	[ "$OS" = "Linux" ] || [ "$OS" = "Darwin" ] || die "unsupported OS: $OS"
	setup_privileges
	log "Install prefix: $PREFIX"
	ensure_basic_deps

	install_neovim
	install_treesitter

	ensure_path
	hash -r 2>/dev/null || true
	setup_alias

	echo
	log "Summary"
	echo "    neovim:      $(nvim_version) ($(command -v nvim || echo 'not found'))"
	echo "    tree-sitter: $(ts_version) ($(command -v tree-sitter || echo 'not found'))"

	if have nvim && [ "$(command -v nvim)" != "$PREFIX/bin/nvim" ] && [ "$OS" = "Linux" ]; then
		warn "another nvim ($(command -v nvim)) comes first in PATH; ensure $PREFIX/bin precedes it"
	fi

	if [ "$FAILED" -ne 0 ]; then
		echo
		warn "Installation finished with errors (see warnings above)."
		exit 1
	fi

	echo
	log "Installation complete!"
	if [ "$ALIAS_INSTALLED" -eq 1 ]; then
		echo "    Run 'nvim-light' to start Neovim with this config (after restarting your shell)."
	else
		echo "    Run 'nvim' to start Neovim."
	fi
}

main "$@"
