---
title: Navigating large markdown files in vim
date: 2023-04-29
author: Arumoy Shome
abstract: |
    Strategies to navigate large plaintext (specifically markdown)
    files in vim.
categories: [shell, vim]
---

Here are three strategies that I use to navigate large markdown files
in vim.

# Folding

Relatively new versions of vim already include the markdown runtime
files package by the infamous [tpope](https://github.com/tpope).
Looking at [the source
code](https://github.com/tpope/vim-markdown/blob/f2b82b7884a3d8bde0c5de7793b27e07030eb2bc/ftplugin/markdown.vim#L82-L87),
we can see that we can enable folding in markdown files by adding the
following configuration to our `vimrc` file.

```{.vim filename=~/.vimrc"}
let g:markdown_folding = 1
```

Now we can use the vim's standard folding keybindings to collapse or
open sections of a large markdown file. See `:help folding` in vim for
more information.

# Movement by text-object

The plugin also includes a pair of handy normal mode keybindings to
navigate between the sections of a markdown document.

+ `[[`: go to previous section
+ `]]`: go to next section

# Navigating using ctags

Use the [universal ctags](https://github.com/universal-ctags/ctags)
program to generate a tags files for your markdown document.

Note that most unix like operating systems already include a `ctags`
executable but this does not support markdown files. There is also
[exuberent ctags](https://ctags.sourceforge.net/) which provides the
same binary however also does not support markdown.

You can generate a tags files for your markdown document by running
the following command in your terminal.

```bash
ctags <name-of-your-file>.md
```

Alternatively, you can generate a tags file for your entire project
recursively using the following  command.

```bash
ctags -R .
```

Now you can use vim's built-in `:tags` command followed by the `<tab>`
key to see a list of all the sections in your current markdown file.
