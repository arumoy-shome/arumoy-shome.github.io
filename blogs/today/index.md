---
title: Timestamps in the Shell (today)
date: 2022-03-03
abstract: |
    Creating timestamps in the terminal.
categories: [shell, productivity]
---

I often work with text files containing pros (such as blog posts and
git commit messages) and require adding a timestamp containing the
current date, day & time.

I wrote `today`, a shellscript which returns the current date in
various formats. Here is the script as of 2022-03-09, the latest
version can be found in my
[dotfiles](https://github.com/arumoy-shome/dotfiles).

```{.bash filename="today"}
#!/usr/bin/env bash

# today: return today's date in various formats

# Usage: today [OPTS]
# Without any options, today will print today's date in %Y-%m-%d
# format. Following are the supported options:
#    --with-day: %Y-%m-%d %a
#    --with-time: %Y-%m-%d %H:%M
#    -l | --long: %Y-%m-%d %a %H:%M
#    -h | --human: %a %b %d, %Y
#    -s | --stamp: enclose the date in square braces

# NOTE: when using both --with-day & --with-time, the order in which
# the options are passed matters. For example:
#
# today --with-day --with-time will produce
#    2022-03-03 Thu 02:20
#
# But today --with-time --with-day will produce
# 2022-03-03 02:21 Thu

# NOTE: when using --human option, all other options are ignored.

main() {
  local FMT='%Y-%m-%d'
  local STAMP_FLAG=1 # false

  while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case "$1" in
      --with-day)
        FMT="$FMT %a"
        ;;
      --with-time)
        FMT="$FMT %H:%M"
        ;;
      -s | --stamp)
        STAMP_FLAG=0 # true
        ;;
      -l | --long) # short for --with-day --with-time
        FMT="$FMT %a %H:%M"
        ;;
      -h | --human) # alternate format, ignore other flags
        FMT="%a %b %d, %Y"
        ;;
      *)
        echo "Error: unknown option $1."
        return 1
    esac; shift # only shift here since we only pass flags
  done

  local OUT=$(date +"$FMT")

  [[ "$STAMP_FLAG" -eq 0 ]] && OUT="[$OUT]"

  echo "$OUT"
}

main "$@"
```

Without any arguments, `today` prints the date in '%Y-%m-%d'
format. Using the following optional flags the output can be
manipulated.

flag        output
----        ------
--with-day  '%Y-%m-%d %a'
--with-time '%Y-%m-%d %H:%M'
--long      '%Y-%m-%d %a %H:%M'
--human     '%a %b %d, %Y'

The `--stamp` flag can be used to optionally wrap the output in square
braces.

I frequently use this to add a timestamp to my git commit messages.

```bash
git commit -m "feat: timestamps from the shell $(today -l -s)"
```

Or insert a timestamp into the current buffer I am editing in vim.

```vim
:r! today -l -s
```
