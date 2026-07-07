alias vi=nvim
alias vim=nvim

# color support + handy ls aliases (shared by bash & zsh; the dircolors eval
# that sets LS_COLORS stays per-shell in ~/.bashrc and ~/.zshrc)
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# `tmux dev` -> 2x2 agent grid; everything else passes through to real tmux
tmux() {
  if [ "$1" = "dev" ]; then
    dev
  else
    command tmux "$@"
  fi
}
