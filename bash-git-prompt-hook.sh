################################################################################
# bash-git-prompt-hook.sh by BlueWizardHat, 2014 - 2021
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
# - branch or tag, including if the branch is local (!) or tracking a remote
#   and weather a tag is annotated (✔) or not (✘)
# - if branch is tracking a remote with a different name than itself the
#   tracked remote branch (upstream branch) (←)
# - special states like merging, rebasing, cherry picking and bisecting
# - current hash
# - number of files that are changed from last commit if any (≠)
# - how many commits the branch is ahead (↑) and/or behind (↓)
# - number of stashes if any (ᐅ)
#
# An example of a line
# | myorigin mybranch (hash) ≠7 ↑1 ↓2 ᐅ3 |
#
# The script can also be used to set a variable called git_prompt_right that can be
# used at the end of a line, this is activated by setting GIT_PROMPT_RIGHT_LENGTH
# to the number of characters that the script is allowed to use, it will automaically
# drop least relevant part of the info to make the line fit or revert to printing
# a separate line if there is not enough space. In this mode origin is moved to the far
# right in the console.
#
#
# To install simply insert the following in your ~/.bashrc after setting your
# prompt (assuming you use the same location for this script that I am):
#
# BASH_GIT_HOOK=~/bin/bash-hooks/bash-git-prompt-hook.sh
# if [ -f $BASH_GIT_HOOK ]; then
#     . $BASH_GIT_HOOK
# fi
#
# Configuration options via environment variables:
# GIT_PROMPT_SHOW_ORIGIN = true (show origin, default), false (do not show origin when integrated into the right side)
# GIT_PROMPT_SHOW_SHA = true (show sha, default), false (do not show sha)
# GIT_PROMPT_SHOW_STASHES = true (show stashes, default), false (do not show stashes)
# GIT_PROMPT_SHOW_TRACKING = true (show tracking branch if named different than the origin, default), false (do not show tracking branch)
# GIT_PROMPT_DISABLE_UTF8_MARKERS = false (use utf-8 markers, default), true (revert to ascii and look old)
# GIT_PROMPT_RIGHT_LENGTH = how many columns left in the line, if not set print a normal line, else set $git_prompt_right
# GIT_PROMPT_DISABLE_PRINT = false (print line when GIT_PROMPT_RIGHT_LENGTH is not set or reverting to print, default), true (only set variables)
################################################################################

