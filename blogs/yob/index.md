---
title: Toggling background color in kitty and vim (yob)
date: 2024-01-19
abstract: |
    `yob` is a tiny shell script which toggles between a light and dark
    colorscheme in Kitty, my terminal of choice.
categories: [shell, vim]
---

`yob` is a shell script that I wrote to toggle between a light and
dark colorscheme in Kitty, my terminal of choice. Some additional
configuration also allow me to sync the vim colorscheme to that of
kitty. This is a much simpler version of [this script by Greg
Hurrell](https://github.com/wincent/wincent/blob/main/aspects/dotfiles/files/.zsh/color).

The name is inspired by the
[vim-unimpaired](https://github.com/tpope/vim-unimpaired) package for
vim. The package adds keybindings prefixed with the `yo*` that toggle
various vim settings. The `b` in `yob` stands for "background".

Here is the script in its entirety as of 2024-01-19. You can also find
the latest version in my [dotfiles
repository](https://github.com/arumoy-shome/dotfiles/blob/master/bin/yob).

```{.bash filename="yob"}
#!/usr/bin/env bash

LIGHT_THEME="colors/gruvbox-light.conf" # <1>
DARK_THEME="colors/gruvbox-dark.conf" # <1>
LOCATION="$HOME/.local/share/yob" # <1>
VIM_BG_FILE="$LOCATION/background" # <1>

__init() { # <1>
  [[ ! -d "$LOCATION" ]] && mkdir -p "$LOCATION" # <1>
  [[ ! -e "$VIM_BG_FILE" ]] && touch "$VIM_BG_FILE" # <1>
} # <1>

__update() { # <2>
  ( # <2>
  cd "$HOME/.config/kitty" # <2>
  if [[ "$1" == "light" ]]; then # <2>
    ln -sf "$LIGHT_THEME" current-theme.conf # <2>
    echo "light" >"$VIM_BG_FILE" # <2>
  else # <2>
    ln -sf "$DARK_THEME" current-theme.conf # <2>
    echo "dark" >"$VIM_BG_FILE" # <2>
  fi # <2>
  ) # <2>

  kitten @ set-colors --all --configured "$HOME/.config/kitty/current-theme.conf" # <2>
} # <2>

__toggle() { # <3>
  local CURRENT_BG # <3>
  CURRENT_BG="$(head -n 1 "$VIM_BG_FILE")" # <3>
  if [[ "$CURRENT_BG" =~ "light" ]]; then # <3>
    __update "dark" # <3>
  else # <3>
    __update "light" # <3>
  fi # <3>
} # <3>

main() {
  if [[ ! "$TERM" =~ "kitty" ]]; then
    echo "yob: not running kitty, doing nothing."
    exit 1
  fi

  if [[ ! -e "$VIM_BG_FILE" ]]; then
    __init
    __update "dark"
    exit 0
  fi

  __toggle
}

main "$@"
```
1. Some initial setup. Here we define the location of the light and
   dark colorscheme files for kitty (I choose to save them in the
   kitty config directory and check it into git so that they are
   available wherever I clone my dotfiles repo). We also store
   additional data for `yob` in `~/.local/share/yob/background` as per
   XDG best practices for unix systems.
2. Here we create a symbolic link between the colorscheme file and
   `current-theme.conf`. The `current-theme.conf` file is picked up by
   kitty next time it starts. Finally, we set the theme for the
   existing kitty sessions using `kitty @ set-colors`.
3. This function toggles between the light and dark themes based on
   information in `~/.local/share/yob/background`.

# Choosing a colorscheme with light and dark variant

After many experiments with various colorschemes in different lighting
conditions, I picked [Gruvbox](https://github.com/morhetz/gruvbox) as
my theme of choice. There are several reasons for this decision:

+ The colorscheme has been around for a little over 10 years and is
  very stable (very few changes since 2018 as per the commits chart on
  github).
+ Both light and dark variants of the theme are legible in various
  lighting conditions.
+ Due to its popularity, the theme is available in Kitty and Vim
  9 out-of-the-box.

# Preserving kitty colors across sessions

To preserve the colorscheme across kitty sessions, `yob` symlinks the
colorsheme files to `current-theme.conf` in kitty's config directory.
The following line ensures that kitty sources the right colorscheme
next time kitty starts.

```{.conf filename="~/.config/kitty/kitty.conf"}
include current-theme.conf
```

# Syncing vim colors with kitty

The `aru#set_background()` function reads the first line of
`~/.local/share/yob/background` using the built-in `readfile` function
in vim (see `:help readfile`) and updates the `background`.

```{.vim filename=".vim/autoload/aru.vim"}
function! aru#set_background() abort
  let config_file = expand('~/.local/share/yob/background')
  if filereadable(config_file)
    let bg = readfile(config_file, '', 1)[0]
  endif

  execute 'set background=' .. bg
endfunction
```

If we run `yob` from another shell, the colors in existing vim
sessions does not update. To account for this I introduce an
autocommand that is fired every time vim is started and when it gets
focus.

```{.vim filename=".vimrc"}
set termguicolors
color retrobox

function! AruAutoBackground() abort
  augroup AruAutoBackground
    autocmd!
    autocmd FocusGained,VimEnter * call aru#set_background()
  augroup END
endfunction
call AruAutoBackground()
```

