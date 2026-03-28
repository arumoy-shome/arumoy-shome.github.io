---
title: Automatically retrieving Bibtex information from DOI
date: 2023-11-26
abstract: |
    `doi2bib` is a simple Python script I wrote that fetches bibtex
    information from the Crossref API using the provided DOI. It can
    also handle pre-prints published on Arxiv.
categories: [shell, productivity]
---

`doi2bib` is a simple Python script I wrote to automatically retrieve
bibtex information for a given DOI. The script queries Crossref to
obtain the bibtex. The script can also handle pre-prints published on
Arxiv. Here is the content of `doi2bib` along with some explaination
of what the script does.

```{.python filename="doi2bib"}
#!/usr/bin/env python3

import sys
import argparse
from urllib import request, error

def get_bibtex(doi,ispreprint):                                                 # <3>
    if ispreprint:                                                              # <3>
        url = f"https://arxiv.org/bibtex/{doi}"                                 # <3>
    else:                                                                       # <3>
        url = f"https://api.crossref.org/works/{doi}/transform/application/x-bibtex"  # <3>
    req = request.Request(url)                                                  # <3>

    try:
        with request.urlopen(req) as response:
            return response.read().decode()
    except error.HTTPError as e:
        return f"HTTP Error: {e.code}"
    except error.URLError as e:
        return f"URL Error: {e.reason}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
            description="Convert DOI or Arxiv ID to Bibtex"
            )
    parser.add_argument(                    # <1>
            "doi",                          # <1>
            help="DOI or Arxiv ID of paper" # <1>
            )                               # <1>
    parser.add_argument(                            # <2>
            "-p",                                   # <2>
            "--preprint",                           # <2>
            help="Treat provided DOI as Arxiv ID",  # <2>
            action="store_true",                    # <2>
            default=False,                          # <2>
            )                                       # <2>
    args = parser.parse_args()

    bibtex = get_bibtex(args.doi, args.preprint)
    print(bibtex)
```
1. The script must be provided with a DOI. This can also be an Arxiv
   ID.
2. The `-p` or `--preprint` flag can be specified to indicate that the
   provided DOI is an Arxiv ID.
3. The Crossref API is queried with the provided DOI to retrieve the
   bibtex information. With the `--preprint` flag, the Arxiv API is
   used.

I pipe the results through the [bib-tool
CLI](http://www.gerd-neugebauer.de/software/TeX/BibTool/en/), to
format the text and generate a unique key. I specify the following key
format in my `.bibtoolrsc` file.

```{filename=".bibtoolrsc"}
print.use.tab=off
fmt.et.al=""
key.format="%-1n(author)%4d(year)%-T(title)"
```

By default, bibtool uses tabs for indentation. I turn this off.
Bibtool adds ".ea" to the author name to indicate "and others".
I prefer to just have the last name of the first author in the key, so
I set it to an empty string. I set the format of the key to the last
name of the first author, followed by the year of publication and the
first meaningful word from the title.

Here is the script in action, I use one of my own publications as an
example.

```{.bash}
$ doi2bib 10.1145/3522664.3528621 |bibtool -k

@InProceedings{   shome2022data,
  series        = {CAIN ’22},
  title         = {Data smells in public datasets},
  url           = {http://dx.doi.org/10.1145/3522664.3528621},
  doi           = {10.1145/3522664.3528621},
  booktitle     = {Proceedings of the 1st International Conference on AI
                  Engineering: Software Engineering for AI},
  publisher     = {ACM},
  author        = {Shome, Arumoy and Cruz, Luís and van Deursen, Arie},
  year          = {2022},
  month         = may,
  collection    = {CAIN ’22}
}
```

And here is another example using an Arxiv ID (again, one of my own).

```{.bash}
$ doi2bib --preprint 2305.04988 |bibtool -k

@Misc{            shome2023towards,
  title         = {Towards Understanding Machine Learning Testing in
                  Practise},
  author        = {Arumoy Shome and Luis Cruz and Arie van Deursen},
  year          = {2023},
  eprint        = {2305.04988},
  archiveprefix = {arXiv},
  primaryclass  = {cs.SE}
}
```
