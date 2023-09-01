---
title: Ripgrep commands
abstract: Ripgrep (`rg`) commands I frequently use.
date: 2022-10-01
categories: [shell]
---

|||
|---|---|
|`--no-ignore`|don't ignore patterns in `.gitignore` file|
|`--hidden`|don't ignore hidden (dot) files|
|`--text`/`-a`|don't ignore binary files|
|`--follow`|don't ignore symlinks|
|`--fixed-string`/`-F`|treat pattern as literal string (not regex)|
|`--type`/`-t`|limit search scope to specific filetype|
|`--type-not`/`-T`| inverse of `--type`|
|`--type-list`|print builtin types|
|`--glob`/`-g`|include manually specified glob patterns in search scope, use `!` in glob pattern to inverse|

Ripgrep follows the Rust regex syntax, more details can be found
[here](https://docs.rs/regex/*/regex/#syntax) but the usual stuff
mostly apply as well.

By default, `rg` performs a recursive search in the current directory
while respecting the glob patterns in the `.gitignore` file. It also
ignores hidden (dot) files, binary files and symbolic links. The
`--no-ignore` and `--hidden` flags can be used to change that. Binary
files can be searched using the `--text`/`-a` flag and symlinks can be
followed with `--follow`.

To ignore certain glob patterns in rg (but not in git) a =.ignore=
file can be placed within the directory.

An example of an inverse glob pattern is shown below.
```sh
  rg hello -g '!*.md' # don't search in md files
```

A note on rg's types: These are customisable and a hand full of them
are built in. `rg --type-list` lists them. New types can be added
using the `--type-add` flag. To persist the new type, create a shell
alias or define a rg config file.

As previously mentioned, rg can be configured using a config file. The
name does not matter since rg looks for the file using the
`RIPGREP_CONFIG_PATH` environment variable.
