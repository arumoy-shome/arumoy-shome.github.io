---
title: Managing Scientific Bibliography using Emacs Org-mode
date: 2023-11-29
abstract: How I organise, search and retrieve my scientific papers using Emacs org-mode.
categories: [emacs, productivity]
---

# Front Matter and setup

I store all my bibliographic information in a single `bib.org` file. I
show a hypothetical version of this file below, with two entries. I
store each paper, as a level 1 header. I use the bibtex key as the
title for the header.

```{.org filename="bib.org"}
#+title: Bibliography
#+tags: test viz data self notebook survey
#+tags: [ test : fair ]

* TODO [#A] amershi2015modeltracker :test:viz:

#+begin_src bibtex
@InProceedings{   amershi2015modeltracker,
  series        = {CHI ’15},
  title         = {ModelTracker: Redesigning Performance Analysis Tools for
                  Machine Learning},
  url           = {http://dx.doi.org/10.1145/2702123.2702509},
  doi           = {10.1145/2702123.2702509},
  booktitle     = {Proceedings of the 33rd Annual ACM Conference on Human
                  Factors in Computing Systems},
  publisher     = {ACM},
  author        = {Amershi, Saleema and Chickering, Max and Drucker, Steven
                  M. and Lee, Bongshin and Simard, Patrice and Suh, Jina},
  year          = {2015},
  month         = apr,
  collection    = {CHI ’15}
}
#+end_src

* DONE [#A] chen2022fairness       :test:fair:survey:
:LOGBOOK:
- State "DONE"       from "TODO"       [2022-09-19 Mon 14:14]
:END:

Some notes that I may have regarding this paper.

#+begin_src bibtex
@Misc{            chen2023fairness,
  title         = {Fairness Testing: A Comprehensive Survey and Analysis of
                  Trends},
  author        = {Zhenpeng Chen and Jie M. Zhang and Max Hort and Federica
                  Sarro and Mark Harman},
  year          = {2023},
  eprint        = {2207.10223},
  archiveprefix = {arXiv},
  primaryclass  = {cs.SE}
}
#+end_src
```

# Retrieving bibtex information from Crossref

My search for papers always begins on Google Scholar. For papers that
I find interesting, I retreive the bibtex information using the
`doi2bib` script. The script accepts the DOI as an argument, and
prints the bibtex information obtained from Crossref.

The script also accepts a `--preprint` flag, in which case, it accepts
an Arxiv ID and obtains the bibtex information from Arxiv directly.

:::{.callout-tip title="Scientific Paper Discovery"}
You can find more information on how I discovery scientific papers [in
this blogpost](../scientific-paper-discovery).
:::

:::{.callout-tip title="doi2bib"}
You can find more details regarding the `doi2bib` script [in this
blogpost](../doi2bib).
:::

# Capturing bibtex information using org-capture

Emacs org-mode has a nifty capture feature that allows the user to
quickly capture information. I have the following capture template to
save bibtex information into the bib.org file above.

```{.txt filename="bib.txt"}
* %?

#+begin_src bibtex
#+end_src
```

I have the following org-capture configuration in my init.el file.

```{.elisp filename="init.el"}
(org-capture-templates
`(("p" "Paper" entry (file aru/org-bib-file)
   "%[~/.emacs.d/org-templates/bib.txt]" :prepend t)))
```

In Emacs, I hit the keystrokes `C-c c` followed by the `p` key to
initiate the capture sequence. Org-mode automatically inserts the
capture template shown above. It creates a new level 1 header and
inserts an empty bibtex source block.

To populate the source block, I hit `C-c '` (see `org-special-edit`
for more information on this keybinding). With `C-u M-|`, I run the
`doi2bib` command along with the DOI to add the output of the command
into the source block. `C-c '` closes the special edit buffer and
returns back to bib.org.

:::{.callout-note title="Evil Mode"}
I now use evil-mode which provides vim keybindings within Emacs. I
populate the source block using the `:read!` command.
:::

# Mapping of orgmode features and my usage

In the following table I summarise how I use the built-in orgmode
features for organising the bibliographic information.

| Feature       | Purpose                                                                                                                                               |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| TODO keywords | I mark papers that I want to read with the `TODO` state. Papers that I have already read are marked with the `DONE` state.                            |
| Priority      | Papers that I find interesting, and cite frequently are marked with the `A` priority.                                                                 |
| Tags          | I use tags to broadly classify the papers based on topics relevant for my Phd. You can see the tags I use in the example bib.org file provided above. |

# Searching and Retrieving

I use org-agenda to search and retrieve papers of interest. For
instance, I can filter papers that I need to read by asking org-agenda
for papers that are marked with the `TODO` state (see
`org-todo-list`). I can produce a list of all papers that have the
`testing` and `data` tag (see `org-tags-view`). More complex search
queries can be constructed using the org advanced search commands: for
instance, give me all papers on `testing` that were written by author
X in the year of 2001 (see [org advanced search syntax](https://orgmode.org/worg/org-tutorials/advanced-searching.html)).
