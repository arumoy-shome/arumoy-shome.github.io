---
title: CMS using Pandoc and Friends
date: 2023-02-03
author: Arumoy Shome
abstract: |
    Some tools & techniques I use to run a no non-sense blog using static
    html pages. All powered by a sane file naming convension, plaintext
    documents writing in markdown and exported to html using pandoc and
    other unix cli tools.
categories: [shell, web]
---

::: {.callout-important title="Migrated to Quarto"}
Since 2023-07-01, I have been using [Quarto](https://quarto.org) to
manage my website.

The CMS system presented here works well. However, I felt the need for
features such as code annotations and custom document layouts (to name
a few) while still authoring content in plaintext. Quarto
provides all this functionality (and more) without me having to dig
around in pandoc's documentation or write custom javascript.

My original website which I managed using the CMS system presented
here, is open-sourced and [can be viewed on
Github](https://github.com/arumoy-shome/www-arumoy-archive).
:::

[In a prior post](../website-management-pandoc), I shared my humble
system for running a static website using pandoc. Since that post,
I have replaced several manual steps in the process with automated
bash scripts.

# Creating and naming new posts

I use the following human and machine readable naming convention for
all my posts.

```
YYYY-MM-DD--<category>--<title>
```

Within the post, I use yaml metadata to record additional information
related to the post such as its title, date, author and a short
abstract.

```{.yaml filename="my-new-blog.md"}
---
title: foo bar baz
author: John Doe
date: 2023-09-09
abstract: |
    This is the abstract for this post. This abstract shows up on the
    index page automatically! Read on to learn how I do this.
---
```

Although the naming convention is clear, writing it is a bit
cumbersome. Note that I also need to write the same information
twice---once within the file in the yaml metadata, and again when
naming the file. To reduce chances of human error, and make my life a
bit easier, I automate the process of creating a new post using the
following python script.

```{.python filename="bin/new"}
#!/usr/bin/env python3

import os
import subprocess
import sys
import argparse
from datetime import datetime

EXT = ".md"
TIMESTAMP = datetime.now()
TIMESTAMP = TIMESTAMP.__format__("%Y-%m-%d %a %H:%M")
TODAY = datetime.now()
TODAY = TODAY.__format__("%Y-%m-%d")

parser = argparse.ArgumentParser()
parser.add_argument( # <1>
    "title", # <1>
    help="Title of new content", # <1>
) # <1>
parser.add_argument( # <2>
    "-t", # <2>
    "--type", # <2>
    help="Type of content", # <2>
    choices=[ # <2>
        "blog", # <2>
        "talk", # <2>
    ], # <2>
) # <2>
parser.add_argument( # <3>
    "-x", # <3>
    "--noedit", # <3>
    help="Do not open new file in EDITOR", # <3>
    action="store_true", # <3>
) # <3>
parser.add_argument( # <4>
    "-f", # <4>
    "--force", # <4>
    help="Do not ask for confirmation", # <4>
    action="store_true", # <4>
) # <4>
args = parser.parse_args()

if args.type:
    TYPE = args.type
else:
    TYPE = "blog"

TITLE = args.title.strip().lower().replace(" ", "-")
NAME = "--".join([TODAY, TYPE, TITLE])
FILE = f"_{TYPE}s/{NAME}{EXT}"

FRONTMATTER = [
    "---",
    "\n",
    f"title: {TITLE}",
    "\n",
    f"date: {TIMESTAMP}",
    "\n",
    f"filename: {NAME}",
    "\n",
    "author: Arumoy Shome",
    "\n",
    "abstract: |",
    "\n",
    "---",
]

if not args.force:
    confirm = input(f"Create {FILE}? [y]es/[n]o: ")

    if confirm.lower()[0] == "n":
        sys.exit("Terminated by user")

try:
    with open(f"{FILE}", "x") as f:
        f.writelines(FRONTMATTER)
except FileExistsError:
    sys.exit(f"{FILE} already exists")

if not args.noedit:
    subprocess.run([os.getenv("EDITOR"), f"{FILE}"])

sys.exit(f"{FILE} created")
```
1. Accept the title of the new post as the first positional
   argument. This argument is mandatory.
2. Optionally specify a type of post.
3. If this flag is passed, don't open the new file in `$EDITOR`.
4. If this flag is passed, don't ask for confirmation.

::: {.callout-tip title="Python argparse"}
The Python argparse module provides a convenient API to create
commandline tools. This code is much more legible and understandable
compared to how we parse arguments in say bash or zsh.

For instance, compare this to the argument parsing code I wrote in
[AIMS, my information management script](../aims).
:::

The script has a `title` positional argument which is
mandatory. Additionally, the script can also accept a type of the post
using the `--type` or `-t` flag. With the `--force` or `-f` flag, the
script does not ask for any confirmation when creating files. By
default, the script will open the newly created post using the default
editor. However, this can be bypassed by passing the `--noedit` or
`-x` flag. The script automatically creates the yaml frontmatter for
the post and names it in the specified format.

# Automatically generating index pages

I have two index pages on my website---the [blogs](blogs) page which
list all the blogposts I have written and the [talks](talks) page
which lists all the talks I have given in the past. Previously, I was
creating these pages manually. However, with a bit of unix
shell scripting, I have now managed to do this automatically!

I use the following script to generate the blogs and the talks index
pages.

```{.bash filename="bin/create-indices"}
#!/usr/bin/env bash

# generate blogs.md # <1>
TMP=$(mktemp) # <1>
[[ -e blogs.md ]] && rm blogs.md # <1>
find _blogs -name '*.md' | # <1>
  sort --reverse | # <1>
  while read -r file; do # <1>
    pandoc --template=_templates/index.md "$file" --to=markdown >>"$TMP" # <1>
  done # <1>

cat _templates/blogs-intro.md "$TMP" >>blogs.md # <1>
rm "$TMP" # <1>

# generate talks.md # <2>
TMP=$(mktemp) # <2>
[[ -e talks.md ]] && rm talks.md # <2>
find _talks -name '*.md' | # <2>
  sort --reverse | # <2>
  while read -r file; do # <2>
    pandoc --template=_templates/index.md "$file" --to=markdown >>"$TMP" # <2>
  done # <2>

cat _templates/talks-intro.md "$TMP" >>talks.md # <2>
rm "$TMP" # <2>
```
1. Steps to generate `blogs.md` file. First clean slate by removing
   the file if it already exists. Find all markdown files in the
   `_blogs` directory, and run them through pandoc with a custom
   markdown template (explained in more details below). Append the
   entires in `blogs.md` in chronological order. Note as extra
   precaution, we use a temporary file to prevent accidental data
   loss.
2. Same as above, but create `talks.md` now.

First we find all relevant markdown pages that we want to export to
html using `find`. Next, we `sort` the results in chronological order
such that the latest posts show up at the top of the page. The final
part is the most interesting bit. We use pandoc's templating system to
extract the date, title and abstract of each file and generate an
intermediate markdown file in the format that I want each post to show
on the index page. Here is the template file that I use.

```{.pandoc filename="_templates/index.md"}
# ${date} ${title}
$if(abstract)$

${abstract}

$endif$
$if(filename)$
[[html](${filename})]

$endif$
```

All that is left to do is stitch everything together using `cat` to
generate the final file.

# Putting everything together using `make`

Once the index pages are created, I use the following script to export
all markdown files to html.

```{.bash filename=bin/publish}
#!/usr/bin/env bash

find . -name "*.md" -not -path "*_templates*" |
  while read -r file; do
    pandoc --template=public -o docs/"$(basename "${file/%.md/.html}")" "$file"
  done
```

The script finds all markdown files in the relevant directories, and
converts them to html using pandoc. I use a custom template once again
which includes some custom css and fonts of my choice.

Finally, to automate the entire build process I use GNU make. I have a
single `all` target which simply runs the `create-indices` and
`publish` scripts in the right order.

```{.make filename="Makefile"}
all:
	bin/create-indices
	bin/publish
```

# Further optimisations

The `create-indices` script is currently sequential. You can imagine
that this will keep getting slower as the number of posts
increases. This step can be further optimised making the template
extraction step parallel using `xargs` and then sorting the results.

In the `publish` script, we are converting all markdown files to
html. Here, we can make the markdown file selection process smarter by
using `git ls-files`. This will allow us to only select modified and
untracked markdown files.
