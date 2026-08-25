---
title: Beta Post With "Quotes" in the Title
date: 2024-07-15
abstract: |
    An abstract that spans several lines, plus **bold** text and a
    [link](https://example.org/beta), all of which must be flattened to one
    line of plain text for the meta description. It also contains the code
    span `printf "%s\n"`, whose literal double quote and backslash survive
    pandoc's plain writer — unlike a quote in prose, which smart punctuation
    turns into a curly one — and so must be escaped before they are written
    into a double-quoted YAML scalar.
categories: [productivity]
---

Body text for beta. This post has no `description:` field in its frontmatter,
which is the norm for this site: templates/listing.md reads `abstract`
directly.
