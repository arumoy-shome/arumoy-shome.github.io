#!/usr/bin/env bash
# 70-new: bin/new scaffolds a post directory.
#
# It is the one piece of the toolchain written in Python, and it owns the slug
# that becomes a post's permanent URL (the slug table is 10-slugify). What
# matters here is that what it writes is something the rest of the build can
# actually consume: the frontmatter has to parse, and templates/meta.txt has to
# be able to read a date and title back out.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
NEW=$REPO_ROOT/bin/new

# run_new WORKDIR ARGS... -- run bin/new in an empty scratch tree.
run_new() {
  local w=$1; shift
  mkdir -p "$w"
  ( cd "$w" && "$NEW" "$@" )
}

# --- the full form ---------------------------------------------------------
w=$TMP/full
run_new "$w" -f -x -d 2026-01-30 "My Test Post" >"$TMP/out.txt" 2>&1
assert_eq "0" "$?" "bin/new exits cleanly"
post=$w/blogs/my-test-post/index.md
assert_file "$post" "the post is scaffolded at blogs/<slug>/index.md"
assert_contains "$(cat "$TMP/out.txt")" "created" "it reports what it made"

body=$(cat "$post")
assert_match "$body" '^---'                       "frontmatter opens"
assert_contains "$body" "title: My Test Post"     "the title is the one given"
assert_contains "$body" "date: 2026-01-30"        "the date is unquoted ISO"
assert_contains "$body" "abstract: |"             "the abstract is an empty block scalar"

# The date must be unquoted: bin/index reads it through templates/meta.txt and
# then hands it to date(1).
assert_not_contains "$body" 'date: "2026-01-30"'  "the date is not quoted"

# --- the build can read it back --------------------------------------------
# This is the real contract: whatever bin/new writes, bin/index must be able
# to parse with templates/meta.txt.
meta=$(pandoc "$post" --template=templates/meta.txt -t plain --wrap=none)
assert_eq "2026-01-30|My Test Post" "${meta%$'\n'}" \
  "meta.txt reads the date and title back"

# And pandoc must accept the document at all.
assert_ok "the scaffolded post is valid pandoc input" -- \
  pandoc "$post" -t html --template=templates/feed-item.xml \
    --metadata slug=my-test-post --metadata site-url=https://example.org

# --- a title containing the field separator --------------------------------
# meta.txt is a two-field, `|`-delimited line and bin/index splits on the first
# `|`. The title is the last field precisely so a pipe inside it cannot corrupt
# the split.
w=$TMP/pipe
run_new "$w" -f -x -d 2026-02-01 "Pipes | In Titles" >/dev/null 2>&1
post=$w/blogs/pipes-in-titles/index.md
assert_file "$post" "a title containing a pipe still scaffolds"
meta=$(pandoc "$post" --template=templates/meta.txt -t plain --wrap=none)
assert_eq "2026-02-01" "${meta%%|*}" "the date survives a pipe in the title"

# --- default date ----------------------------------------------------------
w=$TMP/today
run_new "$w" -f -x "Dated Today" >/dev/null 2>&1
today=$(date +%Y-%m-%d)
assert_contains "$(cat "$w/blogs/dated-today/index.md")" "date: $today" \
  "the date defaults to today"

# --- refuses to clobber ----------------------------------------------------
w=$TMP/clobber
run_new "$w" -f -x -d 2026-03-01 "Existing Post" >/dev/null 2>&1
existing=$w/blogs/existing-post/index.md
printf 'HAND WRITTEN CONTENT\n' >>"$existing"
before=$(cat "$existing")

out=$(run_new "$w" -f -x -d 2026-03-01 "Existing Post" 2>&1)
rc=$?
assert_ne "0" "$rc" "a second run over an existing post fails"
assert_contains "$out" "already exists" "...and says why"
assert_eq "$before" "$(cat "$existing")" "...and leaves the existing file untouched"

# --- $EDITOR is not launched under -x --------------------------------------
# -x exists so the scaffold can be scripted; if it ever stopped being honoured
# the suite itself would hang waiting on an editor.
w=$TMP/noedit
mkdir -p "$w"
( cd "$w" && EDITOR=false "$NEW" -f -x -d 2026-05-01 "No Editor" ) >/dev/null 2>&1
assert_eq "0" "$?" "-x suppresses \$EDITOR (EDITOR=false would have failed the run)"
assert_file "$w/blogs/no-editor/index.md" "the post is still written"
