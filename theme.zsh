# turns path like '/home/user/foo/bar/baz' into '~/f/b/baz'
function prompt_russtone_pwd {
	local pwd="${1/#$HOME/~}"
	local head tail

	if [[ $pwd == [~/] ]]; then
		echo $pwd
	else
		head="${(@j:/:M)${(@s:/:)${pwd:h}}##.#?}"
		head=${head%%/}
		head=${head//\%/%%}
		tail=${pwd:t}
		tail=${tail//\%/%%}
		echo "$head/$tail"
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
	local start=${1:-$stop}
	integer elapsed=$stop-$start
	if (( $elapsed > 5 )); then
		echo $(prompt_russtone_human_time $elapsed)
	else
		echo ''
	fi
}

# Preexec hook
function prompt_russtone_preexec {
	# Save timestamp before executing command
	_prompt_russtone_timestamp_start=$(date +%s)
}


# Precmd hook
function prompt_russtone_precmd {
	# Format PWD
	_prompt_russtone_pwd=$(prompt_russtone_pwd $PWD)

	# Format elapsed time
	_prompt_russtone_elapsed_time=$(prompt_russtone_elapsed_time $_prompt_russtone_timestamp_start)
	unset _prompt_russtone_timestamp_start

	if (( $+functions[vcs_info] )); then
		vcs_info
	fi
}

# Git set-message hook
# Adds '!' to vsc_info untracked (%u) if there are untracked files in repo
function +vi-git-untracked {
	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]] && \
		git status --porcelain | grep '??' &> /dev/null ; then
		hook_com[unstaged]='%F{red}%B!%b%f'
	fi
}


# Git set-message hook
# Adds count of ahead commits to vcs_info misc (%m)
function +vi-git-st() {
	local ahead
	local -a gitstatus

	ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
	(( $ahead )) && gitstatus+=( "%F{green}⇡${ahead// /}%f" )
	behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)
	(( $behind )) && gitstatus+=( "%F{green}⇣${behind// /}%f" )

	hook_com[misc]+=${(j: :)gitstatus}
}

# Main
function prompt_russtone_setup {

	# Expand variables in PROMPT
	setopt PROMPT_SUBST
	setopt EXTENDED_GLOB

	# Load required functions
	autoload -Uz add-zsh-hook

	# Add hooks
	add-zsh-hook precmd prompt_russtone_precmd
	add-zsh-hook preexec prompt_russtone_preexec

	# vsc_info
	autoload -Uz vcs_info
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:git:*' check-for-changes true
	zstyle ':vcs_info:git:*' stagedstr "%F{yellow}%B!%b%f"
	zstyle ':vcs_info:git:*' unstagedstr "%F{red}%B!%b%f"
	zstyle ':vcs_info:git*' formats "%F{magenta}(%b)%f%u%c %m"
	zstyle ':vcs_info:git*+set-message:*' hooks \
	                                      git-untracked \
	                                      git-st

	PROMPT='
%F{blue}${_prompt_russtone_pwd}%f ${vcs_info_msg_0_}
%F{green}➜ %f '

	RPROMPT='%F{yellow}${_prompt_russtone_elapsed_time}%f'

}

prompt_russtone_setup
