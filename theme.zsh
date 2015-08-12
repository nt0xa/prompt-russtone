# turns path like '/home/user/foo/bar/baz' into '~/f/b/baz'
function prompt_russtone_pwd {
  local pwd="${PWD/#$HOME/~}"

  if [[ "$pwd" == "~" ]]; then
    _prompt_russtone_pwd="~"
    unset MATCH
  else
    # ${(@s:/:)var}  - split var by "/"
    # ${var##pat}    - remove pattern from beginning of var
    # ${(M)var##pat} - remove all except match pat (reversed previous)
    # ${(@j:/:)arr}  - join arr with separators "/"
    # ${var%pat}     - remove pat from tail of var
    # ${PWD:h}       - all except last dir
    # ${PWD:t}       - only last dir
    # ${var//s1/s2}  - replace s1 with s2 in var
    _prompt_russtone_pwd="${${${${(@j:/:M)${(@s:/:)pwd}##(.|)?}:h}%/}//\%/%%}/${${pwd:t}//\%/%%}"
  fi
}

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
function prompt_russtone_human_time {
  echo -n " "
  local tmp=$1
  local days=$(( tmp / 60 / 60 / 24 ))
  local hours=$(( tmp / 60 / 60 % 24 ))
  local minutes=$(( tmp / 60 % 60 ))
  local seconds=$(( tmp % 60 ))
  (( $days > 0 )) && echo -n "${days}d "
  (( $hours > 0 )) && echo -n "${hours}h "
  (( $minutes > 0 )) && echo -n "${minutes}m "
  echo "${seconds}s"
}

# Calc elapsed time and save it to _prompt_russtone_elapsed_time (if > 5s)
function prompt_russtone_elapsed_time {
  local stop=$(date +%s)
  local start=${_prompt_russtone_timestamp_start:-$stop}
  integer elapsed=$stop-$start
  unset _prompt_russtone_timestamp_start
  if (( $elapsed > 5 )); then
    _prompt_russtone_elapsed_time=$(prompt_russtone_human_time $elapsed)
  else
    _prompt_russtone_elapsed_time=''
  fi
}

function zle-line-init zle-keymap-select {
  _prompt_russtone_vi_mode="${${KEYMAP/vicmd/%F{yellow}◼︎ %f/(main|viins}/%F{green}➜ %f}"
  zle reset-prompt
}

# Preexec hook
function prompt_russtone_preexec {
  # Save timestamp before executing command
  _prompt_russtone_timestamp_start=$(date +%s)
}


# Precmd hook
function prompt_russtone_precmd {
  # Format PWD
  prompt_russtone_pwd

  # Format elapsed time
  prompt_russtone_elapsed_time
}

# Main
function prompt_russtone_setup {

  # Load required functions
  autoload -Uz add-zsh-hook

  # Add hooks
  add-zsh-hook precmd prompt_russtone_precmd
  add-zsh-hook preexec prompt_russtone_preexec
  zle -N zle-line-init
  zle -N zle-keymap-select

  PROMPT='
${SSH_TTY:+"%F{red}%n%f%F{white}@%f%F{yellow}%M%f "}%F{blue}${_prompt_russtone_pwd}%f$(git_super_status)
${_prompt_russtone_vi_mode} '

  RPROMPT='%F{yellow}${_prompt_russtone_elapsed_time}%f'

}

prompt_russtone_setup