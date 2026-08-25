#!/usr/bin/env bash
# 60-listings: the two-stage pipeline behind publications.html and talks.html.
#
# Both are built in TWO pandoc passes, and the intermediate is markdown, not
# HTML: data -> markdown-emitting template -> build/<name>.md -> page.html.
# That is what lets values inside the YAML contain real markdown -- "46^th^"
# in a subtitle, bold and links inside a talk abstract. Collapsing this into a
# single HTML-emitting pass would render those as literal text.
#
# The other hazard is structural: in templates/publications.md the $if(...)$
# has to start its own line. A conditional opening at the END of a template
# line swallows the following newline, the blank line between entries goes
# away, and the next ### stops being parsed as a heading -- so entries quietly
# collapse into one paragraph.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
B=$REPO_ROOT/build

assert_file "$SITE/publications.html" "publications page is built" || exit 1
assert_file "$SITE/talks.html" "talks page is built" || exit 1

pubs_html=$(cat "$SITE/publications.html")
talks_html=$(cat "$SITE/talks.html")

# --- every record becomes an entry -----------------------------------------
n_pubs=$(grep -c '^- ' publications.yaml)
n_talks=$(grep -c '^- ' talks.yaml)
assert_eq "$n_pubs"  "$(printf '%s' "$pubs_html"  | grep -c '<h3')" "one <h3> per publication"
assert_eq "$n_talks" "$(printf '%s' "$talks_html" | grep -c '<h3')" "one <h3> per talk"
note "$n_pubs publications, $n_talks talks"

# --- the blank-line trap ---------------------------------------------------
# Every ### in the markdown intermediate must be preceded by a blank line, or
# pandoc reads it as paragraph text rather than a heading.
for f in "$B/publications.md" "$B/talks.md"; do
  assert_file "$f" "$(basename "$f") intermediate exists"
  bad=$(awk 'prev != "" && /^### / { print NR": "$0 } { prev = $0 }' "$f")
  assert_eq "" "$bad" "$(basename "$f"): every ### is preceded by a blank line"
done

# And the intermediate really is markdown, not HTML.
assert_not_contains "$(cat "$B/publications.md")" "<h3" "the intermediate is markdown, not HTML"
assert_match "$(cat "$B/publications.md")" '^### ' "the intermediate uses markdown headings"

# --- inline markdown gets a real parse -------------------------------------
# "46^th^" in a subtitle must become a superscript element.
assert_contains "$(cat publications.yaml)" '46^th^' "the source really contains 46^th^"
assert_contains "$pubs_html" '<sup>th</sup>' "superscript markup is parsed, not printed"
assert_not_contains "$pubs_html" '46^th^' "the raw superscript source does not survive"
assert_not_contains "$pubs_html" '5^th^'  "nor any other superscript source"

# Talk abstracts contain bold links; both must render.
assert_contains "$talks_html" '<strong>' "bold in a talk abstract is parsed"
assert_match "$talks_html" '<a href="https://nlbse2024\.github\.io/?"' "a link in a talk abstract is parsed"
assert_not_contains "$talks_html" '**[' "no literal bold-link source survives"

# --- conditional fields ----------------------------------------------------
# A publication with `path:` is a linked heading; one without is plain text.
# The first record has a path, the second does not.
assert_match "$pubs_html" '<h3[^>]*><a href="https://arxiv\.org/abs/2408\.00153"' \
  "a publication with path: renders as a link"

# Count linked vs plain headings against the data.
n_path=$(grep -c '^  path:' publications.yaml)
n_linked=$(printf '%s' "$pubs_html" | grep -cE '<h3[^>]*><a href=')
assert_eq "$n_path" "$n_linked" "exactly the publications with path: are linked"

n_plain=$((n_pubs - n_path))
n_unlinked=$(printf '%s' "$pubs_html" | grep -cE '<h3[^>]*>[^<]' )
assert_eq "$n_plain" "$n_unlinked" "the rest render as plain headings"

# `doi:` is optional and must not leave an empty paragraph behind.
assert_eq "" "$(printf '%s' "$pubs_html" | grep -n '<p></p>')" "no empty paragraphs from absent fields"
assert_not_contains "$pubs_html" '$if(' "no template syntax reached the page"

# --- ordering --------------------------------------------------------------
# bin/yamlseq sorts newest-first, and that order must survive both passes.
pub_dates=$(printf '%s' "$pubs_html" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' | head -20)
if [[ -n $pub_dates ]]; then
  sorted=$(printf '%s' "$pub_dates" | sort -r)
  assert_eq "$sorted" "$pub_dates" "publications are listed newest-first"
fi
talk_dates=$(printf '%s' "$talks_html" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}')
if [[ -n $talk_dates ]]; then
  sorted=$(printf '%s' "$talk_dates" | sort -r)
  assert_eq "$sorted" "$talk_dates" "talks are listed newest-first"
fi

# --- the intro prose -------------------------------------------------------
# Each listing page is its *-intro.md followed by the generated entries.
for pair in "publications publications-intro.md" "talks talks-intro.md"; do
  set -- $pair
  name=$1 intro=$2
  first_words=$(sed -n '/^---$/,/^---$/!p' "pages/$intro" | grep -m1 '[A-Za-z]' | cut -c1-30)
  if [[ -n $first_words ]]; then
    assert_contains "$(cat "$SITE/$name.html")" "${first_words% *}" "$name.html carries its intro prose"
  fi
  intro_at=$(grep -n "${first_words% *}" "$SITE/$name.html" | head -1 | cut -d: -f1)
  h3_at=$(grep -n '<h3' "$SITE/$name.html" | head -1 | cut -d: -f1)
  if [[ -n $intro_at && -n $h3_at ]]; then
    assert_ok "$name.html: intro precedes the first entry" -- test "$intro_at" -lt "$h3_at"
  fi
done

# --- authors ---------------------------------------------------------------
assert_contains "$pubs_html" "Arumoy Shome" "author names are rendered"
assert_not_contains "$pubs_html" "\$for(" "the author loop was expanded"
