#!/usr/bin/env bash
# 40-jobs-identity: the parallelism invariant.
#
# bin/index re-invokes itself once per post under `xargs -P`, so each post's
# three pandoc calls run concurrently. Safety rests on one unenforced rule: a
# worker writes only files named after its own slug. Ordering and category
# data go to build/order/<slug> and build/cats/<slug> rather than being
# appended to a shared file, because concurrent appends would interleave and
# silently corrupt the index, the feed and every tag page at once.
#
# CLAUDE.md names this the first thing to check when JOBS=1 and JOBS=N ever
# diverge. Races are intermittent, so each comparison runs several times.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"

# --- fixture corpus --------------------------------------------------------
fixture_build "$TMP/j1" 1 || exit 1
for jobs in 2 4 8; do
  fixture_build "$TMP/j$jobs" "$jobs" || continue
  assert_same_tree "$TMP/j1/build" "$TMP/j$jobs/build" \
    "fixture: JOBS=1 and JOBS=$jobs produce identical build/"
done

# --- the real corpus -------------------------------------------------------
# Eighteen posts rather than three, so there is enough concurrency for an
# interleaving bug to actually show up.
repo_copy "$TMP/repo"
run_index() {
  local jobs=$1 out=$2
  ( cd "$TMP/repo" && rm -rf build && JOBS=$jobs bin/index ) >"$TMP/index.log" 2>&1 || {
    _bad "$(_where 2)" "bin/index failed with JOBS=$jobs" "$(_trunc "$(cat "$TMP/index.log")" 400)"
    return 1
  }
  rm -rf "$out"; cp -R "$TMP/repo/build" "$out"
}

if run_index 1 "$TMP/real-j1"; then
  n=$(find "$TMP/real-j1/frag" -type f | wc -l | tr -d ' ')
  note "real corpus: $n posts"
  for attempt in 1 2 3; do
    if run_index 8 "$TMP/real-j8-$attempt"; then
      assert_same_tree "$TMP/real-j1" "$TMP/real-j8-$attempt" \
        "real corpus: JOBS=1 and JOBS=8 identical (attempt $attempt/3)"
    fi
  done
fi

# --- the shape the invariant depends on ------------------------------------
# If per-post work ever starts writing to a shared path, the diffs above go
# intermittent rather than red. Assert the file layout directly: everything a
# worker writes is named after its slug.
for d in frag item meta order cats; do
  assert_dir "$TMP/real-j1/$d" "build/$d exists"
done
slugs=$(cd "$TMP/repo/blogs" && ls -d */ | sed 's#/##' | sort)
for d in order cats; do
  got=$(cd "$TMP/real-j1/$d" && ls | sort)
  assert_eq "$slugs" "$got" "build/$d holds exactly one slug-named file per post"
done

# -n1 is load-bearing: without it BSD xargs packs every path into a single
# command and -P does nothing. A regression there would not change the output,
# only the speed, so check the flag is still present.
assert_match "$(cat bin/index)" 'xargs -0 -n1 -P' "xargs keeps -n1 alongside -P"
