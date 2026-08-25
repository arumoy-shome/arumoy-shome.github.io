#!/usr/bin/env bash
# 50-urls: the URL contract CLAUDE.md marks "do not break".
#
# These paths were inherited from the Quarto site and verified against it
# during the migration. Every one of them is a live URL someone may have
# linked to, so a change here is a change to other people's links, not just
# to this repo's layout.
#
# The golden manifest is the ONLY byte-exact artefact in the suite: it lists
# file names, which do not vary with the pandoc version. Regenerate it
# deliberately with `tests/run --update-golden` when adding a post.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
GOLDEN=$TESTDIR/golden/site-manifest.txt

assert_dir "$SITE" "the site is built" || exit 1

# --- the manifest ----------------------------------------------------------
# LC_ALL=C so the ordering does not depend on the locale: macOS and Ubuntu
# collate differently, and the manifest is compared byte for byte.
actual=$(cd "$SITE" && find . -type f | LC_ALL=C sort)
if [[ -f $GOLDEN ]]; then
  expected=$(cat "$GOLDEN")
  if [[ $actual != "$expected" ]]; then
    _bad "$(_where)" "the set of built files changed" \
      "$(diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | head -30)" \
      "if this is intended, run: tests/run --update-golden"
  else
    _ok
  fi
else
  fail "tests/golden/site-manifest.txt is missing; run tests/run --update-golden"
fi

# --- flat top-level pages --------------------------------------------------
# Not /blogs/index.html, /talks/index.html and so on.
for p in index blogs talks publications resume license; do
  assert_file "$SITE/$p.html" "/$p.html is a flat page"
done

# --- directory-style posts -------------------------------------------------
n=0
for post in blogs/*/index.md; do
  slug=$(basename "$(dirname "$post")")
  assert_file "$SITE/blogs/$slug/index.html" "/blogs/$slug/ is directory-style"
  assert_no_file "$SITE/blogs/$slug.html" "/blogs/$slug.html does not exist"
  n=$((n + 1))
done
note "checked $n post URLs"

# The two must coexist: _site/blogs/ holds the posts, _site/blogs.html is the
# index. An index.html inside _site/blogs/ would shadow the listing at /blogs/.
assert_dir  "$SITE/blogs"       "_site/blogs/ is a directory of posts"
assert_file "$SITE/blogs.html"  "_site/blogs.html is the listing page"
assert_no_file "$SITE/blogs/index.html" "nothing shadows /blogs/"

# --- fixed paths -----------------------------------------------------------
for p in blogs.xml sitemap.xml robots.txt CNAME styles.css; do
  assert_file "$SITE/$p" "/$p keeps its path"
done
assert_eq "arumoy.me" "$(tr -d '\n' <"$SITE/CNAME")" "CNAME names the site"

# --- the tag family --------------------------------------------------------
# The only URL family added after the migration.
assert_dir  "$SITE/blogs/tags"            "/blogs/tags/ exists"
assert_file "$SITE/blogs/tags/index.html" "/blogs/tags/ is directory-style"
n_tags=$(find "$SITE/blogs/tags" -name '*.html' ! -name index.html | wc -l | tr -d ' ')
assert_ne "0" "$n_tags" "category pages are built ($n_tags of them)"

# Category pages are flat .html inside that directory, not directories.
while IFS= read -r f; do
  assert_match "$f" '\.html$' "category page $f is a flat .html"
done < <(find "$SITE/blogs/tags" -mindepth 1 -maxdepth 1 ! -name index.html -type f)

# --- nothing unexpected at the top level -----------------------------------
top=$(cd "$SITE" && find . -maxdepth 1 -type f | sed 's#^\./##' | LC_ALL=C sort | paste -sd' ' -)
assert_eq "CNAME blogs.html blogs.xml index.html license.html profile.jpeg publications.html resume.html robots.txt sitemap.xml styles.css talks.html" \
  "$top" "the top level holds exactly the expected files"

# --- sitemap agrees with the contract --------------------------------------
sm=$(cat "$SITE/sitemap.xml")
for p in "" blogs.html talks.html publications.html resume.html license.html blogs/tags/; do
  assert_contains "$sm" "<loc>https://arumoy.me/$p</loc>" "sitemap lists /$p"
done
