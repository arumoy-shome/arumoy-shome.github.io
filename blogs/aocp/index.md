---
title: Aru's Org Capture Template (aocp.el)
author: Arumoy Shome
date: 2021-06-16
abstract: |
    An Emacs package I wrote for managing bibliographic information.
---

After observing my workflow of managing bibliographic information in
Emacs, I extracted the repeated actions into an Emacs package.

To gain some perspective on my workflow, see my prior article on my
[research workflow](../research-workflow).

The package is available on
[github](https://github.com/arumoy-shome/aocp.el) with two alternative
installation methods: 1. By manually downloading the `aocp.el` file
and sticking it in your Emacs `load-path`, or 2. Using
[straight.el](https://github.com/raxod502/straight.el) which is what
I recommend.

The package works under the assumption that you manage your
bibliographic information in [org-mode](https://orgmode.org) (a
major-mode for Emacs). The functions made available through this
package are intended to be used in an
[org-capture](https://orgmode.org/manual/Capture.html) template, they
are not meant to be called interactively (ie. by using
`M-x`).

Assuming that you have a bibtex entry in your `kill-ring` (either by
killing text within Emacs or by coping text from an external
application into your clipboard), this package will do the following:

+ Extract the bibkey
+ Extract the first author
+ Extract the last author
+ Extract the source of publication

```
* TODO %(aocp--get-bibkey nil)
  :PROPERTIES:
  :PDF: file:~/Documents/papers/%(aocp--get-bibkey t).pdf
  :FIRST_AUTHOR: %(aocp--get-first-author)
  :LAST_AUTHOR: %(aocp--get-last-author)
  :SOURCE: %(aocp--get-source)
  :END:
%?
+ problem statement ::
+ solution ::
+ results ::
+ limitations ::
+ remarks ::

  #+begin_src bibtex :tangle yes
  %c
  #+end_src
```

Assuming you have the above template in `paper.txt`, you can configure
org as follows (replace `your-org-inbox-file` appropriately):

```elisp
(setq org-capture-templates
    '(("p" "Paper" entry (file+headline your-org-inbox-file "Inbox")
    "%[~/.emacs.d/org-templates/paper.txt]")))
```

With this in place, you can quickly collect all bibliographic
information within an org file. Leveraging the powerful functionality
provided by
[org-properties](https://orgmode.org/guide/Properties.html), one can
quickly find relevant papers. For instance, I can look up all papers
by author X or all papers by author X published at Y.

A nice little tip is to download a local copy of the pdf and save them
all in a folder. To make this easier, aocp.el also pushes the bibkey
to the kill-ring. So all that is left to do is click the download
button and paste the bibkey as the file name. This ensure 1. That you
have all pdfs names consistently and 2. You have a link to the pdf
from your org file (see the `:PDF:` property in the template above)
which you can open by hitting `C-c C-o` over the link. You do not need
to poke around in the directory containing the pdfs, all the context
is available in the org file and should be the point of entry for all
your bibliographic needs!
