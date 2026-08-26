---
title: Managing Bibliography with Bibshelf
date: 2026-08-25
abstract: |
    Shelve a paper or a book: fetch its bibtex, file its pdf, name it something you can find again.
---

After years of working with a cruddy shellscript,
I finally managed to pull it out of my dotfiles
and release it as a CLI.

[Bibshelf](https://github.com/arumoy-shome/bibshelf)
builds upon the basic functionality that I had sketched out in my [doi2bib script](/blogs/doi2bib),
but with a few little upgrades.

The basic functionality is the same.
Give it a DOI and it will give you the corresponding bibtex entry,
But now it can automatically distinguish between a DOI, arXiv ID and an ISBN.
The bibtex data is pulled from <doi.org> for papers, and Open Library for books.

```sh
$ bs 10.1109/CAIN58948.2023.00034     # doi
$ bs 2211.09545                       # arxiv, new style
$ bs hep-th/9711200                   # arxiv, pre-2007
$ bs 978-0-262-03561-3                # isbn, hyphens optional
```

Additionally, if you give it a PDF,
it will file it automatically within your library:
papers go under `files/` and books under `books`.
It can also extract the DOI automatically from the pdf
using `pdftotext` under the hood.
It will try its best to resolve through user input
if multiple DOIs are found in the document.

```sh
$ bs --pdf paper.pdf
bs: paper.pdf says 10.1007/s10664-023-10291-1

@article{morovati2023bugs,
  author = {Morovati, Mohammad Mehdi and Nikanjam, Amin and Khomh, Foutse},
  title = {Bugs in Machine Learning-Based Systems: A Faultload Benchmark},
  ...
}

bs: does this match the pdf? [Y/n]:
```

Files are named using a sane format:
`[ first author] - [year] - [title]`.
Several edge cases are handled here.
For instance,
the entire file name is capped at 255 bytes,
colons and double quotes are removed,
and accents are folded
in the title (`Géron` becomes `Geron`)
but retrained in the bibtex entry.
