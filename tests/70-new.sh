#!/usr/bin/env bash
# 70-new: bin/new scaffolds a post directory.
#
# It is the one piece of the toolchain written in Python, and it reimplements
# slugify independently of bin/index (that agreement is checked in
# 10-slugify). What matters here is that what it writes is something the rest
# of the build can actually consume: the frontmatter has to parse, and
# templates/meta.txt has to be able to read a date, categories and title back
# out.

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
run_new "$w" -f -x -c "shell, vim" -d 2026-01-30 "My Test Post" >"$TMP/out.txt" 2>&1
assert_eq "0" "$?" "bin/new exits cleanly"
post=$w/blogs/my-test-post/index.md
assert_file "$post" "the post is scaffolded at blogs/<slug>/index.md"
assert_contains "$(cat "$TMP/out.txt")" "created" "it reports what it made"

body=$(cat "$post")
assert_match "$body" '^---'                       "frontmatter opens"
assert_contains "$body" "title: My Test Post"     "the title is the one given"
assert_contains "$body" "date: 2026-01-30"        "the date is unquoted ISO"
assert_contains "$body" 'categories: ["shell", "vim"]' "categories are a quoted flow sequence"
assert_contains "$body" "abstract: |"             "the abstract is an empty block scalar"

# The date must be unquoted: bin/index reads it through templates/meta.txt and
# then hands it to date(1).
assert_not_contains "$body" 'date: "2026-01-30"'  "the date is not quoted"

# --- the build can read it back --------------------------------------------
# This is the real contract: whatever bin/new writes, bin/index must be able
# to parse with templates/meta.txt.
meta=$(pandoc "$post" --template=templates/meta.txt -t plain --wrap=none)
assert_eq "2026-01-30|shell,vim|My Test Post" "${meta%$'\n'}" \
  "meta.txt reads the date, categories and title back"

# And pandoc must accept the document at all.
assert_ok "the scaffolded post is valid pandoc input" -- \
  pandoc "$post" -t html --template=templates/feed-item.xml \
    --metadata slug=my-test-post --metadata site-url=https://example.org

# --- without categories ----------------------------------------------------
w=$TMP/nocats
run_new "$w" -f -x -d 2026-02-01 "No Categories Here" >/dev/null 2>&1
post=$w/blogs/no-categories-here/index.md
assert_file "$post" "a post with no categories is still created"
assert_not_contains "$(cat "$post")" "categories:" "the categories key is omitted entirely"
meta=$(pandoc "$post" --template=templates/meta.txt -t plain --wrap=none)
assert_eq "2026-02-01||No Categories Here" "${meta%$'\n'}" \
  "meta.txt yields an empty category list, and the title still lands in field 3"

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

# --- category whitespace ---------------------------------------------------
# "shell, vim" and "shell,vim" must produce the same thing; the separator is
# trimmed on both sides.
w=$TMP/spacing
run_new "$w" -f -x -d 2026-04-01 -c "  shell ,vim  , emacs " "Spacing" >/dev/null 2>&1
assert_contains "$(cat "$w/blogs/spacing/index.md")" 'categories: ["shell", "vim", "emacs"]' \
  "surrounding whitespace is trimmed from each category"

# An empty -c must not emit a categories line at all.
w=$TMP/emptycats
run_new "$w" -f -x -d 2026-04-02 -c "" "Empty Cats" >/dev/null 2>&1
assert_not_contains "$(cat "$w/blogs/empty-cats/index.md")" "categories:" \
  "an empty -c is the same as no -c"

w=$TMP/commasonly
run_new "$w" -f -x -d 2026-04-03 -c " , , " "Commas Only" >/dev/null 2>&1
assert_not_contains "$(cat "$w/blogs/commas-only/index.md")" "categories:" \
  "a -c of only separators yields no categories"

# --- $EDITOR is not launched under -x --------------------------------------
# -x exists so the scaffold can be scripted; if it ever stopped being honoured
# the suite itself would hang waiting on an editor.
w=$TMP/noedit
mkdir -p "$w"
( cd "$w" && EDITOR=false "$NEW" -f -x -d 2026-05-01 "No Editor" ) >/dev/null 2>&1
assert_eq "0" "$?" "-x suppresses \$EDITOR (EDITOR=false would have failed the run)"
assert_file "$w/blogs/no-editor/index.md" "the post is still written"
