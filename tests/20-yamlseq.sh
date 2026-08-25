#!/usr/bin/env bash
# 20-yamlseq: bin/yamlseq wraps a bare YAML sequence in a mapping and sorts it
# newest-first, because pandoc's --metadata-file needs a mapping at the root.
# It is a real awk parser, and every publication and talk on the site goes
# through it.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
FIX=$TESTDIR/fixtures/yamlseq

# titles KEY FILE -- the title of each record, in output order. Reads the
# wrapped YAML back through pandoc, so this asserts on what pandoc actually
# parses rather than on the text bin/yamlseq emitted.
titles() {
  local key=$1 file=$2
  bin/yamlseq "$key" "$file" >"$TMP/wrapped.yaml"
  printf '$for(%s)$%s$sep$|$endfor$' "$key" "\$$key.title\$" >"$TMP/titles.tpl"
  pandoc /dev/null -f markdown -t plain --wrap=none \
    --template="$TMP/titles.tpl" --metadata-file="$TMP/wrapped.yaml"
}

# --- root mapping ----------------------------------------------------------
out=$(bin/yamlseq pubs "$FIX/basic.yaml")
assert_match "$out" '^pubs:' "output starts with the wrapping key"
assert_ok "wrapped output is valid --metadata-file input" -- \
  env sh -c "bin/yamlseq pubs '$FIX/basic.yaml' > '$TMP/v.yaml' && pandoc /dev/null --metadata-file='$TMP/v.yaml' -t plain"

# --- ordering --------------------------------------------------------------
assert_eq "Newest|Middle|Oldest" "$(titles pubs "$FIX/basic.yaml")" \
  "records come out newest-first"

# Ties: entries sharing a date come out in REVERSE file order. That falls out
# of sorting "<date>-<nnn>" filenames with sort -r, and it is pinned here so a
# future change to the sort has to be deliberate. (Note this contradicts the
# "keeps entries sharing a date stable" comment in bin/yamlseq.)
assert_eq "Third in file|Second in file|First in file|Older" \
  "$(titles pubs "$FIX/ties.yaml")" "same-date entries come out in reverse file order"

# A record with no date: sorts last, rather than being dropped.
assert_eq "Has a date|Older|No date at all" \
  "$(titles pubs "$FIX/undated.yaml")" "an undated record sorts last and survives"

# --- indentation -----------------------------------------------------------
# Records are indented by exactly two spaces so they nest under the key; blank
# lines must stay empty, since "  " on its own line is still valid YAML but
# trips some parsers.
out=$(bin/yamlseq pubs "$FIX/basic.yaml")
while IFS= read -r line; do
  [[ $line == "pubs:" ]] && continue
  if [[ -z $line ]]; then continue; fi
  assert_match "$line" '^  [^ ]|^    ' "record line is indented: $(_trunc "$line" 60)"
done <<<"$out"

blank_with_space=$(printf '%s\n' "$out" | grep -c '^[[:space:]][[:space:]]*$' || true)
assert_eq "0" "$blank_with_space" "blank lines carry no trailing indentation"

# Nested sequences keep their relative depth (authors sit under their record).
assert_contains "$out" "  - title: Newest" "record starts at two spaces"
assert_contains "$out" "    authors:" "nested key at four"
assert_contains "$out" "      - Ada Lovelace" "nested sequence item at six"

# --- inline markdown survives ---------------------------------------------
# The whole reason the pipeline emits markdown rather than HTML: values must
# reach pandoc as markdown source, unaltered.
out=$(bin/yamlseq pubs "$FIX/markdown.yaml")
assert_contains "$out" '46^th^'                  "superscript passes through verbatim"
assert_contains "$out" '**bold**'                "emphasis passes through verbatim"
assert_contains "$out" '[link](https://example.org)' "link passes through verbatim"
assert_contains "$out" '*emphasis*'              "block scalar content survives"
assert_ok "a record containing markdown still parses" -- \
  env sh -c "bin/yamlseq pubs '$FIX/markdown.yaml' > '$TMP/m.yaml' && pandoc /dev/null --metadata-file='$TMP/m.yaml' -t plain"

# --- the real data files ---------------------------------------------------
for pair in "publications publications.yaml" "talks talks.yaml"; do
  set -- $pair
  key=$1 file=$2
  n_in=$(grep -c '^- ' "$file")
  n_out=$(titles "$key" "$file" | tr '|' '\n' | grep -c .)
  assert_eq "$n_in" "$n_out" "$file: every record survives the wrap ($n_in in)"
  assert_ok "$file wraps into valid --metadata-file input" -- \
    env sh -c "bin/yamlseq '$key' '$file' > '$TMP/r.yaml' && pandoc /dev/null --metadata-file='$TMP/r.yaml' -t plain"

  # Dates must come out non-increasing, which is what the listing pages promise.
  printf '$for(%s)$%s$sep$|$endfor$' "$key" "\$$key.date\$" >"$TMP/dates.tpl"
  bin/yamlseq "$key" "$file" >"$TMP/w.yaml"
  dates=$(pandoc /dev/null -f markdown -t plain --wrap=none \
    --template="$TMP/dates.tpl" --metadata-file="$TMP/w.yaml")
  sorted=$(printf '%s' "$dates" | tr '|' '\n' | sort -r | paste -sd'|' -)
  assert_eq "$sorted" "$dates" "$file: dates are in descending order"
done
