#!/usr/bin/env bash
# 60-listings: the two-stage pipeline behind talks.html.
#
# It is built in TWO pandoc passes, and the intermediate is markdown, not
# HTML: talks.yaml -> markdown-emitting template -> build/talks.md ->
# page.html. That is what lets values inside the YAML contain real markdown --
# bold and links inside a talk abstract. Collapsing this into a single
# HTML-emitting pass would render those as literal text.
#
# The other hazard is structural: a $if(...)$ opening at the END of a template
# line swallows the following newline, the blank line between entries goes
# away, and the next ### stops being parsed as a heading -- so entries quietly
# collapse into one paragraph. templates/talks.md has no conditional today,
# but the blank-line assertion below is what would catch one added carelessly.
#
# publications.html used to be built the same way. It is now a plain page
# rendered by citeproc from bibliography.bib; see 61-publications.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
B=$REPO_ROOT/build

assert_file "$SITE/talks.html" "talks page is built" || exit 1

talks_html=$(cat "$SITE/talks.html")

# --- every record becomes an entry -----------------------------------------
n_talks=$(grep -c '^- ' talks.yaml)
assert_eq "$n_talks" "$(printf '%s' "$talks_html" | grep -c '<h3')" "one <h3> per talk"
note "$n_talks talks"

# --- the blank-line trap ---------------------------------------------------
# Every ### in the markdown intermediate must be preceded by a blank line, or
# pandoc reads it as paragraph text rather than a heading.
assert_file "$B/talks.md" "talks.md intermediate exists"
bad=$(awk 'prev != "" && /^### / { print NR": "$0 } { prev = $0 }' "$B/talks.md")
assert_eq "" "$bad" "talks.md: every ### is preceded by a blank line"

# And the intermediate really is markdown, not HTML.
assert_not_contains "$(cat "$B/talks.md")" "<h3" "the intermediate is markdown, not HTML"
assert_match "$(cat "$B/talks.md")" '^### ' "the intermediate uses markdown headings"

# --- inline markdown gets a real parse -------------------------------------
# Talk abstracts contain bold links; both must render.
assert_contains "$talks_html" '<strong>' "bold in a talk abstract is parsed"
assert_match "$talks_html" '<a href="https://nlbse2024\.github\.io/?"' "a link in a talk abstract is parsed"
assert_not_contains "$talks_html" '**[' "no literal bold-link source survives"

# Absent optional fields must not leave an empty paragraph behind, and no
# template syntax may reach the page.
assert_eq "" "$(printf '%s' "$talks_html" | grep -n '<p></p>')" "no empty paragraphs from absent fields"
assert_not_contains "$talks_html" '$if(' "no template syntax reached the page"
assert_not_contains "$talks_html" "\$for(" "the entry loop was expanded"

# --- ordering --------------------------------------------------------------
# bin/yamlseq sorts newest-first, and that order must survive both passes.
talk_dates=$(printf '%s' "$talks_html" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}')
assert_ne "" "$talk_dates" "talk dates are rendered, so the ordering check has something to check"
if [[ -n $talk_dates ]]; then
  sorted=$(printf '%s' "$talk_dates" | sort -r)
  assert_eq "$sorted" "$talk_dates" "talks are listed newest-first"
fi

# --- the intro prose -------------------------------------------------------
# The listing page is talks-intro.md followed by the generated entries.
first_words=$(sed -n '/^---$/,/^---$/!p' pages/talks-intro.md | grep -m1 '[A-Za-z]' | cut -c1-30)
if [[ -n $first_words ]]; then
  assert_contains "$talks_html" "${first_words% *}" "talks.html carries its intro prose"
fi
intro_at=$(grep -n "${first_words% *}" "$SITE/talks.html" | head -1 | cut -d: -f1)
h3_at=$(grep -n '<h3' "$SITE/talks.html" | head -1 | cut -d: -f1)
if [[ -n $intro_at && -n $h3_at ]]; then
  assert_ok "talks.html: intro precedes the first entry" -- test "$intro_at" -lt "$h3_at"
fi
