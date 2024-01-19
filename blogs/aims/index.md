---
title: Aru's Information Management System (AIMS)
date: 2022-02-28
abstract: |
    AIMS or Aru's Information Management System is a collection of
    shellscripts to manage information in plaintext. It is inspired by
    [org-mode](https://orgmode.org/), and tries to replicate a subset
    of its functionalities which I frequently use. AIMS is completely
    tuned towards my workflow as a researcher and how I manage my
    digital notes.
categories: [shell, productivity]
---

AIMS or Aru's Information Management System is a collection of
shellscripts to manage information in plaintext. It is inspired by
[org-mode](https://orgmode.org/), and tries to replicate a subset of
its functionalities which I frequently use. AIMS is completely tuned
towards my workflow as a researcher and how I manage my digital notes.

Although org-mode is great, the primary motivation for writing AIMs is
because I was feeling a lot of resistance when trying to tune it to my
workflow, primarily because of Elisp. Org-mode also requires that you
use Emacs as your text editor. I did not appreciate the "vendor
lock-in" enforced by org-mode.

You can find the latest version of the script on my [dotfiles
repo](https://github.com/arumoy-shome/dotfiles/blob/master/bin/aims),
below is the script as it stands on 2022-02-28.

```{.bash filename="aims"}
#!/usr/bin/env bash

NOTESDIR="$HOME/org"                                        # <1>
INBOX="$NOTESDIR/inbox.md"                                  # <1>
TEMPLATESDIR="$XDG_DATA_HOME/aims"                          # <1>
[[ ! -e "$INBOX" ]] && touch "$INBOX"                       # <1>

__capture() {
  # Capture incoming info quickly. All items are appended to INBOX
  # which defaults to `inbox.md' in NOTESDIR. Optionally a template
  # can be specified using the --template| -t flag.
  local TEMPLATE="$TEMPLATESDIR/default"                    # <2>

  while [[ "$1" =~ ^-+.* && ! "$1" == "--" ]]; do           # <2>
    case "$1" in                                            # <2>
      --template | -t)                                      # <2>
        shift                                               # <2>
        TEMPLATE="$TEMPLATESDIR/$1"                         # <2>
        ;;                                                  # <2>
      *)                                                    # <2>
        echo "Error: unknown option $1."                    # <2>
        return 1                                            # <2>
        ;;                                                  # <2>
    esac; shift                                             # <2>
  done                                                      # <2>

  local ITEM=$(mktemp)                                      # <3>
  if [[ -e "$TEMPLATE" && -x "$TEMPLATE" ]]; then           # <3>
    eval "$TEMPLATE $ITEM"                                  # <3>
  fi                                                        # <3>

  if eval "$EDITOR -c 'set ft=markdown' $ITEM"; then        # <4>
    [[ "$1" && -e "$NOTESDIR/$1" ]] && INBOX="$NOTESDIR/$1" # <4>
    cat "$ITEM" >> "$INBOX"                                 # <4>
    echo "Info: captured in $INBOX."                        # <4>
  fi                                                        # <4>

  echo "Info: cleaning up $(rm -v "$ITEM")"                 # <5>
}

__capture "$@"
```
1. Store all notes in `$HOME/org/inbox.md`, creating it if necessary.
   Also look for template scripts in `~/.local/share/aims`.
2. Parse the flags passed to AIMS. Currently it only supports the
   `--template`/`-t` flag which accepts the name of the template to
   use. Use the `default` template if none is provided. More on this
   later.
3. Create a temporary file and insert the contents of the template.
4. Edit the temporary file using `$EDITOR` (here I assume its vim or
   neovim), setting the filetype to markdown. If the first positional
   argument passed to AIMS is a valid file inside `$NOTESDIR` then set
   that to the `$INBOX` file. Finally, prepend the contents of the
   temporary file to `$INBOX` file, if vim does not report an error.
5. Cleanup, remove the temporary file.

For the time being, it only provides the capture functionality. A
temporary file is used to compose the text first. Upon successful
completion, the contents of the temporary file are appended to the
default `$INBOX` file if no other files are specified.

What I find really neat is the templating system. An arbitrary name
for a template can be passed to `aims` using the `--template` (or `-t`
for short) flag. `aims` looks for a shellscript with the same name in
the `~/.local/share/aims` directory and executes it if it exists. The
beauty of this design is in its simplicity. Since templates are
shellscripts, it gives us the full expressiveness of the shell. This
is best demonstrated with some examples. Here is my `default` template
as of 2022-02-28 which is used when no template is specified.

```{.bash filename="~/.local/share/aims/default"}
#!/usr/bin/env bash

[[ -z "$1" ]] && return 1 # <1>

echo >> "$1" # <2>
echo "# [$(date +'%Y-%m-%d %a %H:%M')]" >> $1 # <2>
```
1. Sanity check, ensure that a positional argument was passed (that
   is, the temporary file path).
2. Insert an empty line and a level 1 markdown header with a time stamp.

It simply adds a level 1 markdown header followed by a timestamp. Here
is another for capturing bibtex information for research papers.

::: {.callout-tip}
[I also wrote aocp.el](../aocp), an emacs package to capture bibtex
information of research papers using org-mode.
:::
```bash
#!/usr/bin/env bash

[[ -z "$1" ]] && return 1

echo >> "$1"

BIBKEY=$(pbpaste | grep '^@.*' | sed 's/^@.*{\(.*\),/\1/') # <1>
if [[ -n "$BIBKEY" ]]; then # <1>
  echo "# [$(date +'%Y-%m-%d %a %H:%M')] $BIBKEY" >> $1 # <1>
else # <1>
  echo "# [$(date +'%Y-%m-%d %a %H:%M')]" >> $1 # <1>
fi # <1>

echo >> "$1" # <2>
echo '+ **Problem Statement:**' >> "$1" # <2>
echo '+ **Solution**' >> "$1" # <2>
echo '+ **Results**' >> "$1" # <2>
echo '+ **Limitations**' >> "$1" # <2>
echo '+ **Remarks**' >> "$1" # <2>
echo >> "$1" # <2>
echo '```bibtex' >> "$1" # <3>

if [[ -n "$BIBKEY" ]]; then # <3>
  pbpaste | sed '/^$/d' >> "$1" # <3>
  pbcopy <(echo "$BIBKEY") # <3>
fi # <3>

echo '```' >> "$1" # <3>
```
1. Check that the bibtex information is currently in the system
   clipboard by attempting to extract the key using `grep` and `sed`.
   If a key was successfully extracted, then create a level 1 markdown
   header with a time stamp and the key. Otherwise, fall back to just
   a time stamp.
2. Add my prompts for note-taking when reading scientific papers.
3. Remove empty lines and put the bibtex information in a markdown
   source block.

This one is a bit more involved but highlights the power of using
shellscripts for templating. Given that a bibentry is copied in the
clipboard, this template adds a level 1 markdown header with a
timestamp and the bibkey. It adds my [note-taking
prompts](../research-workflow#writing-notes) and sticks the bibentry
at the bottom.
