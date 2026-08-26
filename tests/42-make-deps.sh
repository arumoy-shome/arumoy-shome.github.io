#!/usr/bin/env bash
# 42-make-deps: the dependency graph.
#
# A missing prerequisite does not break the build; it makes an edit silently
# not take effect until the next `make clean`, which is worse. Each case here
# touches one input and checks what make decides to rebuild.
#
# One property of this build shapes the assertions: bin/index deletes and
# regenerates the whole of build/ on every run, and every post page depends on
# build/blogs.md, so editing ONE post rebuilds ALL post pages. CLAUDE.md calls
# this intentional coarseness.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
W=$TMP/repo
repo_copy "$W"

make_in "$W" -j8 >"$TMP/build.log" 2>&1 || {
  fail "initial build failed: $(_trunc "$(cat "$TMP/build.log")" 400)"
  exit 1
}

# rebuilt AFTER touching the given inputs: the _site files make regenerated.
# Nothing is filtered out any more -- the phony tag target that used to churn
# on every build is gone, so this is the exact set.
rebuilt() {
  local stamp=$TMP/stamp
  # macOS ships GNU Make 3.81, which compares mtimes at one-second resolution.
  # A build fast enough to finish inside the same second as the next touch
  # leaves make unable to tell prerequisite from target, and it silently
  # decides the target is up to date -- so this reports "nothing rebuilt" for
  # a dependency that is in fact wired correctly. Cross a second boundary
  # before touching so the comparison is never ambiguous.
  sleep 1
  : >"$stamp"
  ( cd "$W" && touch "$@" ) || return 1
  make_in "$W" -j8 >"$TMP/make.log" 2>&1 || {
    _bad "$(_where 2)" "make failed after touching $*" "$(_trunc "$(cat "$TMP/make.log")" 400)"
    return 1
  }
  ( cd "$W" && find _site -type f -newer "$stamp" ) | sort
}

changed=""

# --- a single post ---------------------------------------------------------
changed=$(rebuilt blogs/aims/index.md)
assert_contains "$changed" "_site/blogs/aims/index.html" "editing a post rebuilds its own page"
assert_contains "$changed" "_site/blogs.html"            "...and the blog index"
assert_contains "$changed" "_site/blogs.xml"             "...and the feed"
assert_contains "$changed" "_site/sitemap.xml"           "...and the sitemap"
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
assert_contains "$changed" "_site/publications.html"     "the bibliography rebuilds publications, which is nothing but references"

# The citation style is site-wide for the same reason, and is the sole input
# deciding how every reference on the site is formatted.
changed=$(rebuilt association-for-computing-machinery.csl)
assert_contains "$changed" "_site/blogs/aims/index.html" "the CSL rebuilds post pages"
assert_contains "$changed" "_site/index.html"            "the CSL rebuilds plain pages"
assert_contains "$changed" "_site/publications.html"     "the CSL rebuilds publications"

# --- narrow inputs ---------------------------------------------------------
# These must rebuild their own output and nothing else.
changed=$(rebuilt talks.yaml)
assert_contains "$changed" "_site/talks.html" "talks.yaml rebuilds the talks page"
assert_not_contains "$changed" "_site/blogs.html"        "talks.yaml leaves the blog index alone"
assert_not_contains "$changed" "_site/publications.html" "talks.yaml leaves publications alone"

changed=$(rebuilt pages/publications.md)
assert_contains "$changed" "_site/publications.html" "the publications page rebuilds itself"
assert_not_contains "$changed" "_site/talks.html"    "...and leaves talks alone"
assert_not_contains "$changed" "_site/blogs.html"    "...and the blog index alone"

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

# --- fragment templates and intros -----------------------------------------
changed=$(rebuilt templates/listing.md)
assert_contains "$changed" "_site/blogs.html" "the listing template regenerates the index"

changed=$(rebuilt templates/feed-item.xml)
assert_contains "$changed" "_site/blogs.xml" "the feed-item template regenerates the feed"

changed=$(rebuilt pages/blogs-intro.md)
assert_contains "$changed" "_site/blogs.html" "the blog intro regenerates the index"

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
