---
title: Navigating in Vim
date: 2019-08-06
abstract: Strategies to navigate files in vim.
categories: [vim]
---

The `gf` visits the file under the cursor if it exists in the `path`
variable. I find this quite useful and use it constantly (for instance
to navigate to imported files in python projects). There are several
variants of this command:

|          |                                            |
|----------|--------------------------------------------|
| `gF`     | same as `gf` but also navigate to the line |
| `C-w f`  | same as `gf` but open in a split window    |
| `C-w F`  | same as `C-w f` with line number           |
| `C-w gf` | same as `gf` but open in new tab           |
| `C-w gF` | same as `C-w gf` with line number          |

Since the line number variants fall back to their non line number
counter parts, I remap them to the non line number variants.

```{.vim filename="~/.vimrc"}
nmap gf gF
nmap <C-w>f <C-w>F
nmap <C-w><C-f> <C-w>F
nmap <C-w>gf <C-w>gF
```

Vim provides the `<cname>` parameter which expands to the filename
under the cursor. To make `gf` automatically create the file if it
doesn't exist, a mapping can be created: `map fg :e <cname>`. However,
I prefer to keep this operation transparent and manual (so that I know
what I am doing). Check `:h gf` for more info. The visual variant of
`gf` uses the visual selection as the filename.

Vim also allows navigation by tags using `C-[`. This however requires
the external `ctags` command and the tag generation is left to the
user.

Finally vim provides the `:find` command which searches for the given
file in `path` and opens the first hit. The `:sfind` does the same but
in a split window. Both commands accept a glob pattern which I
extensively use to find what I need to edit without a fuzzy finder.
