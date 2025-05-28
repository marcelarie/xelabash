# shellcheck shell=bash source="$HOME"

__xelabash_path() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
}

__xelabash_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

__xelabash_is_apple_terminal() {
  test "$TERM_PROGRAM" = 'Apple_Terminal'
}

clear() {
  command clear
  __xelabash_prompt
}

bind -x '"\C-l":clear'
bind -m vi-command '"\C-l": clear-screen'
bind -m vi-insert '"\C-l": clear-screen'

__xelabash_configure_completion() {
  bind 'set colored-stats on'
  bind 'set colored-completion-prefix on'
  bind 'set completion-ignore-case on'
  bind 'set completion-map-case on'
  bind 'set expand-tilde on'
  bind 'set mark-directories on'
  bind 'set mark-symlinked-directories on'
  bind 'set show-all-if-ambiguous on'
  bind 'set show-all-if-unmodified on'
  bind 'set skip-completed-text on'
  shopt -s 'cdspell'
  shopt -s 'checkwinsize'
  shopt -s 'dirspell'
}

__xelabash_configure_dircolors() {
  if [ -x "$(command -v dircolors)" ]; then
    if [ -r "$HOME/.dircolors" ]; then
      eval "$(dircolors -b "$HOME/.dircolors")"
    else
      eval "$(dircolors -b)"
     fi
  fi
}

__xelabash_configure_history() {
  if ! __xelabash_is_apple_terminal; then
    export HISTCONTROL='ignoreboth:erasedups'
    export HISTTIMEFORMAT='[%Y-%m-%d %T] '
    shopt -s 'histappend'
  fi
}

__xelabash_configure_variables() {
  export __xelabash_git_bin
  export __xelabash_kubectl_bin
  export __xelabash_nix_bin
  __xelabash_git_bin="$(command -v git)"
  __xelabash_kubectl_bin="$(command -v kubectl)"
  __xelabash_nix_bin="$(command -v nix)"
}

# load all configuration files
__xelabash_configure() {
  export __xelabash_PS1_last_exit
  export __xelabash_PS1_prefix
  export __xelabash_PS1_content
  export __xelabash_PS1_suffix

  __xelabash_configure_completion
  __xelabash_configure_dircolors
  __xelabash_configure_history
  __xelabash_configure_variables

  for config in "$(dirname "$(__xelabash_path)")"/config.d/*.bash; do
    source "$config"
  done
}

__in_nix_shell() {
  [[ -n "$IN_NIX_SHELL" ]] && return 0
  # Fallback heuristic for 'nix shell' and flakes shells:
  [[ ":$PATH:" == *":/nix/store:"* ]] && return 0
  return 1
}

# prepares the prompt variables
__xelabash_reset_prompt() {
  export __xelabash_PS1_last_exit="$?"
  export __xelabash_PS1_prefix=''
  if ! __xelabash_is_apple_terminal; then
    __xelabash_PS1_prefix='\[\e]0;\w\a\]'
  fi
  export __xelabash_PS1_content='\[\e[1m\]\w\[\e[0m\]'
  export __xelabash_PS1_suffix='\n \$ '
}

# make __xelabash_PS1_suffix red if the previous command failed
__xelabash_add_exit_code_to_prompt() {
  [ "$__xelabash_PS1_last_exit" -ne 0 ] && __xelabash_PS1_suffix="\[\e[31m\]${__xelabash_PS1_suffix}\[\e[0m\]"
}

# display git branch and repo state asterisk after path, if inside of a repository
__xelabash_add_git_to_prompt() {
  local prompt
  local branch
  local status_count

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = 'true' ] || [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" = 'true' ]; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ -z "$branch" ] && branch='(no branch)'
    if [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" != 'true' ]; then
      status_count="$(git status --porcelain | wc -l)"
    fi
  elif [ "$(git rev-parse --is-bare-repository 2>/dev/null)" = 'true' ]; then
    branch='(bare repo)'
  fi

  if [ -n "$branch" ]; then
    if [ "${status_count:-0}" -gt 0 ]; then
      prompt="\[\e[1;33m\]${branch}*\[\e[0m\]"
    else
      prompt="\[\e[36m\]${branch}\[\e[0m\]"
    fi
    __xelabash_PS1_content="${__xelabash_PS1_content:-} ${prompt}"
  fi
}

# display kubernetes context name and namespace
__xelabash_add_kube_to_prompt() {
  local context
  local namespace
  context="$(kubectl config view -o=jsonpath='{.current-context}')"
  namespace="$(kubectl config view -o=jsonpath="{.contexts[?(@.name==\"${context}\")].context.namespace}")"
  __xelabash_PS1_content="${__xelabash_PS1_content:-} \[\e[34m\]${context}${namespace:+:$namespace}\[\e[0m\]"
}

# prepend user@hostname to prompt, if connected via ssh
__xelabash_add_ssh_to_prompt() {
  if [ -n "$SSH_CONNECTION" ]; then
    __xelabash_PS1_prefix='\[\e]0;\u@\h \w\a\]'
    __xelabash_PS1_content="\[\e[2m\]\u@\h\[\e[0m\] ${__xelabash_PS1_content}"
  fi
}

__xelabash_add_nix_indicator() {
    if __in_nix_shell; then
    if [[ "$IN_NIX_SHELL" == "impure" ]]; then
      __xelabash_PS1_prefix="(impure) ${__xelabash_PS1_prefix}"
    fi
    if [[ "$IN_NIX_SHELL" == "1" ]]; then
      __xelabash_PS1_prefix="(dev) ${__xelabash_PS1_prefix}"
    fi
    # __xelabash_PS1_prefix="❆ ${__xelabash_PS1_prefix}"
    __xelabash_PS1_prefix="❄️ ${__xelabash_PS1_prefix}"
    fi
}

__xelabash_add_vi_mode_indicator() {
  bind 'set show-mode-in-prompt on'
  bind "set vi-ins-mode-string \1\e[1;38;2;19;194;153mi\e[0m\2"
  bind "set vi-cmd-mode-string \1\e[1;38;2;226;187;5mn\e[0m\2"
}


# set the prompt
__xelabash_prompt() {
  __xelabash_reset_prompt
  __xelabash_add_exit_code_to_prompt
  __xelabash_add_ssh_to_prompt
  [ -n "$GIT_PROMPT" ] && [ -n "$__xelabash_git_bin" ] && __xelabash_add_git_to_prompt
  [ -n "$KUBE_PROMPT" ] && [ -n "$__xelabash_kubectl_bin" ] && __xelabash_add_kube_to_prompt
  [ -n "$NIX_PROMPT" ] && [ -n "$__xelabash_nix_bin" ] && __xelabash_add_nix_indicator
  [ -n "$VI_MODE_PROMPT" ] && __xelabash_add_vi_mode_indicator
  export PS1="${__xelabash_PS1_prefix:-}${__xelabash_PS1_content:-}${__xelabash_PS1_suffix:-}"
  history -a
  __xelabash_cleanup
}

# clean up shared xelabash variables
__xelabash_cleanup() {
  unset __xelabash_PS1_prefix \
        __xelabash_PS1_content \
        __xelabash_PS1_suffix \
        __xelabash_PS1_last_exit
}

# do the thing!
__xelabash_init() {
  if [[ "$-" == *i* ]]; then
    __xelabash_configure
    if [[ "$PROMPT_COMMAND" != *__xelabash_prompt* ]]; then
      export PROMPT_COMMAND="__xelabash_prompt;$PROMPT_COMMAND"
    fi
  fi
}

if [ -z "${__xelabash_skip_init:-}" ]; then
  __xelabash_init
fi
