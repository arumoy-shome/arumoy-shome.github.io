#!/usr/bin/env bash
# 61-publications: publications.html, which citeproc renders from
# bibliography.bib.
#
# The page is pages/publications.md: a `nocite:` list of bibkeys plus an empty
# ::: {#refs} div that citeproc fills. Two things about that arrangement are
# worth pinning down.
#
# First, bibliography.bib is dual-purpose -- it holds both the works cited by
# blog posts and Arumoy's own papers -- so the nocite list is the only thing
# keeping Zhang, Heer, Quaranta and Pimentel off a page titled "Publications".
# A stray `@*` would pull all of them in and nothing else would complain.
#
# Second, the explicit #refs div is what suppresses the "References" heading
# that COMMON's --metadata reference-section-title would otherwise insert.
# Citeproc only emits that header when it appends the bibliography itself.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
PAGE=pages/publications.md

assert_file "$SITE/publications.html" "publications page is built" || exit 1
assert_file "$PAGE" "the source page exists" || exit 1

html=$(cat "$SITE/publications.html")

# The keys the page asks for, read out of the nocite block rather than
# hardcoded here, so adding a publication does not need a test edit.
keys=$(sed -n '/^nocite:/,/^[a-z-]*:/p' "$PAGE" | grep -oE '@[A-Za-z][A-Za-z0-9_-]*' | tr -d '@' | sort)
n_keys=$(printf '%s\n' "$keys" | grep -c .)
assert_ne "0" "$n_keys" "the page nominates at least one bibkey"
note "$n_keys publications"

# --- the bibliography landed where the page put it --------------------------
assert_match "$html" '<div id="refs"[^>]*class="[^"]*publications' \
  "the #refs div is present and kept its .publications class"
assert_match "$html" 'class="[^"]*csl-bib-body' "citeproc filled it in"

# The explicit div means no "References" heading, despite COMMON passing
# reference-section-title for the benefit of blog posts.
assert_not_match "$html" '<h[12][^>]*>References<' "no stray References heading"
assert_not_match "$html" 'id="bibliography"' "no citeproc-generated bibliography section"

# --- one entry per nominated key, and nothing else --------------------------
n_entries=$(printf '%s' "$html" | grep -c 'class="csl-entry"')
assert_eq "$n_keys" "$n_entries" "one csl-entry per nocite key"

for k in $keys; do
  assert_contains "$html" "id=\"ref-$k\"" "$k is rendered"
done

# The works cited by blog posts share bibliography.bib and must not appear.
# Anything in the .bib that the page did not nominate is a leak.
all_keys=$(grep -oE '^@[A-Za-z]+\{[[:space:]]*[A-Za-z][A-Za-z0-9_-]*' bibliography.bib \
  | sed -E 's/^@[A-Za-z]+\{[[:space:]]*//' | sort)
foreign=$(comm -23 <(printf '%s\n' "$all_keys") <(printf '%s\n' "$keys"))
assert_ne "" "$foreign" "bibliography.bib really does hold works this page must exclude"
for k in $foreign; do
  assert_not_contains "$html" "id=\"ref-$k\"" "$k is cited by a post, not a publication: it must not leak in"
done
note "excluded: $(printf '%s' "$foreign" | tr '\n' ' ')"

# --- the entries say what they should ---------------------------------------
assert_contains "$html" "Arumoy Shome" "author names are rendered"
# The chosen style lists every author rather than truncating to "et al.",
# which is the whole reason ACE (where Arumoy is second author) reads sensibly.
assert_not_contains "$html" "et al." "no author list is truncated"
assert_match "$html" 'class="csl-left-margin"' "the numeric label is its own element (styles.css floats it)"

# Accented names and BibTeX braces must survive the .bib -> HTML trip intact.
assert_contains "$html" "Luís Cruz" "LaTeX accent escapes are resolved"
assert_not_match "$html" '\{\\' "no raw LaTeX escape reached the page"
assert_not_match "$html" '\}\}' "no raw BibTeX brace reached the page"

# --- prose and layout -------------------------------------------------------
first_words=$(sed -n '/^---$/,/^---$/!p' "$PAGE" | grep -m1 '[A-Za-z]' | cut -c1-30)
assert_contains "$html" "${first_words% *}" "publications.html carries its intro prose"
intro_at=$(grep -n "${first_words% *}" "$SITE/publications.html" | head -1 | cut -d: -f1)
refs_at=$(grep -n 'id="refs"' "$SITE/publications.html" | head -1 | cut -d: -f1)
if [[ -n $intro_at && -n $refs_at ]]; then
  assert_ok "the intro precedes the list" -- test "$intro_at" -lt "$refs_at"
fi

# The page deliberately no longer has a heading per entry; if <h3>s come back,
# something has reintroduced the old two-stage listing.
assert_not_contains "$html" "<h3" "entries are citations, not headings"
