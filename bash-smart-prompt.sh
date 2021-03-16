#
# Setup a nice and powerful two-line bash prompt
#

# Put calculation of terminal width so it comes after the timer, but before the git hook
if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="ps1_calc_git_len"
else
	PROMPT_COMMAND="ps1_calc_git_len; $PROMPT_COMMAND"
fi

# Get the timer functionality
source "${GIT_PROMPT_DIR}/bash-command-timer-hook.sh"

# Make sure we save the status of the last command
PROMPT_COMMAND="last_status=\$?; $PROMPT_COMMAND"

#
# Now set up the prompt
#

ps1_exit_code() {
	if [ $last_status -eq 0 ]; then
		echo -e "\e[0;32m$last_status"
	else
		echo -e "\e[0;31m$last_status"
	fi
}
ps1_calc_git_len() {
	local integrated=${GIT_PROMPT_INTEGRATED:-true}
	columns=${COLUMNS:-$(tput cols)}
	printf -v lp "${PS1_LINE1_L@P}"
	local stripped=$(sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" <<<"$lp" | sed "s,[\x01-\x02],,g")
	local ps1_left_len=${#stripped}
	GIT_PROMPT_RIGHT_LENGTH=$(if [ "$integrated" == true ]; then echo $((columns - ps1_left_len - 2)); else echo 0; fi)
}

# Ensure the git line is part of the prompt, not printed by itself
GIT_PROMPT_DISABLE_PRINT=true

PS1_TITLE='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}'
PS1_CLEARLINE='$(printf "%$((columns - 1))s\r\e[K\]")'
PS1_LINE1_PRE='\[\e[0;34m\]┌ $([ ! -z "$git_prompt_line" ] && echo -e "${git_prompt_line}\n\[\e[0;34m\]├ ")'
PS1_LINE1_L='$(ps1_exit_code) \[\e[0;36m\]${timer_show} $([ \j -gt 0 ] && echo -e "\[\e[0;33m\]\j ")\[\e[0;34m\]\t \[\e[0;33m\]\w'
PS1_LINE1_R='$git_prompt_right'
PS1_LINE2='\[\e[0;34m\]└ \[\e[0;32m\]\u\[\e[0;34m\]@\[\e[0;32m\]\h \[\e[01;33m\]\$\[\e[0m\] '

PS1="$PS1_TITLE$PS1_CLEARLINE$PS1_LINE1_PRE$PS1_LINE1_L$PS1_LINE1_R\n$PS1_LINE2"
