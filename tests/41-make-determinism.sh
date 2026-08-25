#!/usr/bin/env bash
# 41-make-determinism: the build is a pure function of the sources.
#
# Two properties, both claimed in CLAUDE.md:
#   - `make -j8` produces output identical to `make -j1`
#   - a no-op `make` is silent and instant
#
# The second is the one that catches a missing prerequisite in the other
# direction: a rule whose output is always considered stale rebuilds forever
# and makes every incremental build a full one.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
W=$TMP/repo
repo_copy "$W"

build() {
  local jobs=$1
  make_in "$W" -j"$jobs" >"$TMP/make.$jobs.log" 2>&1 || {
    _bad "$(_where 2)" "make -j$jobs failed" "$(_trunc "$(cat "$TMP/make.$jobs.log")" 600)"
    return 1
  }
}

# --- serial vs parallel ----------------------------------------------------
if build 1; then
  rm -rf "$TMP/site-j1"; cp -R "$W/_site" "$TMP/site-j1"
  make_in "$W" clean >/dev/null 2>&1
  if build 8; then
    assert_same_tree "$TMP/site-j1" "$W/_site" "make -j1 and make -j8 produce identical _site"
  fi
fi

# --- repeatability ---------------------------------------------------------
# Same recipes, same inputs, run again from scratch: the bytes must match.
# Anything time- or order-dependent leaking into the output shows up here.
make_in "$W" clean >/dev/null 2>&1
if build 4; then
  assert_same_tree "$TMP/site-j1" "$W/_site" "a clean rebuild reproduces the same _site"
fi

# --- the no-op build -------------------------------------------------------
# Everything is current, so make must print nothing at all. Output here means
# a rule is re-firing every time.
out=$(make_in "$W" 2>&1)
rc=$?
assert_eq "0" "$rc" "a no-op make exits 0"
assert_eq "" "$out" "a no-op make is silent"

# Twice more, to catch a rule that alternates rather than always firing.
for i in 1 2; do
  out=$(make_in "$W" 2>&1)
  assert_eq "" "$out" "no-op make is still silent (run $((i + 1)))"
done

# `make -q` cannot report 0 here, and that is a property of the design rather
# than a bug: category pages are only discoverable after bin/index has run, so
# `tags` is a .PHONY target and a phony prerequisite always counts as out of
# date. The cost is real though — see below.
make_in "$W" -q >/dev/null 2>&1
assert_ne "0" "$?" "make -q reports work to do, because tags is phony"

# What that phony target actually costs: every no-op build re-renders every
# category page. It is silent, so it looks free, but it is one pandoc call per
# category. Pinned here so the cost is visible and a fix would show up as a
# failing assertion rather than going unnoticed.
: >"$TMP/stamp"
make_in "$W" >/dev/null 2>&1
# index.html under tags/ is a real target, not part of the phony loop.
rerendered=$(find "$W/_site/blogs/tags" -name '*.html' ! -name index.html \
  -newer "$TMP/stamp" | wc -l | tr -d ' ')
n_cats=$(find "$W/_site/blogs/tags" -name '*.html' ! -name index.html | wc -l | tr -d ' ')
assert_eq "$n_cats" "$rerendered" "every category page is re-rendered on a no-op build ($n_cats of them)"

# Pages that are NOT behind the phony target stay untouched, which is the
# control showing the rest of the graph is wired correctly.
untouched=$(find "$W/_site" -maxdepth 1 -name '*.html' -newer "$TMP/stamp" | wc -l | tr -d ' ')
assert_eq "0" "$untouched" "top-level pages are not rebuilt by a no-op make"
assert_no_file_newer "$W/_site/blogs/tags/index.html" "$TMP/stamp" \
  "the tag index has a real rule and is not re-rendered"

# --- clean really cleans ---------------------------------------------------
make_in "$W" clean >/dev/null 2>&1
assert_no_file "$W/_site" "make clean removes _site"
assert_no_file "$W/build" "make clean removes build"

# Nothing generated escapes into the source tree. Compare the file list before
# and after a build rather than mtimes against some reference file, which only
# measures when the working copy was last edited.
before=$( cd "$W" && find . -path ./_site -prune -o -path ./build -prune -o \
  -type f -print | LC_ALL=C sort )
build 4 || true
after=$( cd "$W" && find . -path ./_site -prune -o -path ./build -prune -o \
  -type f -print | LC_ALL=C sort )
assert_eq "$before" "$after" "the build creates no files outside _site/ and build/"