function git_bash_prompt() {
	# Exit if not inside a git working tree
	if ! $(git rev-parse --is-inside-work-tree > /dev/null 2>&1); then
		git_prompt_line=""
		git_prompt_right=""
		return
	fi

	# Options
	local show_origin=${GIT_PROMPT_SHOW_ORIGIN:-true}
	local show_sha=${GIT_PROMPT_SHOW_SHA:-true}
	local show_stashes=${GIT_PROMPT_SHOW_STASHES:-true}
	local show_tracking=${GIT_PROMPT_SHOW_TRACKING:-true}
	local disable_print=${GIT_PROMPT_DISABLE_PRINT:-false}

	# Define colors
	local color_reset="\e[0m"
	local color_marker="\e[0;34m"
	local color_origin="\e[0;35m"
	local color_branch="\e[36;1m"
	local color_branch_local="\e[0;34m"
	local color_branch_empty_rep="\e[0;31m"
	local color_branch_master="\e[32;1m"
	local color_branch_develop="\e[31;1m"
	local color_branch_release="\e[33;1m"
	local color_branch_tracking="\e[0;34m"
	local color_no_branch="\e[45;33;1m"
	local color_state="\e[44;33;1m"
	local color_tag_anno="\e[33;1m"
	local color_tag_non="\e[0;33m"
	local color_tag_msg="\e[0;36m"
	local color_tag_non_msg="\e[0;35m"
	local color_hash="\e[36m"
	local color_hash_dirty="\e[36m"
	local color_hash_sep="\e[0;34m"
	local color_change_count="\e[0;33m"
	local color_stash="\e[0;34m"
	local color_dirty_marker="\e[0;31m"

	# Define markers
	if [ "$GIT_PROMPT_DISABLE_UTF8_MARKERS" != true ]; then
		local branch_marker=""
		local local_branch_marker=""
		local origin_marker="→"
		local modified_marker="≠"
		local stashes_marker="ᐅ"
		local aheadbehind_pre=""
		local aheadbehind_post=""
		local aheadbehind_sep=" "
		local ahead_marker="↑"
		local behind_marker="↓"
		local tracking_marker=" ← "
		local pre_tag_marker_anno="✔"
		local pre_tag_marker_non="✘"
		local post_tag_marker_non=""
	else
		local branch_marker=""
		local local_branch_marker=""
		local origin_marker=""
		local modified_marker="M:"
		local stashes_marker="stashes:"
		local aheadbehind_pre="["
		local aheadbehind_post="]"
		local aheadbehind_sep=", "
		local ahead_marker="ahead "
		local behind_marker="behind "
		local tracking_marker=" <- "
		local pre_tag_marker_anno=""
		local pre_tag_marker_non=""
		local post_tag_marker_non=":non-annotated"
	fi

	# Find the origin
	local origin_raw=$(git config --get remote.origin.url 2> /dev/null) || true
	origin=$(echo "$origin" | sed -e 's/%[0-9a-f][0-9a-f]/¤/ig') # Replace URL encode entitites with a ¤ mark
	if [ -z "$origin_raw" ]; then
		origin_raw="[no origin]"
		origin="${color_origin}[no origin]"
	else
		origin="${color_origin}${origin_raw}"
	fi

	# Find tracking branch and change count
	local tracking_branch_raw=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD) 2> /dev/null) || true
	local tracking_branch=""
	local change_raw=""
	local change=""
	if [ -n "${tracking_branch_raw}" ]; then
		set -- $(git rev-list --left-right --count @{upstream}...HEAD 2> /dev/null)
		local behind=$1
		local ahead=$2
		if [ -n "$ahead" ] && [ -n "$behind" ]; then
			if [ $ahead -gt 0 ] && [ $behind -gt 0 ]; then
				change_raw="${aheadbehind_pre}${ahead_marker}$ahead${aheadbehind_sep}${behind_marker}$behind${aheadbehind_post}"
			elif [ $ahead -gt 0 ]; then
				change_raw="${aheadbehind_pre}${ahead_marker}$ahead${aheadbehind_post}"
			elif [ $behind -gt 0 ]; then
				change_raw="${aheadbehind_pre}${behind_marker}$behind${aheadbehind_post}"
			fi
			if [ -n "$change_raw" ]; then
				change=" ${color_change_count}${change_raw}"
				change_raw=" $change_raw"
			fi
		fi
	fi

	# Find the hash
	local short_sha=$(git rev-parse --short HEAD 2> /dev/null) || true

	# Check if we are on a branch or a tag
	local git_branch=""
	local branch_raw=""
	local branch=""
	local tag=""
	if git_branch=$(git symbolic-ref --short -q HEAD 2> /dev/null); then
		if [ -z "${tracking_branch_raw}" ]; then
			color_branch="${color_branch_local}"
			branch_marker="${local_branch_marker}"
			tracking_branch=""
		elif [[ "${tracking_branch_raw}" == "origin/${git_branch}" || "$show_tracking" != true ]]; then
			tracking_branch_raw=""
			tracking_branch=""
		else
			tracking_branch_raw="${tracking_marker}${tracking_branch_raw}"
			tracking_branch="${color_branch_tracking}${tracking_branch_raw}"
		fi

		case "${git_branch}" in
			master|main)
				branch_raw="${branch_marker}${git_branch}"
				color_branch="${color_branch_master}"
				;;
			develop)
				branch_raw="${branch_marker}${git_branch}"
				color_branch="${color_branch_develop}"
				;;
			[Rr][Ee][Ll][Ee][Aa][Ss][Ee]-*)
				branch_raw="${branch_marker}${git_branch}"
				color_branch="${color_branch_release}"
				;;
			*)
				branch_raw="${branch_marker}${git_branch}"
				;;
		esac
		branch=" ${color_branch}${branch_raw}"
		branch_raw=" $branch_raw"
	elif tag=$(git describe --exact-match HEAD 2> /dev/null); then
		branch_raw=" ${pre_tag_marker_anno}${tag}"
		branch="${color_tag_msg}${pre_tag_marker_anno}${color_tag_anno}${tag}"
		change_raw=""
		change=""
	elif tag=$(git describe --exact-match --tags HEAD 2> /dev/null); then
		branch_raw=" ${pre_tag_marker_non}${tag}${post_tag_marker_non}"
		branch=" ${color_tag_msg}${pre_tag_marker_non}${color_tag_non}${tag}${color_tag_non_msg}${post_tag_marker_non}"
		change_raw=""
		change=""
	else
		if [ -n "${short_sha}" ]; then
			branch_raw="  $short_sha "
			branch=" ${color_no_branch} $short_sha ${color_reset}"
		else
			branch_raw="  NO BRANCH "
			branch=" ${color_no_branch} NO BRANCH ${color_reset}"
		fi
		show_sha=false
	fi

	# Check if a rebase, merge, cherry-pick or bisect is in progress
	local git_dir=$(git rev-parse --git-dir 2> /dev/null) || true
	local state_raw=""
	local state=""
	if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
		state_raw=" REBASING "
	elif [ -f "$git_dir/MERGE_HEAD" ]; then
		state_raw=" MERGING "
	elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
		state_raw=" CHERRY-PICKING "
	elif [ -f "$git_dir/BISECT_LOG" ]; then
		state_raw=" BISECTING "
	fi
	if [ -n "$state_raw" ]; then
		state=" ${color_state}${state_raw}${color_reset}"
		state_raw=" ${state_raw}"
	fi

	# Find the modified count
	local porcelain=$(git status --porcelain 2> /dev/null) || true
	local modified_raw=""
	local modified=""
	if [ -n "$porcelain" ]; then
		local files=$(echo "$porcelain" | wc -l)
		modified_raw=" ${modified_marker}${files}"
		modified=" ${color_dirty_marker}${modified_marker}${files}"
	fi

	# Find the hash (how to display)
	local sha_raw=""
	local sha=""
	if [ "$show_sha" == true ] && [ -n "${short_sha}" ]; then
		if [ -z "$porcelain" ]; then
			sha_raw="|${short_sha}"
			sha="${color_hash_sep}|${color_hash}${short_sha}"
		else
			sha_raw="|${short_sha}"
			sha="${color_hash_sep}|${color_hash_dirty}${short_sha}"
		fi
	fi
	if [ -z "${short_sha}" ]; then
		branch_raw="${branch_raw}|empty-repository"
		branch="${branch}${color_hash_sep}|${color_branch_empty_rep}empty-repository"
	fi

	# Find number of stashes
	local stash_raw=""
	local stash=""
	if [ "$show_stashes" == true ]; then
		local stash_count=$(git stash list 2> /dev/null | wc -l) || true
		if [ ${stash_count} -gt 0 ]; then
			stash_raw=" ${stashes_marker}${stash_count}"
			stash=" ${color_stash}${stashes_marker}${stash_count}"
		fi
	fi

	# Ensure they are empty
	git_prompt_line=""
	git_prompt_right=""


	#
	# "Separate-line" mode (default)
	#

	# Contruct and print line
	if [ -z "$GIT_PROMPT_RIGHT_LENGTH" ] || [ "$GIT_PROMPT_RIGHT_LENGTH" == 0 ] ; then
		local fullline="${origin}${branch}${state}${sha}${modified}${change}${stash}${tracking_branch}${color_reset}"
		if [ $disable_print == true ]; then
			git_prompt_line="$fullline"
		else
			printf "${color_marker}| ${fullline} ${color_marker}|${color_reset}\n"
		fi
		return
	fi

	#
	# "Right-side" mode
	#

	if [ "$show_origin" == true ]; then
		local pre_origin_raw="  ${origin_marker}  "
		local pre_origin="  ${color_origin}${origin_marker}  "
	else
		local pre_origin_raw=""
		local pre_origin=""
		origin_raw=""
		origin=""
	fi

	# Try if there is room for the full line
	local rline_raw="  ${origin_marker} ${branch_raw}${state_raw}${sha_raw}${modified_raw}${change_raw}${stash_raw}${tracking_branch_raw}"
	local line_len=$((${#rline_raw} + ${#origin_raw} + ${#pre_origin_raw}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${sha}${modified}${change}${stash}${tracking_branch}${pre_origin}${origin}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Try dropping the sha
	local line_len=$((line_len - ${#sha_raw}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${modified}${change}${stash}${tracking_branch}${pre_origin}${origin}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Try shortening the origin
	local origin_short="${origin_raw##*:}"; origin_short="${origin_short##*/}"
	local line_len=$((line_len - ${#origin_raw} + ${#origin_short}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${modified}${change}${stash}${tracking_branch}${pre_origin}${origin_short}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Try dropping the origin completely
	local line_len=$((line_len - ${#origin_short} - ${#pre_origin_raw}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${modified}${change}${stash}${tracking_branch}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Try dropping the stashes
	local line_len=$((line_len - ${#stash_raw}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${modified}${change}${tracking_branch}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Try dropping tracking branch
	local line_len=$((line_len - ${#tracking_branch_raw}))
	if [ $line_len -lt $GIT_PROMPT_RIGHT_LENGTH ]; then
		local rline="  ${color_origin}${origin_marker} ${branch}${state}${modified}${change}"
		printf -v git_prompt_right "$rline"
		return
	fi

	# Dropped as much as it makes sense to drop, so revert to print on a separate line with slightly reduced info
	local fullline="${color_origin}${origin_short}${branch}${state}${sha}${modified}${change}${stash}${color_reset}"
	if [ $disable_print == true ]; then
		git_prompt_line="$fullline"
	else
		printf "${color_marker}| ${fullline} ${color_marker}|${color_reset}\n"
	fi
}

if [ -z "$PROMPT_COMMAND" ]; then
	PROMPT_COMMAND="git_bash_prompt"
else
	PROMPT_COMMAND="git_bash_prompt; $PROMPT_COMMAND"
fi
