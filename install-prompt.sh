#!/usr/bin/env bash

BASHRC_FILE=~/.bashrc
GIT_PROMPT_DIR=$(dirname $(readlink -f $0))


# Install the bash hook
touch $BASHRC_FILE
if [[ ! -z $(grep GIT-BASH-MARKER $BASHRC_FILE) ]]; then
	echo "Older version of the Bash Git Hooks installed, remove older version before installing this one!"
	exit 1
fi

if [[ -z $(grep GIT-PROMPT-MARKER $BASHRC_FILE) ]]; then
	echo "Installing Bash Git Hooks in '$BASHRC_FILE'"
	echo >> $BASHRC_FILE
	echo "# BEGIN  -  GIT-PROMPT-MARKER" >> $BASHRC_FILE
	echo "GIT_PROMPT_DIR=\"$GIT_PROMPT_DIR\"" >> $BASHRC_FILE
	echo 'source "${GIT_PROMPT_DIR}/bash-smart-prompt-init.sh"' >> $BASHRC_FILE
	echo "# END  -  GIT-PROMPT-MARKER" >> $BASHRC_FILE
else
	echo "Bash Git Hooks already installed"
fi

# Edit the config file
editors="$EDITOR nano vim vi"
for e in $editors; do
	if [ ! -z "$e" ] && editor=$(which "${e}"); then
		echo "Editing '${GIT_PROMPT_DIR}/bash-smart-prompt-init.sh' with '$editor' in 5 seconds"
		for i in 5 4 3 2 1; do
			echo -n "$i.. "
			sleep 1
		done
		echo
		$editor "${GIT_PROMPT_DIR}/bash-smart-prompt-init.sh"
		editor_status=$?
		echo "Installation done."
		exit $editor_status
	fi
done

echo "Unable to find suitable editor to edit '${GIT_PROMPT_DIR}/bash-smart-prompt-init.sh'"
echo "with, please edit it manually to configure the features you wish to use."
