#!/usr/bin/env bash
set -eu

echo "Setting up your Mac..."

# Ask for sudo once, keep-alive
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# --------------------
# User-defined variables
# --------------------

read -rp "Connect to the internet then press enter to continue... " _

read -rp "Enter your git user name: " git_name
read -rp "Enter your git email: " git_email

# --------------------
# Pre-requisites
# --------------------

echo "Installing pre-requisites..."

# Install Xcode
if xcode-select -p >/dev/null 2>&1; then
  echo "Xcode command line tools already installed"
else
  echo "Installing Xcode command line tools"
  xcode-select --install || true
fi

# Install Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh is already installed"
else
  echo "Installing Oh My Zsh. You may need to run this script again after it finishes."
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Check for Homebrew and install if we don't have it
if command -v brew &>/dev/null; then
  echo "Homebrew is already installed"
else
  echo "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Locate brew and eval shellenv without relying on PATH yet
BREW_BIN=""
for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$p" ] && BREW_BIN="$p" && break
done
[ -z "$BREW_BIN" ] && BREW_BIN="$(command -v brew || true)"
if [ -z "$BREW_BIN" ]; then
  echo "Error: brew not found after install"; exit 1
fi
eval "$("$BREW_BIN" shellenv)"  # makes brew usable now
HOMEBREW_PREFIX="$(brew --prefix)"

# --------------------
# Symlinks
# --------------------

echo "Creating symlinks..."

# Helper: safe idempotent symlink maker
link() {
  # link <target> <linkpath>
  local target="$1" linkpath="$2"
  mkdir -p "$(dirname "$linkpath")"
  if [ -L "$linkpath" ] || [ -e "$linkpath" ]; then
    if [ "$(readlink "$linkpath" 2>/dev/null || true)" = "$target" ]; then
      echo "✓ $linkpath already -> $target"
      return 0
    else
      rm -rf "$linkpath"
    fi
  fi
  ln -s "$target" "$linkpath"
  echo "→ $linkpath -> $target"
}

# zprofile (login shell)
link "$HOME/.dotfiles/terminal/.zprofile" "$HOME/.zprofile"

# zshrc (interactive shell)
link "$HOME/.dotfiles/terminal/.zshrc" "$HOME/.zshrc"

# Git
link "$HOME/.dotfiles/git/.gitconfig" "$HOME/.gitconfig"
cat > "$HOME/.gitconfig.local" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
echo "Git user configured: $git_name <$git_email>"

# VS Code
link "$HOME/.dotfiles/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# Claude
link "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
link "$HOME/.dotfiles/claude/skills" "$HOME/.claude/skills"

# Others
link "$HOME/.dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"

# --------------------
# Install applications
# --------------------

source "$HOME/.dotfiles/brew/install.sh"

VS_CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [ -x "$VS_CODE" ]; then
  ln -sf "$VS_CODE" "$HOMEBREW_PREFIX/bin/code"
  echo "→ Installed 'code' CLI to $HOMEBREW_PREFIX/bin/code"
else
  echo "⚠️ Visual Studio Code.app not found at $VS_CODE; install it via 'brew install --cask visual-studio-code' later."
fi

source "$HOME/.dotfiles/vscode/extensions.sh"
source "$HOME/.dotfiles/terminal/install.sh"
source "$HOME/.dotfiles/tmux/install.sh"
source "$HOME/.dotfiles/javascript/install.sh"
source "$HOME/.dotfiles/python/install.sh"

# --------------------
# macOS settings
# --------------------

source "$HOME/.dotfiles/os/macos.sh"

echo -n "Log in to your Google Drive then press enter to continue... "
read check

echo "Set up of your Mac is completed. It is recommended to restart the computer to apply all changes."
echo 'Enjoy!'
