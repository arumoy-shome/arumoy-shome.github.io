#!/usr/bin/env bash
# 52-leaked-syntax: nothing that should have been consumed by the build
# reaches the reader.
#
# Three families, all of which render as literal text rather than failing:
#   - Quarto syntax, deliberately removed during the migration. Nothing in
#     this build understands it any more.
#   - unexpanded pandoc template variables, which mean a template referenced
#     something the metadata did not supply.
#   - markdown that was escaped instead of parsed, the signature of a value
#     passed via --metadata rather than --metadata-file.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site
assert_dir "$SITE" "the site is built" || exit 1

# hits PATTERN -- "page:line:text" for each match outside code blocks. Several
# posts document this very syntax inside code fences, so the scan runs over
# visible prose and attributes only.
hits() {
  local pat=$1 f
  while IFS= read -r f; do
    visible_text "$f" | grep -nE "$pat" | sed "s#^#${f#"$SITE"/}:#"
  done < <(site_html "$SITE") | head -5
}

# --- Quarto leftovers ------------------------------------------------------
assert_eq "" "$(hits ':::')"              "no Quarto div fences"
assert_eq "" "$(hits '@fig-')"            "no @fig- cross references"
assert_eq "" "$(hits 'filename=')"        "no filename= fence attributes"
assert_eq "" "$(hits '\{python\}|\{r\}')" "no executable code cells"
assert_eq "" "$(hits 'callout-(note|tip|warning|important|caution)')" "no callout classes"

# --- unexpanded template variables ----------------------------------------
# A literal $if(, $for( or $endif$ in the output means a template line was
# emitted rather than evaluated.
assert_eq "" "$(hits '\$(if|for|endif|endfor|sep)\(?')" "no pandoc template control syntax"
for v in title body abstract date slug pubdate site-url description \
         postnav older-url older-title newer-url newer-title; do
  assert_eq "" "$(hits "\\\$$v\\\$")" "no unexpanded \$$v\$"
done

# --- escaped markdown ------------------------------------------------------
# blogs.html is assembled from markdown fragments, so post abstracts get a real
# markdown parse on the second pass. A backslash-escaped bracket here is the
# signature of a value that reached pandoc as an escaped string instead.
assert_eq "" "$(grep -nE '\\\[|\\\]|\\\*' "$SITE/blogs.html" | head -5)" \
  "no backslash-escaped markdown in the listing page"

# --- the markdown intermediate did its job --------------------------------
# talks.yaml contains inline markdown. The two-stage pipeline exists so it
# gets a real markdown parse; if it were emitted as HTML in one pass, the
# source characters would survive verbatim.
talks=$(cat "$SITE/talks.html")
assert_not_contains "$talks" '^th^' "superscript source does not survive into talks"
assert_not_contains "$talks" '**'   "bold source does not survive into talks"
assert_not_match "$talks" '\]\(http' "link source does not survive into talks"

# The equivalent hazard for publications.html, which comes from BibTeX rather
# than YAML: a mis-parsed entry leaks LaTeX braces and accent escapes instead.
pubs=$(cat "$SITE/publications.html")
assert_not_match "$pubs" '\{\\'    "no LaTeX accent escape survives into publications"
assert_not_match "$pubs" '\\[a-z]+\{' "no LaTeX command survives into publications"
assert_not_contains "$pubs" '}}'   "no BibTeX brace survives into publications"

# --- citations -------------------------------------------------------------
# --citeproc runs on every page. An unresolved key renders as a marker rather
# than failing the build.
assert_eq "" "$(hits '\[@[a-zA-Z]')"   "no unprocessed citation keys"
assert_eq "" "$(hits '\*\*\?\?\?\*\*')" "no unresolved-citation markers"
assert_eq "" "$(hits '\(\?\?\?\)')"     "no unresolved-citation parentheses"

# --- generic ---------------------------------------------------------------
# Pandoc emits nothing containing these unless something went wrong.
assert_eq "" "$(hits 'Could not find data file')" "no pandoc error text in the output"
assert_eq "" "$(hits '\[WARNING\]')"              "no pandoc warnings in the output"

n=$(site_html "$SITE" | wc -l | tr -d ' ')
note "scanned $n built pages"
