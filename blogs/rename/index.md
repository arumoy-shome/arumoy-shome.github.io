---
title: Renaming files so they make sense (rename)
date: 2024-11-28
abstract: |
    `rename` is a bash script I wrote to automatically rename long files
    (the way I like it).
categories: [shell, python]
---

Often I need to work with files that have really long and obscure
names. `rename` is a Python script I wrote that renames a given file
using a sane format. By default, it makes the following changes:

1. Remove all whitespace and punctuation marks
2. Remove English stopwords
3. Lowercase all characters and
4. Hyphenate everything

Here is the full script as of 2024-11-29, you can find the latest
version of the script [in my dotfiles
repository](https://github.com/arumoy-shome/dotfiles/blob/master/bin/rename).

```{.python filename="rename"}
#!/usr/bin/env python3

import argparse
import os
import re


with open(
    os.path.join(os.getenv("HOME"), ".local/share/rename", "stopwords-en.txt")
) as f:
    STOPWORDS = f.readlines()
    STOPWORDS = [word.strip("\n") for word in STOPWORDS]


def rename(src: str) -> str:
    dst = src
    dst = dst.lower()
    dst = re.sub(r"\s+", "-", dst)  # replace 1 or more whitespace with hyphen
    dst = re.sub(
        r"[^a-zA-Z0-9]+", "-", dst
    )  # replace 1 or more punctuations with hyphen
    dst = re.sub("([A-Z][a-z]+)", r"-\1", re.sub("([A-Z]+)", r"-\1", dst))
    dst = dst.split("-")
    dst = [word for word in dst if word]  # remove empty words
    dst = [word for word in dst if word not in STOPWORDS]
    return "-".join(dst)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rename files the way I like it.")
    parser.add_argument("source", type=str, help="File or directory to rename")
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        default=False,
        help="Don't ask for confirmation",
    )

    args = parser.parse_args()

    head, tail = os.path.split(args.source)
    src, ext = os.path.splitext(tail)

    dst = rename(src)
    dst = os.path.join(head, dst)
    dst = f"{dst}{ext}"

    if not dst:
        print("rename: no more words left!")
        exit(1)

    if not args.force:
        response = input(f"rename: {args.source} --> {dst}? [y, n]: ")
        match response:
            case "n":
                print("rename: aborted by user.")
                exit(0)
            case _:
                print("rename: incorrect response, please type one of [y, n]")
                exit(1)

    print(f"rename: {args.source} --> {dst}")
    os.rename(src=args.source, dst=dst)
```

The stopwords are read from a text file so adding new stopwords (or
words you never want to see in your filenames) easy. I store this file
in my dotfiles repo to ensure that the `rename` script works on any
machine where I clone my system configuration files.

By default, the script will ask for confirmation before renaming
a file. The `--force` flag can be passed to bypass this. This makes it
convenient to rename files in bulk using standard unix tools such as
`find` and `xargs`. For instance, below how I show how you can rename
all Docx files in a directory automatically.

```{.bash}
find * -name '*.docx' -print0 |
xargs -0 -n1 rename --force
```
