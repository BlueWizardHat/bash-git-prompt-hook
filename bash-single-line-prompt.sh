
if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="last_status=\$?; ps1_pre_prompt"
else
	PROMPT_COMMAND="last_status=\$?; ps1_pre_prompt; $PROMPT_COMMAND"
fi

ps1_pre_prompt() {
	if [ "$EUID" == 0 ]; then
		color_user_host="\e[0;31m"
	elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		color_user_host="\e[0;33m"
	else
		color_user_host="\e[0;32m"
	fi
	if [ $last_status -eq 0 ]; then
		color_line_marker="\e[0;32m"
	else
		color_line_marker="\e[0;31m"
	fi
}
ps1_exit_code() {
	if [ $last_status -eq 0 ]; then
		echo -e "\e[0;32m✔"
	else
		echo -e "\e[1;31m✘"
	fi
}


#
# Now set up the prompt
#

# Ensure the git line is part of the prompt, not printed by itself
GIT_PROMPT_DISABLE_PRINT=true

PS1_TITLE='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}'
PS1_CLEARLINE='\[\e[0m\]$(printf "%$((${COLUMNS:-$(tput cols)} - 1))s\r\e[K\]")'
PS1_LINE_PRE='$(if [ -n "$git_prompt_line" ]; then echo -e "${color_line_marker}┌ ${git_prompt_line}\n${color_line_marker}└"; else ps1_exit_code; fi)'
PS1_LINE=' $(echo -e $color_user_host)\u\[\e[0;34m\]@$(echo -e $color_user_host)\h \[\e[0;36m\]\w \[\e[1;33m\]\$\[\e[0m\] '

PS1="$PS1_TITLE$PS1_CLEARLINE$PS1_LINE_PRE$PS1_LINE"
