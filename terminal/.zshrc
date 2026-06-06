# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set default text editor
export EDITOR='code -w'

# Ensure 256 color support
export TERM=xterm-256color

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Custom folder other than $ZSH/custom?
ZSH_CUSTOM="$DOTFILES/terminal"

# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    brew
    colored-man-pages
    colorize
    git
    macos
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Use case-sensitive completion.
# CASE_SENSITIVE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

source "$ZSH/oh-my-zsh.sh"