---
title: Organising research projects with git
date: 2024-01-19
abstract: |
    Some standards and conventions I follow when organising research
    project data using git.
categories: [research, productivity]
---

In this post I list some of the standards and conventions I have
developed over the course of my PhD to organise research project data.
I use git to version control the relevant files and host them on
Github.

# Project naming convention

I name my research projects uniformly across all applications: file
system, task management, Github, etc. I use the naming convention of
`<my-last-name><project-start-year><keyword>`.

# Project directory structure

My research projects have the following directory structure. Here is
an example from a prior project I worked on:

```
~/phd/shome2022qualitative/
├── bin
├── data
├── docs
├── report
├── src
└── vendor
    ├── biswas2021fair
    └── zhang2021ignorance

```

Typically, research projects have several scripts for the data
collection, data pre-processing, training ML models and running
experiments. Put these scripts in the `bin/` directory. If you have
a more mature code base, you can organise your files in the `src/`
directory. This way your scripts in `bin/` are still able to import
modules or helper functions from `src/`.

Put all datasets for the project in the `data/` directory. I typically
put existing datasets (such as benchmarks introduced in prior papers)
and the data created during the course of the project in separate
folders within the `data/` directory.

If you have a simple static website consisting of html and css pages,
put them in the `docs/` directory. Then you can use [Github
Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
to serve your website.

Put all your latex files, images and additional resources such as
`*.cls` and `*.bst` files in the `report/` directory. You may write
several papers that originate from the same core project idea. Name
the latex files using the `<conference-name><year>.tex` template. This
prevents the need for duplicating all the accompanying files for each
submission. Use version control to track the progress of your papers.
For instance, use [git
tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging) to mark the
major drafts and final submission. This makes it easy to retrieve
prior versions of the paper if required.

If replication packages from prior papers are available on git, use
[git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
and put them in the `vendor/` directory. If they are hosted on other
platforms such as Zenodo or Figshare, check in the source code files
you need as reference. Use folders within `vendor/` to organise
replication packages from multiple papers.

# Recommendations for `.gitignore` patterns

Github has [an excellent
repository](https://github.com/github/gitignore) of `.gitignore`
patterns for various filetypes. Consider importing them into your own
global `.gitignore` file (for instance, Latex and Python). At the
project level, do not check in the pdf version of your papers since
these are typically high churn files and git cannot produce meaningful
diffs for binary files. Instead use the `latexmk` command to generate
the pdf. You can also consider putting the command in a `Makefile` to
reduce keystrokes.

```sh
latexmk -pdf -outdir=report report/<your-paper>.pdf
```

If you use Overleaf, [connect your document to the Github
project](https://www.overleaf.com/learn/how-to/Git_Integration_and_GitHub_Synchronization)
so that everything remains in sync.

# Recommendations for git commit messages

Follow the general best practices for writing good git commit
messages. I use the following template which was recommended by [Tim
Pope](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
You can also paste the following snippet into `~/.config/git/message`.
Then the text is automatically displayed in your text editor, whenever
you write a commit message. See [the git configuration
documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
for more details.

```
# 50-character subject line
#
# 72-character wrapped longer description. This should answer:
#
# * Why was this change necessary?
# * How does it address the problem?
# * Are there any side effects?
#
# Include a link to the ticket, if any.
```

## Additionally for the subject line

For instance, say you want to commit a first draft of your paper. Use
a subject line as follows:

```
feat(report): init icse24 paper draft # <1>
```

Where `feat` is an abbreviation for "feature". The braces specify the
folder within which the changes were made, and the title provides
a quick description of the change.

In contrast, say you refactor the data processing pipeline script. The
subject line could be as follows:

```
refac(bin): remove magic numbers in data-process.sh
```

This makes it very easy to track down prior commits that introduced
changes in the paper versus in the code. For instance, you can target
all refactoring commits within the `report/` directory using the
following `git grep` command:

```sh
git log --grep 'refac.*report.'
```
