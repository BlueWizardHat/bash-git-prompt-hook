Git/Bash helpers
================

To install, run the `install.sh` script.

This installs an number of helpful Git aliases, and adds a function to the Bash
prompt that displays Git info whenever the current directory is under a git 
repository.

This was developed using git version 1.8.1.2 and should work with this version
of git and newer. It may or may not work with some older versions. It has been
tested with multiple versions of Git up to 2.17.1.

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

An example of a line:

```
myorigin mybranch (hash) M:7 [ahead 1, behind 2] stashes:3 *
```
