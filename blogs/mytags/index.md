---
title: Generating tags for git repositories (mytags)
date: 2024-11-17
abstract: |
    `mytags` is a wrapper around `ctags` which respects your gitignore
    files.
categories: [shell]
---

Often while working on remote servers where I don't have permissions to
install language servers, I find
[`ctags`](https://github.com/universal-ctags/ctags) to be an effective
tool to navigate code. `mytags` is a simple Bash script I wrote which
wraps around `ctags` with some added functionality.

Here is the script as of 2024-11-27, [you can find the latest version in
my dotfiles
repo](https://github.com/arumoy-shome/dotfiles/blob/master/bin/mytags).

```{.bash filename="mytags"}
#!/usr/bin/env bash

__is_git_repo() {
  git rev-parse &>/dev/null
}

__git_toplevel() {
  git rev-parse --show-toplevel
}

__ctags() {
  if [[ -x "$(command -v fd)" ]]
  then
    command ctags "$@" $(fd --type f --hidden --exclude '.git') # <5>
  else # <5>
    command ctags "$@" $(git ls-files --exclude-standard) # <5>
  fi
}

if ! __is_git_repo # <1>
then # <1>
  echo "mytags: not inside git repo." # <1>
  exit 1 # <1>
fi # <1>

( # <2>
  cd $(__git_toplevel) && # <3>
  __ctags "$@" # <4>
) # <2>
```
1. `mytags` check that we are inside a git repo, if not exit gracefully.
2. When inside a git repo, start a new subshell and...
3. `cd` to the top-level of the repo (i.e. where the `.git` folder is
   located), this allows us to run `mytags` from any subdirectory
inside the git repo
4. execute ctags with relevant files, either using `fd` if it exists or
   `git ls-files`
5. any additional arguments are passed along to `ctags`

