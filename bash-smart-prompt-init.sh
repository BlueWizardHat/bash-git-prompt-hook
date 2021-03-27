#
# bash-smart-prompt-init.sh
#
# Edit this file to configure features for git your prompt. When you are done save
# and exit and the next terminal you start will have the features you selected.
# You can edit this file again at any time to change your configuration.
#

#
# Configure git prompt features (below shows the default)
#
# GIT_PROMPT_SHOW_SHA=true
# GIT_PROMPT_SHOW_STASHES=true
# GIT_PROMPT_SHOW_TRACKING=true
# GIT_PROMPT_DISABLE_UTF8_MARKERS=false

#
# Activate the git prompt (do not comment out this or you lose all git features)
#
source "${GIT_PROMPT_DIR}/bash-git-prompt-hook.sh"

#
# Configure smart prompt features (below shows the default)
#
# GIT_PROMPT_SHOW_ORIGIN=true
# GIT_PROMPT_INLINE=true

#
# Activate the two-line smart prompt (comment out to stick with your own prompt)
#
source "${GIT_PROMPT_DIR}/bash-smart-prompt.sh"

#
# Or use the single line prompt
#
#source "${GIT_PROMPT_DIR}/bash-single-line-prompt.sh"
