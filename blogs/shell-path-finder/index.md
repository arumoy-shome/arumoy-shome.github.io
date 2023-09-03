---
title: shell `path_finder`
date: 2020-06-01
abstract: How `$PATH` is constructed on OSX.
categories: [shell]
---

The `/etc/profile` file is executed each time a login shell is
started. If we investigate this file, we see the following:

```{.sh filename="/etc/profile"}
# System-wide .profile for sh(1)

if [ -x /usr/libexec/path_helper ]; then
    eval `/usr/libexec/path_helper -s`
fi

if [ "${BASH-no}" != "no" ]; then
    [ -r /etc/bashrc ] && . /etc/bashrc
fi
```

So each time a login shell is started, `path_helper` is run. In short,
it takes the paths listed in `/etc/paths` & `etc/paths.d/`, appends
the existing `PATH` and clears the duplicates[^stackoverflow].

Tmux[^tmux] always runs as a login shell. Thus a common problem within tmux
is duplicate entries =PATH= (in a different order than what we specify
in our shell config files).

Thus, it's okay to *append* to =PATH= in the shell config files, but
*prepending* causes unwanted side-effects. We could edit =etc/paths=
manually, but this requires sudo and is generally not advised.

[^stackoverflow]: This [Stack overflow
    post](https://stackoverflow.com/a/48228223) explains how
    `path_helper` operates in mode details.
[^tmux]: https://github.com/tmux/tmux/wiki
