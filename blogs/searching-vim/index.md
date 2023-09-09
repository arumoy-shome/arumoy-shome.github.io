---
title: Searching in Vim
date: 2019-05-13
abstract: Various strategies for searching text within vim.
categories: [vim]
---

# In buffer search
There are several stratergies for searching in vim. For searching
within the buffer the `/` and `?` normal commands exist which take in
a search pattern. The `ignorecase`, `smartcase` and `infercase`
options affects the matching for the above normal commands. I
additionally install the
[wincent/loupe](https://github.com/wincent/loupe) plugin which
enhances the buffer searchers.

# Project wide search
For searching in a project or across several files there are several
options. First is the `:vimgrep <pattern> <files>` command which
accepts vim regex for the search pattern and glob patterns for the
files to search. The downside is that it is not recursive by default,
although `**/*.filetype` does the trick (but needs to be specified
every time).

The next option is the `:grep` command which invokes the grep command.
Problem is that it does not ignore dotfiles or binaries by default.
The following snippet uses the `wildignore` option to exclude files
when calling grep (assuming `wildignore` is properly configured).
Found on [[https://vi.stackexchange.com/a/8858][stackoverflow]].

```{.vim filename="~/.vimrc"}
let &grepprg='grep -n -R --exclude=' . shellescape(&wildignore) . ' $*'
```

# Customising the grep program
The `grepprg` and `grepformat` options allows us to specify a grep
command and output format of out liking. I like to use ripgrep as an
alternative to grep since it ignores dotfiles and binaries by default.

```{.vim filename="~/.vimrc"}
if executable('rg')
    set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
    set grepformat=%f:%l:%c:%m,%f:%l:%m
endif
```

Tiny downside which bugs me with the above two solutions is that every
search takes away focus from the active splits and shows the search
results in a temporary buffer before populating the quickfix list.

Finally, the [vim-fugitive](https://github.com/tpope/vim-fugitive)
plugin provides a `:Ggrep <pattern> <glob>` command which uses
`git-grep` under the hood. The upside is that only files tracked by
git are searched.

Personally, I like to keep external dependencies to a minimum. Since
vim-fugitive is pretty much a must have, I prefer a combination of
modifying the `grepprg` to ignore files and directories specified by
`wildignore` and `:Ggrep`.

