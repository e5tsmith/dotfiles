# ~/.zshrc

# PATH stays self-deduplicating no matter how often this file is re-sourced
typeset -U path PATH

# --- history ---
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=200000
setopt SHARE_HISTORY        # panes see each other's history live
setopt HIST_IGNORE_SPACE    # leading space = kept out of history
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY     # timestamps

# --- line editing: emacs mode ---
bindkey -e

# Ctrl+X Ctrl+E -> edit line in nvim, return WITHOUT executing
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# --- completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# --- navigation ---
setopt AUTO_CD                          # a bare dir name cd's into it
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS     # every cd remembered: cd -<Tab>

# named directories (also abbreviate the prompt)
hash -d e5c=~/github/e5-clients
hash -d navy=~/github/e5-clients/Clients/Navy
hash -d dot=~/github/dotfiles

# --- environment ---
export VISUAL=nvim
export EDITOR="$VISUAL"
export PATH="$HOME/.local/bin:$PATH"

# nvm (node / npm / npx / claude) — mirrors ~/.bashrc; no bash_completion in zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# color support for ls (sets LS_COLORS) — mirrors the dircolors eval in ~/.bashrc
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# make less friendly for non-text input (LESSOPEN) — mirrors ~/.bashrc
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# local, non-git secrets (Octopus API key, etc.) — mirrors ~/.bashrc
[ -f "$HOME/.config/e5/secrets.env" ] && . "$HOME/.config/e5/secrets.env"

# --- shared aliases & wrappers (the same file bash uses) ---
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# --- prompt: green left, git branch flush-right ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{yellow}%b%f'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
RPROMPT='${vcs_info_msg_0_}'

# --- fzf (uncomment if/when installed): fuzzy Ctrl+R / Ctrl+T / Alt+C ---
# source /usr/share/doc/fzf/examples/key-bindings.zsh

# --- the two headline plugins ---
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax highlighting must be sourced LAST
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
