#!/usr/bin/env bash
# 53-page-head: what templates/page.html puts in every <head>.
#
# The head is where --wrap=none earns its place on the HTML pass: pandoc's
# writer folds long lines, and a fold inside <title> or a meta content=""
# value corrupts the attribute. It is also where the highlighting stylesheet
# has to be ordered correctly, since pandoc's inlined palette is light-theme
# only and styles.css overrides its token colours for dark mode.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
assert_dir "$SITE" "the site is built" || exit 1

pages=$(site_html "$SITE")
n=0

while IFS= read -r f; do
  page=${f#"$SITE"/}
  n=$((n + 1))

  # --- title -------------------------------------------------------------
  n_title=$(grep -c '<title>' "$f")
  assert_eq "1" "$n_title" "$page has exactly one <title>"

  # On one line, and non-empty. A fold would leave <title> and </title> on
  # different lines, which is precisely what --wrap=none prevents.
  title_line=$(grep '<title>' "$f")
  assert_match "$title_line" '<title>.+</title>' "$page: <title> opens and closes on one line"

  title=$(printf '%s' "$title_line" | sed -e 's/.*<title>//' -e 's#</title>.*##')
  assert_ne "" "$title" "$page has a non-empty title"

  # --- description -------------------------------------------------------
  desc_line=$(grep '<meta name="description"' "$f")
  assert_match "$desc_line" '<meta name="description" content="[^"]*" />' \
    "$page: description meta is a single well-formed tag"
  assert_eq "1" "$(grep -c '<meta name="description"' "$f")" "$page has one description"

  # --- open graph --------------------------------------------------------
  for prop in og:type og:site_name og:title og:description; do
    assert_eq "1" "$(grep -c "property=\"$prop\"" "$f")" "$page has $prop"
  done
  assert_contains "$(cat "$f")" '<meta property="og:site_name" content="Arumoy Shome" />' \
    "$page: og:site_name comes from site.yaml"

  # --- stylesheet ordering ----------------------------------------------
  # Where pandoc inlined a highlighting palette, it must appear BEFORE
  # styles.css: the two set the same token colours at equal specificity, so
  # source order decides which wins in dark mode.
  if grep -q '<style>' "$f"; then
    style_at=$(grep -n '<style>' "$f" | head -1 | cut -d: -f1)
    css_at=$(grep -n 'href="/styles.css"' "$f" | head -1 | cut -d: -f1)
    assert_ok "$page: highlighting <style> precedes styles.css" -- \
      test "$style_at" -lt "$css_at"
  fi

  # --- furniture ---------------------------------------------------------
  assert_contains "$(cat "$f")" 'href="/styles.css"' "$page links the stylesheet"
  assert_contains "$(cat "$f")" 'type="application/rss+xml"' "$page advertises the feed"
  assert_contains "$(cat "$f")" '<html lang="en"' "$page declares a language"
done <<<"$pages"

note "checked $n pages"

# --- nav on every page -----------------------------------------------------
# The nav comes from site.yaml and is rendered into every page; a missing
# entry is a site-wide regression rather than a single broken page.
while IFS= read -r href; do
  missing=""
  while IFS= read -r f; do
    grep -q "href=\"$href\"" "$f" || missing="$missing ${f#"$SITE"/}"
  done <<<"$pages"
  assert_eq "" "$missing" "nav entry $href appears on every page"
done < <(sed -n '/^nav:/,/^links:/s/^ *href: "\(.*\)"/\1/p' site.yaml)

# --- posts differ from plain pages ----------------------------------------
# Posts are built with POST_FLAGS: --toc and an author. Plain pages are not.
#
# --toc emits a nav only when the document has headings, so "every post has a
# TOC" is not the property to assert -- several posts are continuous prose and
# correctly get none. Counting headings in the markdown source does not work
# either: posts like blogs/today are full of shell comments inside code
# fences, which look exactly like ATX headings.
#
# What is worth checking is that the TOCs that do exist are correct: every
# entry must point at an id that is actually on the page.
n_toc=0
bad_toc=""
for p in "$SITE"/blogs/*/index.html; do
  grep -q 'role="doc-toc"' "$p" || continue
  n_toc=$((n_toc + 1))
  slug=$(basename "$(dirname "$p")")
  while IFS= read -r anchor; do
    grep -q "id=\"$anchor\"" "$p" || bad_toc="$bad_toc $slug#$anchor"
  done < <(sed -n '/role="doc-toc"/,/<\/nav>/p' "$p" \
           | grep -oE 'href="#[^"]+"' | sed 's/href="#//; s/"$//')
done
assert_eq "" "$bad_toc" "every table-of-contents entry points at a real heading"
assert_ne "0" "$n_toc" "posts are built with --toc (found $n_toc pages with one)"
note "$n_toc of 18 posts have a table of contents"

post=$SITE/blogs/research-workflow-plaintext/index.html
assert_contains "$(cat "$post")" 'role="doc-toc"' "a post with headings carries a TOC"
assert_contains "$(cat "$post")" '<meta name="author" content="Arumoy Shome"' "a post carries an author"
assert_contains "$(cat "$SITE/blogs/aims/index.html")" 'href="/blogs/tags/' "a post links its categories"

assert_not_contains "$(cat "$SITE/license.html")" 'role="doc-toc"' "a plain page has no TOC"

# The title suffix is appended everywhere except where a page overrides it.
assert_contains "$(cat "$post")" '– Arumoy Shome</title>' "post titles carry the suffix"
assert_not_contains "$(cat "$SITE/index.html")" '– Arumoy Shome</title>' \
  "the home page overrides the suffix from its own frontmatter"

# --- descriptions are real -------------------------------------------------
# Every post's meta description should be its abstract, flattened -- not
# empty, and not the site-wide fallback.
empty=""
for p in "$SITE"/blogs/*/index.html; do
  d=$(grep '<meta name="description"' "$p" | sed -e 's/.*content="//' -e 's/" \/>.*//')
  [[ -n $d ]] || empty="$empty ${p#"$SITE"/}"
done
assert_eq "" "$empty" "every post page has a non-empty description"
