#!/usr/bin/env bash
# 42-make-deps: the dependency graph.
#
# A missing prerequisite does not break the build; it makes an edit silently
# not take effect until the next `make clean`, which is worse. Each case here
# touches one input and checks what make decides to rebuild.
#
# Two properties of this build shape the assertions:
#   - bin/index deletes and regenerates the whole of build/ on every run, and
#     every post page depends on build/blogs.md, so editing ONE post rebuilds
#     ALL post pages. CLAUDE.md calls this intentional coarseness.
#   - category pages sit behind a .PHONY target and are re-rendered on every
#     build, so they are excluded from the "exactly these changed" sets.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
W=$TMP/repo
repo_copy "$W"

make_in "$W" -j8 >"$TMP/build.log" 2>&1 || {
  fail "initial build failed: $(_trunc "$(cat "$TMP/build.log")" 400)"
  exit 1
}

# rebuilt AFTER touching the given inputs: the _site files make regenerated,
# minus the category pages that always churn.
rebuilt() {
  local stamp=$TMP/stamp
  : >"$stamp"
  ( cd "$W" && touch "$@" ) || return 1
  make_in "$W" -j8 >"$TMP/make.log" 2>&1 || {
    _bad "$(_where 2)" "make failed after touching $*" "$(_trunc "$(cat "$TMP/make.log")" 400)"
    return 1
  }
  # Category pages are dropped (the phony target always re-renders them); the
  # tag index is kept, because it has a real rule and so carries information.
  ( cd "$W" && find _site -type f -newer "$stamp" ) \
    | awk '$0 !~ /^_site\/blogs\/tags\// || $0 ~ /\/index\.html$/' \
    | sort
}

changed=""

# --- a single post ---------------------------------------------------------
changed=$(rebuilt blogs/aims/index.md)
assert_contains "$changed" "_site/blogs/aims/index.html" "editing a post rebuilds its own page"
assert_contains "$changed" "_site/blogs.html"            "...and the blog index"
assert_contains "$changed" "_site/blogs.xml"             "...and the feed"
assert_contains "$changed" "_site/sitemap.xml"           "...and the sitemap"
assert_contains "$changed" "_site/blogs/tags/index.html" "...and the tag index"
# The documented coarseness: every post page goes with it.
assert_contains "$changed" "_site/blogs/yob/index.html" \
  "every post page rebuilds too (intentional coarseness, see CLAUDE.md)"
assert_not_contains "$changed" "_site/talks.html"        "but not unrelated listing pages"
assert_not_contains "$changed" "_site/resume.html"       "but not unrelated static pages"

# --- site-wide inputs ------------------------------------------------------
changed=$(rebuilt site.yaml)
for p in index.html blogs.html talks.html publications.html resume.html license.html; do
  assert_contains "$changed" "_site/$p" "site.yaml rebuilds $p"
done
assert_contains "$changed" "_site/blogs/aims/index.html" "site.yaml rebuilds post pages"

changed=$(rebuilt templates/page.html)
for p in index.html blogs.html talks.html resume.html; do
  assert_contains "$changed" "_site/$p" "the page template rebuilds $p"
done
assert_contains "$changed" "_site/blogs/aims/index.html" "the page template rebuilds post pages"

# bibliography.bib is read by every pandoc call via --citeproc. Before it was
# made a prerequisite, editing a reference rebuilt nothing at all.
changed=$(rebuilt bibliography.bib)
assert_contains "$changed" "_site/blogs/aims/index.html" "the bibliography rebuilds post pages"
assert_contains "$changed" "_site/index.html"            "the bibliography rebuilds plain pages"
assert_contains "$changed" "_site/blogs.html"            "the bibliography rebuilds listing pages"

# --- narrow inputs ---------------------------------------------------------
# These must rebuild their own output and nothing else.
changed=$(rebuilt talks.yaml)
assert_contains "$changed" "_site/talks.html" "talks.yaml rebuilds the talks page"
assert_not_contains "$changed" "_site/blogs.html"        "talks.yaml leaves the blog index alone"
assert_not_contains "$changed" "_site/publications.html" "talks.yaml leaves publications alone"

changed=$(rebuilt publications.yaml)
assert_contains "$changed" "_site/publications.html" "publications.yaml rebuilds its page"
assert_not_contains "$changed" "_site/talks.html"    "publications.yaml leaves talks alone"

changed=$(rebuilt styles.css)
assert_eq "_site/styles.css" "$changed" "styles.css is recopied, and nothing else runs"

changed=$(rebuilt robots.txt)
assert_eq "_site/robots.txt" "$changed" "robots.txt is recopied, and nothing else runs"

changed=$(rebuilt CNAME)
assert_eq "_site/CNAME" "$changed" "CNAME is recopied, and nothing else runs"

# --- the generators themselves ---------------------------------------------
changed=$(rebuilt bin/index)
assert_contains "$changed" "_site/blogs.html" "editing bin/index regenerates the index"
assert_contains "$changed" "_site/blogs.xml"  "editing bin/index regenerates the feed"

changed=$(rebuilt bin/yamlseq)
assert_contains "$changed" "_site/publications.html" "editing bin/yamlseq regenerates publications"
assert_contains "$changed" "_site/talks.html"        "editing bin/yamlseq regenerates talks"

# --- fragment templates and intros -----------------------------------------
changed=$(rebuilt templates/listing.md)
assert_contains "$changed" "_site/blogs.html" "the listing template regenerates the index"

changed=$(rebuilt templates/feed-item.xml)
assert_contains "$changed" "_site/blogs.xml" "the feed-item template regenerates the feed"

changed=$(rebuilt pages/blogs-intro.md)
assert_contains "$changed" "_site/blogs.html" "the blog intro regenerates the index"

changed=$(rebuilt pages/tags-intro.md)
assert_contains "$changed" "_site/blogs/tags/index.html" "the tags intro regenerates the tag index"

changed=$(rebuilt templates/publications.md)
assert_contains "$changed" "_site/publications.html" "the publications template regenerates its page"

changed=$(rebuilt templates/talks.md)
assert_contains "$changed" "_site/talks.html" "the talks template regenerates its page"

# --- post assets -----------------------------------------------------------
asset=$( cd "$W" && find blogs -type f ! -name '*.md' | head -1 )
if [[ -n $asset ]]; then
  changed=$(rebuilt "$asset")
  assert_contains "$changed" "_site/$asset" "touching a post asset recopies it into _site"
else
  note "no post assets found to check"
fi
