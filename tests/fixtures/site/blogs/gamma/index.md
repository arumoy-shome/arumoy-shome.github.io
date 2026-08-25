---
title: Gamma Post With Awkward Content
date: 2023-01-20
abstract: |
    Exercises the feed's URL rewriting and its CDATA guard.
categories: [shell]
---

A relative image, which a feed reader cannot resolve and which bin/index must
rewrite to an absolute URL:

![A caption](pic.png)

Links that must be left exactly as they are:

- [absolute](https://example.org/somewhere)
- [root relative](/blogs.html)
- [anchor](#a-heading)

<!-- A literal ]]> inside an HTML comment: pandoc passes this through raw, so
     it reaches the RSS body unescaped and would terminate the CDATA section
     early if bin/index did not guard it. -->

```{=html}
<p>Raw HTML block, also passed through verbatim: ]]> </p>
```

## A heading

Text after the heading.
