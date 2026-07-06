alias vi=nvim
alias vim=nvim
# `tmux dev` -> 2x2 agent grid; everything else passes through to real tmux
tmux() {
  if [ "$1" = "dev" ]; then
    dev
  else
    command tmux "$@"
  fi
}
