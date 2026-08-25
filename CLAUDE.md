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
JOBS=1 bin/index    # force bin/index sequential (debugging)
bin/new "Post Title"          # scaffold blogs/<slug>/index.md
bin/new -f -x -c "shell, vim" -d 2026-01-30 "Title"   # no prompt, no $EDITOR
```

There is no test suite and no linter. Verification means building and inspecting the
output. Useful checks after a change:

```sh
grep -rn ':::\|@fig-\|filename=' _site --include='*.html'   # leaked Quarto syntax
xmllint --noout _site/blogs.xml _site/sitemap.xml           # feed + sitemap well-formed
grep -c '^<h2' _site/blogs.html                             # index entry count
(cd _site && find . -type f | sort)                         # diff against a known-good list
```

A full build is ~5s (~3s with `make -j8`). A no-op `make` is silent and instant.
Editing any single post re-runs `bin/index` and therefore rebuilds all post pages;
this is intentional coarseness, not a bug.

## Architecture

### The two-stage pandoc pipeline

Listing pages (`blogs.html`, `talks.html`, `publications.html`, tag pages) are built
in **two** pandoc passes, and the intermediate is **markdown**, not HTML:

1. data (post frontmatter, or `publications.yaml` / `talks.yaml`) → pandoc with a
   *markdown-emitting* template → a markdown fragment in `build/`
2. `build/<name>.md` → pandoc with `templates/page.html` → `_site/<name>.html`

The markdown intermediate is what makes inline markdown inside data files work —
`46^th^` in `publications.yaml`, `**bold**` and links inside `talks.yaml` abstracts,
and links inside post abstracts all get a real markdown parse instead of being
emitted as literal text. Do not "simplify" this into a single HTML-emitting pass.

### Pieces

| Path | Role |
| --- | --- |
| `Makefile` | Pattern rules with real dependencies. `COMMON` / `POST_FLAGS` hold the shared pandoc flags. |
| `bin/index` | The only real logic. One pass over `blogs/*/index.md` producing `build/{blogs.md,blogs.xml,sitemap.xml,tags/*.md,frag/,item/,meta/}`. |
| `bin/yamlseq` | `publications.yaml` / `talks.yaml` are bare YAML **sequences**; pandoc's `--metadata-file` needs a **mapping** at the root. Wraps them under a key and date-sorts newest-first. |
| `templates/page.html` | The single HTML template for every page. |
| `templates/*.md`, `*.xml`, `meta.txt` | Fragment templates consumed by `bin/index` and the Makefile. |
| `site.yaml` | Site-wide metadata: nav, footer, `og:` values, `title-suffix`. Passed to every pandoc call. |
| `pages/` | Hand-written page bodies. `*-intro.md` are the prose headers of the four generated listing pages. |
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
  newline.** In `templates/publications.md` the conditional therefore starts its own
  line; putting it back at end-of-line silently removes the blank line between
  entries, and the next `###` stops being parsed as a heading.
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
  which is enabled for every page
- `# <1>` code-annotation markers render literally as comments, with the explanatory
  numbered list following the block. This is accepted, not broken.

## Deploy

`.github/workflows/publish.yml` runs on push to `master`: installs a pinned pandoc
`.deb` (the apt package lags behind the 3.x features this build uses), runs `make`,
and publishes `_site` to `gh-pages` via `peaceiris/actions-gh-pages` with
`cname: arumoy.me`. `CNAME` is also copied into `_site` by the Makefile.
