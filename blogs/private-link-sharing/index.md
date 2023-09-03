---
title: Private Link Sharing
date: 2018-01-01
abstract: |
  Poor man's document sharing with private links, sort of what you get with Google Docs.
categories: [web]
---

Poor man's document sharing with private links, sort of like what you
get with Google Docs. The solution is very simple and I stumbled upon
it when I was trying to device a solution for publishing my
non-scientific work. The following snippet, when put in the html
source, prevents web crawlers from indexing the page. Thus, the page
can be hosted on a web server (I use Github Pages) but won't show up
on a web search engine (such as Google, Bing, Yahoo, etc.).

```{.html filename="index.html"}
<meta name="robots" content="noindex" />
```

The page is thus only accessible to those who possess the page url.
There are several strategies to generate unique urls. I tend to
prepend a timestamp to all my file names. You could also generate a
uuid for your file names using the `uuidgen` command on \*nix like
operating systems.
