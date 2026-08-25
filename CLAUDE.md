# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The source for <https://arumoy.me>, a personal site built by a hand-rolled static site
generator: **pandoc + GNU make + POSIX shell**. There is no framework, no npm, no
Python dependency in the build, and no client-side JavaScript in the output.

The site was migrated off Quarto. Quarto-specific syntax (`::: {.callout-*}`,
`@fig-` cross references, `filename=` code-fence attributes, executable
```` ```{python} ```` cells) has been deliberately removed from the content and
**must not be reintroduced** — nothing in the build understands it, and it will
render as literal text.

## Commands

```sh
make                # build everything into _site/
make -j8            # same, recipes in parallel (safe; output is identical)
make clean          # rm -rf _site build
make serve          # build, then serve _site on http://localhost:8000
make test           # build, then run tests/
JOBS=1 bin/index    # force bin/index sequential (debugging)
bin/new "Post Title"          # scaffold blogs/<slug>/index.md
bin/new -f -x -c "shell, vim" -d 2026-01-30 "Title"   # no prompt, no $EDITOR
```

A full build is ~5s (~3s with `make -j8`). Editing any single post re-runs
`bin/index` and therefore rebuilds all post pages; this is intentional coarseness,
not a bug. A no-op `make` is silent, but not free: category pages sit behind the
`.PHONY` tags target and are re-rendered on every build (~1s), which is also why
`make -q` never reports a clean tree.

## Tests

`tests/` is plain bash — no framework, no dependency beyond pandoc and `xmllint`.
`tests/run` builds the site, then runs each `tests/[0-9]*.sh` as its own process.

```sh
make test                  # everything, ~80s
TEST_FAST=1 make test      # skip 40-42, which do full rebuilds (~15s)
tests/run 5                # only tests/5*.sh
tests/run links yamlseq    # match by name
tests/run --update-golden  # after adding a post, refresh the URL manifest
```

| File | Covers |
| --- | --- |
| `10-slugify` | `slugify()`, every category in use, agreement with `bin/new`'s Python copy |
| `11-rfc822` | both branches of the BSD/GNU `date` split, driven explicitly |
| `20-yamlseq` | ordering, ties, undated records, indentation, inline markdown |
| `30-index-fixture` | the pandoc traps below, against `tests/fixtures/site` |
| `31-feed` | CDATA guard, relative-URL rewriting, feed and sitemap shape |
| `32-tags` | category page membership, ordering, the tag index and its counts |
| `40-jobs-identity` | `JOBS=1` vs `JOBS=N` byte-identity, fixture and real corpus |
| `41-make-determinism` | `-j1` vs `-j8`, repeatability, the no-op build |
| `42-make-deps` | what each input rebuilds |
| `50-urls` | the URL contract, against `tests/golden/site-manifest.txt` |
| `51-links` | every internal link, fragment and asset resolves |
| `52-leaked-syntax` | Quarto leftovers, unexpanded template vars, escaped markdown |
| `53-page-head` | `<title>`/description integrity, stylesheet order, TOC correctness |
| `60-listings` | the two-stage talks pipeline |
| `61-publications` | the `nocite:` list, the `#refs` div, and that no post's citation leaks onto the page |
| `70-new` | `bin/new` output, and that the build can read it back |

Two rules keep the suite stable across pandoc versions (local is ahead of the
3.7.0.2 pinned in CI): **no golden HTML** — the only byte-exact artefact is the
`_site` file manifest, everything else asserts properties — and byte comparison
only ever between two runs of the *same* pandoc.

Assertion helpers never return non-zero, so a file reports all its failures rather
than aborting at the first. `INDEX_LIB=1 . bin/index` sources the helpers without
running the driver.

Tests that document a trap are only worth having if they fail when it returns.
Each one has been checked by reintroducing the bug and confirming that test — and
no other — goes red.

## Architecture

### The two-stage pandoc pipeline

Listing pages (`blogs.html`, `talks.html`, tag pages) are built in **two** pandoc
passes, and the intermediate is **markdown**, not HTML:

1. data (post frontmatter, or `talks.yaml`) → pandoc with a *markdown-emitting*
   template → a markdown fragment in `build/`
2. `build/<name>.md` → pandoc with `templates/page.html` → `_site/<name>.html`

The markdown intermediate is what makes inline markdown inside data files work —
`**bold**` and links inside `talks.yaml` abstracts, and links inside post
abstracts, all get a real markdown parse instead of being emitted as literal
text. Do not "simplify" this into a single HTML-emitting pass.

### The publications page

`publications.html` is **not** a listing page. It is an ordinary hand-written
page, `pages/publications.md`, whose body is a `nocite:` list of bibkeys and an
empty `::: {#refs .publications}` div that citeproc fills from
`bibliography.bib`.

That bib is dual-purpose: it holds both the works cited by blog posts and
Arumoy's own papers. The `nocite:` list is the only thing separating them — a
`@*` would drop Zhang, Heer, Quaranta and Pimentel onto the publications page.
`tests/61-publications.sh` is what catches that.

Entry order is the citation style's, i.e. alphabetical by first author, not
newest-first. Adding a publication means adding a BibTeX entry and its key to
the `nocite:` list; nothing else.

### Pieces

| Path | Role |
| --- | --- |
| `Makefile` | Pattern rules with real dependencies. `COMMON` / `POST_FLAGS` hold the shared pandoc flags. |
| `bin/index` | The only real logic. One pass over `blogs/*/index.md` producing `build/{blogs.md,blogs.xml,sitemap.xml,tags/*.md,frag/,item/,meta/}`. |
| `bin/yamlseq` | `talks.yaml` is a bare YAML **sequence**; pandoc's `--metadata-file` needs a **mapping** at the root. Wraps it under a key and date-sorts newest-first. |
| `templates/page.html` | The single HTML template for every page. |
| `templates/*.md`, `*.xml`, `meta.txt` | Fragment templates consumed by `bin/index` and the Makefile. |
| `site.yaml` | Site-wide metadata: nav, footer, `og:` values, `title-suffix`. Passed to every pandoc call. |
| `bibliography.bib` | Every reference on the site: works cited by posts, and Arumoy's own publications. |
| `association-for-computing-machinery.csl` | Vendored citation style, applied site-wide. Chosen over `acm-sig-proceedings.csl`, which truncates to "et al." past two authors and so drops co-authors from the publications page. |
| `pages/` | Hand-written page bodies. `*-intro.md` are the prose headers of the generated listing pages. |
| `blogs/<slug>/index.md` | One directory per post, images alongside. |
| `build/`, `_site/` | Generated; both gitignored. |

`bin/index` writes `build/meta/<slug>.yaml` per post (slug, RFC-822 pubdate,
plain-text `description`, pre-slugified `catlinks`). The Makefile's post rule feeds
that file back into pandoc, which is how post pages get their `<meta name="description">`
and their category links. That is why every post page depends on `build/blogs.md`.

### Parallelism in `bin/index`

Each post costs three pandoc invocations, so `bin/index` re-invokes **itself** as
`bin/index --post <path>` under `xargs -0 -n1 -P "$JOBS"`. The script therefore has
two modes: a worker (`render_post`) and a driver.

The invariant that makes this safe: **a worker writes only files named after its own
slug.** Ordering and category data go to `build/order/<slug>` and `build/cats/<slug>`
rather than being appended to one shared file — concurrent appends would interleave
and corrupt both. The driver concatenates and sorts them after `xargs` returns, so
output is deterministic regardless of completion order.

If you add per-post work, keep it inside `render_post` and keep it writing only
slug-named files. `JOBS=1` runs the same code path sequentially and must produce
byte-identical output; that is the first thing to check if the two ever diverge.

`-n1` is load-bearing: without it BSD xargs packs every path into one command and
`-P` does nothing.

### URL contract — do not break

Inherited from the Quarto site and verified against it during the migration:

- top-level pages are **flat**: `/blogs.html`, `/talks.html`, `/publications.html`,
  `/resume.html`, `/license.html`
- posts are **directory-style**: `/blogs/<slug>/`, with images as siblings
- `/blogs.xml`, `/sitemap.xml`, `/robots.txt`, `/CNAME` keep their paths
- `/blogs/tags/<category>.html` is the only URL family added post-migration,
  indexed by `/blogs/tags/` (directory-style, like a post)

`_site/blogs/` (post directories) and `_site/blogs.html` (the index) coexist
deliberately.

## Pandoc behaviours this build depends on

These were each found by debugging real breakage. Changing them silently breaks output.

- **`--wrap=none` is mandatory on every markdown-emitting template pass.** Without it
  the markdown writer reflows long lines, which splits `## [Title](url)` across two
  lines and destroys both the heading and the link. It is also on the HTML pass, where
  folding otherwise injects newlines inside `<title>` and `<meta content="…">`.
- **`--metadata key=value` escapes markdown; `--metadata-file` parses it.** Passing
  `[shell](/blogs/tags/shell.html)` via `--metadata` yields `\[shell\](...)`. This is
  why `bin/index` writes category links into a per-post YAML file instead.
- **Document frontmatter beats `--metadata-file`.** That is how `pages/index.md` and
  `pages/resume.md` override `title-suffix` from `site.yaml`.
- **A `$if(...)$` opening at the *end* of a template line swallows the following
  newline.** A conditional in a markdown-emitting template must therefore start its
  own line; at end-of-line it silently removes the blank line between entries, and
  the next `###` stops being parsed as a heading.
- **An explicit `::: {#refs}` div suppresses the `reference-section-title` heading.**
  Citeproc only inserts the "References" header when it appends the bibliography
  itself; where the document places the div, no heading is emitted. That is what lets
  `publications.html` be a bare list, and why `COMMON` can keep
  `--metadata reference-section-title` for posts without special-casing that page.
- **`--metadata` beats document frontmatter, unlike `--metadata-file`.** So
  `reference-section-title` cannot be overridden from a page's own YAML; the `#refs`
  div above is the lever that works.
- **`$highlighting-css$` must appear before `<link rel="stylesheet" href="/styles.css">`**
  in `templates/page.html`. Pandoc's inlined palette is light-theme only, and
  `styles.css` overrides its token colours for dark mode; equal specificity means
  source order decides.
- **Posts have no `description:` field.** `templates/listing.md` reads `abstract`
  directly (Quarto's listing used to fall back this way). Renaming that breaks every
  index entry and every `<meta name="description">`.
- **The RSS CDATA terminator must be protected before escaping `]]>`.** `bin/index`
  swaps `]]></description>` for a sentinel, escapes remaining `]]>`, then restores it.
  Escaping unconditionally makes the whole feed unparseable.

`bin/index` must stay portable between BSD (macOS, local) and GNU (Ubuntu, CI)
userland. The RFC-822 date helper branches on `date -j`, which succeeds on BSD and
fails on GNU.

## Content conventions

Post frontmatter: `title`, `date` (unquoted ISO), `abstract` (block scalar, may
contain markdown), `categories` (flow or block sequence).

Because there are no Lua filters, prose uses plain markdown:

- asides are **blockquotes** with a bold lead (`> **Tip — doi2bib**`), not callouts
- a code block's filename is a **bold line above it** (`` **`bin/publish`** ``), not a
  fence attribute
- figures are plain `![Caption](img.png)`; pandoc's `implicit_figures` produces
  `<figure>`/`<figcaption>`. There is no figure numbering — refer to figures in prose
  ("the figure above")
- `::: {.wide}` is a full-bleed figure, `::: {.grid2}` a two-column pair; both are
  styled in `styles.css`
- citations (`@key`, `[@key]`) resolve against `bibliography.bib` via `--citeproc`,
  which is enabled for every page, styled site-wide by
  `association-for-computing-machinery.csl`. The style is numeric, so an in-text
  citation renders as `[1]`, and a post's reference list is numbered to match
- the style prints a thesis's `type` field but ignores `note` and `howpublished`.
  That is why the unpublished entries in `bibliography.bib` carry their
  description in `type` (`MSc. systematic literature review`) or, for the paper
  under review, in `institution` — those are the fields that actually reach the
  page
- `# <1>` code-annotation markers render literally as comments, with the explanatory
  numbered list following the block. This is accepted, not broken.

## Deploy

`.github/workflows/publish.yml` runs on push to `master`: installs a pinned pandoc
`.deb` (the apt package lags behind the 3.x features this build uses), runs `make`,
and publishes `_site` to `gh-pages` via `peaceiris/actions-gh-pages` with
`cname: arumoy.me`. `CNAME` is also copied into `_site` by the Makefile.
