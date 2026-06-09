# Enable and initialize the completion system
autoload -Uz +X compinit && compinit
source $HOME/.config/fzf-tab/fzf-tab.plugin.zsh

export LS_COLORS="di=38;5;81:fi=38;5;250"
zstyle ':fzf-tab:*' popup-min-size 80 10

zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no 
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  '[[ -d $realpath ]] && eza -1 --color=always "$realpath"'

# custom fzf flags
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept 
# To make fzf-tab follow FZF_DEFAULT_OPTS.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':completion:*' format '%d'

# =====================================================================

# ALIASES

# bat alias
alias cat="bat --wrap=auto --style='numbers,header,header-filesize' --theme='Catppuccin Frappe'"

# eza aliases
alias ls="eza --color=always --long --git --no-user --no-permissions --icons=always --no-time --group-directories-first"
alias lt="eza --color=always --long --git --no-user --no-permissions --icons=always --no-time --group-directories-first --tree --level=3 --ignore-glob='node_modules|dist|build|.next'"
alias ll="eza -a --color=always --no-user --long --git --icons=always --no-time --group-directories-first"

# lazygit
alias lg="lazygit"

# fzf
alias vf='nvim "$(fzf)"'

# system aliases
alias c="clear"
alias nq="networkquality"
alias md="mkdir -p"
alias rm="rm -rI"

# =====================================================================

# VARIABLES

# fzf
export FZF_DEFAULT_OPTS=' --height=40%  --color=fg:#c0caf5,fg+:#7dcfff,hl:#7aa2f7,hl+:#ff9e64,pointer:#f7768e,marker:#9ece6a,header:#7dcfff'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow \
  --exclude .git --exclude node_modules --exclude .cache \
  --exclude .zsh_sessions --exclude .DS_Store --exclude __pycache__\
  --exclude Library --exclude languageserver --exclude .local \
  --exclude .m2 --exclude languageserver-library --exclude .vscode'

# java variables
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH="$JAVA_HOME/bin:$PATH"

# git
export PAGER="bat --wrap=auto --style='numbers' --theme 'Catppuccin Frappe'"

# Config
export PATH="$(brew --prefix)/opt/libtool/libexec/gnubin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"

# Starship
eval "$(starship init zsh)"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"

# =====================================================================

# Plugins
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /Users/ponteski/.config/zsh-you-should-use/you-should-use.plugin.zsh
source /Users/ponteski/.config/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/ponteski/.config/git.plugin.zsh
source /Users/ponteski/.config/zsh-extract-master/extract.plugin.zsh


export _ZO_DOCTOR=0
eval "$(zoxide init --cmd cd zsh)"

eval "$(gh copilot alias -- zsh)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/ponteski/.config/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/ponteski/.config/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/ponteski/.config/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/ponteski/.config/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/Users/ponteski/.config/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/Users/ponteski/.config/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
