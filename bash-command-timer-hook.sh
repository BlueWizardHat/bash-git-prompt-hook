################################################################################
# bash-command-timer-hook.sh
#
# This script installs a function in the prompt of the bash shell that will
# time every command entered and report the time the command took in a variable
# that can be included in the PS1 prompt environment variable.
#
# To install simply insert the following in your ~/.bashrc after setting your
# prompt (assuming you use the same location for this script that I am):
#
#     . .bash-command-timer-hook.sh
#
# Then include "$timer_show" in PS1 like so
#
#     PS1='${timer_show} \u@\h \w \$ '
#
# If you use other hooks that use PROMPT_COMMAND make sure to run this script
# last or the timings can be off. For this to work properly the first command in
# $PROMPT_COMMAND should be "timer_stop" and the last command should be
# "unset timer_start".
################################################################################

# MacOS
if [ "$(uname -s)" = "Darwin" ]; then

if $(which "gdate"); then

# If GNU date is installed use that for millisecond precision
function timer_now {
	local nanos=$(gdate +%s%N)
	echo -e $(($nanos / 1000000))
}

else

# Default to seconds (ie. milliseconds is 000)
function timer_now {
	date +%s000
}

fi

# Linux
else

# date command in ubuntu 26.04 no longer supports +%3N (rust rewrite I guess),
# so manually convert from nanos to millis.
function timer_now {
	local nanos=$(date +%s%N)
	echo -e $(($nanos / 1000000))
}

fi

function timer_start {
	timer_start=${timer_start:-$(timer_now)}
}

function timer_stop {
	local delta_ms=$(($(timer_now) - $timer_start))
	local ms=$((delta_ms % 1000 ))
	local s=$(((delta_ms / 1000) % 60))
	local m=$(((delta_ms / 60000) % 60))
	local h=$((delta_ms / 3600000))
	if ((h > 0)); then
		timer_show="$h:$(printf %02d $m)h"
	elif ((m > 0)); then
		timer_show="$m:$(printf %02d $s)m"
	elif ((s > 0)); then
		local tenths=$((ms / 100))
		if ((tenths > 0)); then
			timer_show="${s}.${tenths}s"
		else
			timer_show="${s}s"
		fi
	else
		timer_show="~${ms}ms"
	fi
}

trap 'timer_start' DEBUG

if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="timer_stop; unset timer_start"
else
	PROMPT_COMMAND="timer_stop; $PROMPT_COMMAND; unset timer_start"
fi
