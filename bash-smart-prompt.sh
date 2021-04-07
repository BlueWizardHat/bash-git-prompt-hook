#
# Setup a nice and powerful two-line bash prompt
#

# Put calculation of terminal width so it comes after the timer, but before the git hook
if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="ps1_pre_prompt"
else
	PROMPT_COMMAND="ps1_pre_prompt; $PROMPT_COMMAND"
fi

# Get the timer functionality
source "${GIT_PROMPT_DIR}/bash-command-timer-hook.sh"

# Make sure we save the status of the last command
PROMPT_COMMAND="last_status=\$?; $PROMPT_COMMAND"

#
# Now set up the prompt
#

ps1_pre_prompt() {
	columns=${COLUMNS:-$(tput cols)}
	printf -v lp "${PS1_LINE1_L@P}"
	local stripped=$(sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" <<<"$lp" | sed "s,[\x01-\x02],,g")
	local ps1_left_len=${#stripped}
	GIT_PROMPT_RIGHT_LENGTH=$(if [ "${GIT_PROMPT_INLINE:-true}" == true ]; then echo $((columns - ps1_left_len - 2)); else echo 0; fi)
	unset lp
	if [ "$EUID" == 0 ]; then
		printf -v color_user_host "\e[0;31m"
	elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf -v color_user_host "\e[0;33m"
	else
		printf -v color_user_host "\e[0;32m"
	fi
	if [ $last_status -eq 0 ]; then
		printf -v color_line_marker "\e[0;34m"
		printf -v color_exit_code "\e[0;32m"
	else
		printf -v color_line_marker "\e[0;31m"
		printf -v color_exit_code "\e[0;31m"
	fi
}

# Ensure the git line is part of the prompt, not printed by itself
GIT_PROMPT_DISABLE_PRINT=true

PS1_TITLE='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}'
PS1_CLEARLINE='\[\e[0;1;36m\]⏎\[\e[0m\]$(printf "%$((columns - 1))s\r\[\e[K\]")'
PS1_LINE1_PRE='\[${color_line_marker}\]┌ $([ -n "$git_prompt_line" ] && echo -e "${git_prompt_line}\n\[${color_line_marker}\]│ ")'
PS1_LINE1_L='\[${color_exit_code}\]${last_status} \[\e[0;36m\]${timer_show} $([ \j -gt 0 ] && echo -e "\[\e[0;33m\]\j ")\[\e[0;34m\]\t \[\e[0;33m\]\w'
PS1_LINE1_R='${git_prompt_right}'
PS1_LINE2='\[${color_line_marker}\]└ \[${color_user_host}\]\u\[\e[0;34m\]@\[${color_user_host}\]\h \[\e[1;33m\]\$\[\e[0m\] '

PS1="$PS1_TITLE$PS1_CLEARLINE$PS1_LINE1_PRE$PS1_LINE1_L$PS1_LINE1_R\n$PS1_LINE2"
