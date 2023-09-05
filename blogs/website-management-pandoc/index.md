---
title: There and Back Again A Tale of Website Management
date: 2022-03-04
abstract: |
    Managing websites using markdown, shell and vim.
categories: [shell, vim, web]
---

After years of using [orgmode](https://orgmode.org) along with the
[org-publish](https://orgmode.org/worg/org-tutorials/org-publish-html-tutorial.html)
package to run my website, I came back to markdown, shell & vim.

In my humble shell dwelling days---before I began my journey into
Emacs land---I was using [Jekyll](https://jekyllrb.com/). Rather,
I was fighting with it. Github requires a `CNAME` file in the
directory from which the website should be served. Now, the
`github-pages` gem can be used to instruct Github Pages (GHP) to
automatically build and serve the website. But I faced several
challenges getting the compatible versions of the `github-pages`,
`jekyll` and `ruby` to match.

I decided to forgo this madness and just use html & css to build my
website. I used org-publish to accomplish this using the following
setup in my `init.el`.

See [the documentation for `org-publish-project-alist`](TODO) on how to
setup org-publish.

```{.lisp filename="~/.emacs.d/init.el"}
(setq org-publish-project-alist
 '(("org" :components ("org-posts" "org-static"))
   ("website-posts"
    :base-directory "~/code/arumoy"
    :base-extension "org"
    :publishing-directory "~/code/arumoy/docs/"
    :section-numbers nil
    :auto-preamble t
    :auto-sitemap t
    :html-head "<link rel=\"stylesheet\" href=\"assets/css/main.css\" type=\"text/css\"/>"
    :publishing-function org-html-publish-to-html)
   ("website-static"
    :base-directory "~/code/arumoy/assets"
    :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf"
    :publishing-directory "~/code/arumoy/docs/assets/"
    :recursive t
    :publishing-function org-publish-attachment)
   ("website-cname"
    :base-directory "~/code/arumoy/"
    :base-extension ""
    :publishing-directory "~/code/arumoy/docs/"
    :include ("CNAME")
    :publishing-function org-publish-attachment)
   ("website" :components ("website-posts" "website-static" "website-cname"))))
```

Since org-publish wipes the `:publishing-directory` clean prior to
each build, I copy the `CNAME` file back in there.

I was very pleased with its simplicity and its text-centric
nature. The fact that it just worked out of the box was a pleasant
surprise. However this intricate setup only worked in Emacs and this
did not sit well with me. So I decided to find a more universal
solution and landed on [Pandoc](https://pandoc.org/).

Pandoc has the `--standalone` flag which produces a document which is
valid on its own (think HTML documents with header and footer). One
can write custom templates to produce documents styled to their
liking. The default template can be viewed using `pandoc -R FORMAT`.
A custom template can be specified using the `--template` flag. See
[section on templates](https://pandoc.org/MANUAL.html#templates) in
the pandoc manual for more info.

Following the advice laid out by
[https://jgthms.com/web-design-in-4-minutes/](Web design in
4 minutes), I designed a minimal pandoc custom template which you can
find my in [dotfiles](https://github.com/arumoy-shome/dotfiles) repo.

My current workflow comprises of authoring content in markdown which
I edit in vim. I use GNU make to automate the html generation using
pandoc. The contents of my Makefile are as follows.

```{.make filename="Makefile"}
# Taken from <https://gist.github.com/kristopherjohnson/7466917>

SRCFILES:= $(wildcard *.md)
PUBFILES=$(SRCFILES:.md=.html)

%.html: %.md
	pandoc --template=public -o docs/$@ $<

# Targets and dependencies

.PHONY: all clean

all : $(PUBFILES)

clean:
	rm $(PUBFILES)
```
