Git/Bash helpers
==============================================================================

#### Installation

To install, run the `install-hooks.sh` script.

This installs a function to the Bash prompt that displays Git info whenever
the current directory is under a git repository.

To additionally install some helpful Git aliases, run the `install-git-aliases.sh`
script.

#### General info

This was developed using git version 1.8.1.2 and should work with this version
of git and newer. It may or may not work with some older versions. It has been
tested with multiple versions of Git up to 2.27.0.

The info line is able to show the following information
- upstream origin
- branch or tag, including if the branch is local or tracking a remote and
  wether a tag is annotated or not
- if branch is tracking a remote with a different name than itself the
  tracked remote branch (upstream branch)
- special states like merging, rebasing, cherry picking and bisecting
- current hash (in inverse colors if there are changes)
- number of files that are changed from last commit if any
- number of stashes if any

A examples of a line:

```
| myorigin ⑂mybranch (hash) ≠7 ↑1 ↓2 ᐅ3 |
```
A examples of a line (utf8 markers disabled):
```
| myorigin mybranch (hash) M:7 [ahead 1, behind 2] stashes:3 |
```

#### Demonstration (pure git)

![demonstration of line mode](images/git_prompt_line_mode.png)

Changing to ASCII mode (ie. no fancy UTF-8 characters)

![demonstration of line mode (ascii)](images/git_prompt_line_mode_ascii.png)

## Smart prompt

Also included here is a setup of the bash prompt where the git line is integrated
rather than a separate line. I call this my smart prompt since it integrates a lot
of handy features besides git.

Smart prompt is a two line prompt because I hate having the current directory push
the start of the command line towards the right edge of the terminal, I like to start
typing my commands near the start of the line.

This prompt shows the directory, git and other information on one line and has the
username@hostname and actual prompt on a separate line. Git information is shown last
with the origin right aligned in the terminal window.

The smart prompt shows the following information:

Line 1:
- exit code of the last command (in green for zero, in red for non-zero)
- how long the last command took to execute
- number of background jobs (hidden if none)
- the current time (24h)
- directory
- git information if in a git repository

Line 2:
- username
- hostname
- prompt ($ for non-root, and # for root)

![demonstration of smart mode (git)](images/smart_prompt_git.png)

Non-git features demonstrated:

![demonstration of smart mode (non-git)](images/smart_prompt.png)

#### Dropping git information intelligently

I usually use the excellent [Guake Terminal](http://guake-project.org/) so my terminal
is pretty wide and thus has plenty of room for information, however sometimes even I
have to go into a deep deep directory structure.

So in smart mode the git functionality will automatically try to fit on the line
by shortening the origin and dropping the least useful information a little at a time
from the prompt if there is not enough space. In case there is not enough space on
the line for even the most basic git information it will even revert back to the
default mode of printing git info on a separate line.

Demonstrated here (with origin already shortened due to lack of space):

![demonstration of smart dropping git info](images/smart_prompt_drop_git.png)
