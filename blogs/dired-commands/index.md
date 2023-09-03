---
title: Dired Commands
date: 2021-04-23
abstract: Dired commands I frequently use.
categories: [emacs]
---

|||
|---|---|
|`% m`|mark the files matching the provided regex (also useful `% d` which marks the files for deletion)|
|`% g`|mark the files whose contents match the provided regex (essentially dired interface to grep)|
|`t`|toggle the mark (I usually follow this with `k` to kill the lines, and `g` to restore)|
|`!` or `&`|run shell command in current dir, if marked files are present pass them to the command as arguments|
