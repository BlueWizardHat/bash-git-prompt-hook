################################################################################
# bash-git-prompt-hook.sh by BlueWizardHat, 2014-11-15
# https://github.com/BlueWizardHat/bash-git-prompt-hook
#
# This script installs a function in the prompt of the bash shell that will
# display a Git info line whenever the current directory is under a git
# repository.
#
# This was developed using git version 1.8.1.2 and should work with this
# version of git and newer. It may or may not work with some older versions.
#
# The info line is able to show the following information
# - upstream origin
# - branch or tag, including if the branch is local or tracking a remote and
#   wether a tag is annotated or not
# - if branch is tracking a remote with a different name than itself the
#   tracked remote branch (upstream branch)
# - special states like merging, rebasing, cherry picking and bisecting
# - current hash (in inverse colors if there are changes)
# - number of files that are changed from last commit if any
# - number of stashes if any
#
# An example of a line
# | myorigin mybranch (hash) M:7 [ahead 1, behind 2] stashes:3 |
#
# To install simply insert the following in your ~/.bashrc after setting your
# prompt (assuming you use the same location for this script that I am):
#
# BASH_GIT_HOOK=~/bin/bash-hooks/bash-git-prompt-hook.sh 
# if [ -f $BASH_GIT_HOOK ]; then
#     . $BASH_GIT_HOOK
# fi
#
################################################################################

function git_bash_prompt() {
	# Exit if not inside a git working tree
	if ! $(git rev-parse --is-inside-work-tree > /dev/null 2>&1); then
		return
	fi

	# Define colors
	local color_reset="\e[0m"
	local color_marker="\e[1;34m"
	local color_origin="\e[0;34m"
	local color_branch="\e[36;1m"
	local color_branch_local="\e[35;1m"
	local color_branch_local_msg="\e[0;35m"
	local color_branch_master="\e[32;1m"
	local color_branch_develop="\e[31;1m"
	local color_branch_release="\e[33;1m"
	local color_no_branch="\e[45;32;1m"
	local color_state="\e[44;32;1m"
	local color_tag="\e[36;1m"
	local color_tag_msg="\e[0;36m"
	local color_hash="\e[34;1m"
	local color_hash_dirty="\e[41;37;1m"
	local color_hash_paren="\e[0;34m"
	local color_change_count="\e[33m"
	local color_stash="\e[0;31m"
	local color_empty_rep="\e[41;37m"
	local color_dirty_marker="\e[31m"

	# Find the origin
	local origin=$(git config --get remote.origin.url 2> /dev/null) || true
	if [ -z "$origin" ]; then
		origin="${color_origin}[no origin]"
	else
		origin="${color_origin}${origin}"
	fi

	# Find tracking branch and change count
	local tracking_branch=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD) 2> /dev/null) || true
	local change=""
	if [ ! -z "${tracking_branch}" ]; then
		set -- $(git rev-list --left-right --count $tracking_branch...HEAD 2> /dev/null)
		local behind=$1
		local ahead=$2
		if [ ! -z "$ahead" ] && [ ! -z "$behind" ]; then
			if [ $ahead -gt 0 ] && [ $behind -gt 0 ]; then
				change=" ${color_change_count}[ahead $ahead, behind $behind]"
			elif [ $ahead -gt 0 ]; then
				change=" ${color_change_count}[ahead $ahead]"
			elif [ $behind -gt 0 ]; then
				change=" ${color_change_count}[behind $behind]"
			fi
		fi
	fi

	# Check if we are on a branch or a tag
	local git_branch=""
	local branch=""
	local tag=""
	if git_branch=$(git symbolic-ref --short -q HEAD 2> /dev/null); then
		if [ -z "${tracking_branch}" ]; then
			color_branch="${color_branch_local}"
			tracking_branch="${color_branch_local_msg} (local)"
		elif [ "${tracking_branch}" == "origin/${git_branch}" ]; then
			tracking_branch=""
		else
			tracking_branch="${color_branch_local_msg} <- ${tracking_branch}"
		fi

		case "${git_branch}" in
			master)
				branch=" ${color_branch_master}${git_branch}${tracking_branch}"
				;;
			develop)
				branch=" ${color_branch_develop}${git_branch}${tracking_branch}"
				;;
			[Rr][Ee][Ll][Ee][Aa][Ss][Ee]-*)
				branch=" ${color_branch_release}${git_branch}${tracking_branch}"
				;;
			*)
				branch=" ${color_branch}${git_branch}${tracking_branch}"
				;;
		esac
	elif tag=$(git describe --exact-match HEAD 2> /dev/null); then
		branch=" ${color_tag_msg}Tag ${color_tag}${tag}"
		change=""
	elif tag=$(git describe --exact-match --tags HEAD 2> /dev/null); then
		branch=" ${color_tag_msg}Tag ${color_tag}${tag} ${color_tag_msg}(non-annotated)"
		change=""
	else
		branch=" ${color_no_branch} NO BRANCH ${color_reset}"
	fi

	# Check if a rebase, merge, cherry-pick or bisect is in progress
	local git_dir=$(git rev-parse --git-dir 2> /dev/null) || true
	local state=""
	if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
		state=" ${color_state} REBASING ${color_reset}"
	elif [ -f "$git_dir/MERGE_HEAD" ]; then
		state=" ${color_state} MERGING ${color_reset}"
	elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
		state=" ${color_state} CHERRY-PICKING ${color_reset}"
	elif [ -f "$git_dir/BISECT_LOG" ]; then
		state=" ${color_state} BISECTING ${color_reset}"
	fi

	# Find the modified count
	local porcelain=$(git status --porcelain 2> /dev/null) || true
	local modified=""
	if [ ! -z "$porcelain" ]; then
		local files=$(echo "$porcelain" | wc -l)
		modified=" ${color_dirty_marker}M:${files}"
	fi

	# Find the hash
	local short_sha=$(git rev-parse --short HEAD 2> /dev/null) || true
	local sha=""
	if [ -z "${short_sha}" ]; then
		sha=" ${color_hash_paren}(${color_empty_rep} EMPTY REPOSITORY ${color_hash_paren})"
	elif [ -z "$porcelain" ]; then
		sha=" ${color_hash_paren}(${color_hash}${short_sha}${color_hash_paren})"
	else
		sha=" ${color_hash_paren}(${color_hash_dirty}${short_sha}${color_hash_paren})"
	fi

	# Find number of stashes
	local stash_count=$(git stash list 2> /dev/null | wc -l) || true
	local stash=""
	if [ ${stash_count} -gt 0 ]; then
		stash=" ${color_stash}stashes:${stash_count}"
	fi

	# Print the line
	printf "${color_marker}| ${origin}${branch}${state}${sha}${modified}${change}${stash}${color_reset} ${color_marker}|${color_reset}\n"
}

PROMPT_COMMAND='git_bash_prompt'
