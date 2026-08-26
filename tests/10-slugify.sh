#!/usr/bin/env bash
# 10-slugify: bin/new's slug, which decides every /blogs/<slug>/ URL.
#
# bin/index used to carry a shell twin of this, for category page names; the
# tag family is gone and so is that copy, leaving bin/new's Python the single
# implementation. It is still worth a table: the slug is the post's permanent
# URL, and there is no second implementation left to disagree with it and give
# the mismatch away.
#
# The corpus is ASCII on purpose — a slug is a URL segment, and titles on this
# site are ASCII.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"

# new_slug TITLE -- the directory bin/new creates for TITLE, in a throwaway
# tree so the real blogs/ is never written to.
new_slug() {
  local work
  work=$TMP/new-$RANDOM
  mkdir -p "$work"
  ( cd "$work" && "$REPO_ROOT/bin/new" -f -x -d 2020-01-01 "$1" >/dev/null )
  ( cd "$work/blogs" && ls )
}

# --- table -----------------------------------------------------------------
assert_eq "machine-learning" "$(new_slug 'Machine Learning')" "two words"
assert_eq "shell"            "$(new_slug 'shell')"            "already a slug"
assert_eq "se4ai"            "$(new_slug 'SE4AI')"            "all caps with a digit"
assert_eq "c"                "$(new_slug 'C++')"              "trailing punctuation dropped"
assert_eq "spaced-out"       "$(new_slug '  spaced  out  ')"  "leading/trailing/repeated space"
assert_eq "a-b"              "$(new_slug 'a--b')"             "runs collapse to one hyphen"
assert_eq "2024-review"      "$(new_slug '2024 Review')"      "leading digits kept"
assert_eq "tech-debt-ml"     "$(new_slug 'Tech Debt / ML')"   "slash is a separator"
assert_eq "web"              "$(new_slug '.web.')"            "leading and trailing dots"
assert_eq "don-t-repeat-yourself" "$(new_slug "Don't Repeat Yourself!")" \
  "apostrophe separates, trailing bang is dropped"
assert_eq "effortless-parallel-execution-with-xargs" \
  "$(new_slug 'Effortless Parallel Execution with xargs')" "a real post title"

# Idempotence: re-slugifying a slug must be a no-op, or a title that already
# reads as a slug would land at a different URL than the same words spaced out.
for s in machine-learning shell se4ai 2024-review; do
  assert_eq "$s" "$(new_slug "$s")" "the slug for '$s' is itself"
done
