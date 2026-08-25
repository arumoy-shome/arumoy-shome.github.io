#!/usr/bin/env bash
# 10-slugify: bin/index's slugify(), which decides every /blogs/tags/<x>.html URL.
#
# Sourcing bin/index brings its `set -euo pipefail` along; the assertion
# helpers never return non-zero, so the file still runs to completion.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
INDEX_LIB=1 . bin/index

# --- table -----------------------------------------------------------------
assert_eq "machine-learning" "$(slugify 'Machine Learning')" "two words"
assert_eq "shell"            "$(slugify 'shell')"            "already a slug"
assert_eq "se4ai"            "$(slugify 'SE4AI')"            "all caps with a digit"
assert_eq "technical-debt"   "$(slugify 'Technical Debt')"   "real category"
assert_eq "c"                "$(slugify 'C++')"              "trailing punctuation dropped"
assert_eq "spaced-out"       "$(slugify '  spaced  out  ')"  "leading/trailing/repeated space"
assert_eq "a-b"              "$(slugify 'a--b')"             "runs collapse to one hyphen"
assert_eq "2024-review"      "$(slugify '2024 Review')"      "leading digits kept"
assert_eq "tech-debt-ml"     "$(slugify 'Tech Debt / ML')"   "slash is a separator"
assert_eq "web"              "$(slugify '.web.')"            "leading and trailing dots"
assert_eq ""                 "$(slugify '---')"              "no alphanumerics at all"

# Idempotence: slugifying a slug must be a no-op, or tag URLs would drift
# every time a category were round-tripped.
for s in machine-learning shell se4ai 2024-review; do
  assert_eq "$s" "$(slugify "$s")" "slugify is idempotent for '$s'"
done

# --- every category actually in use ---------------------------------------
# A category that slugifies to "" or to something outside [a-z0-9-] would
# produce a broken or unreachable tag page.
seen=""
for post in blogs/*/index.md; do
  meta=$(pandoc "$post" --template=templates/meta.txt -t plain)
  cats=${meta#*|}
  cats=${cats%$'\n'}
  [[ -n $cats ]] || continue
  IFS=',' read -ra arr <<<"$cats"
  for c in "${arr[@]}"; do
    c="${c#"${c%%[![:space:]]*}"}"; c="${c%"${c##*[![:space:]]}"}"
    [[ -n $c ]] || continue
    case " $seen " in *" $c "*) continue ;; esac
    seen="$seen $c"
    s=$(slugify "$c")
    assert_match "$s" '^[a-z0-9]+(-[a-z0-9]+)*$' "category '$c' slugifies to a clean URL segment (got '$s')"
  done
done
note "checked $(printf '%s' "$seen" | wc -w | tr -d ' ') distinct categories in use"

# --- agreement with bin/new ------------------------------------------------
# bin/new reimplements this in Python (bin/new:29). If the two ever diverge,
# `bin/new "Some Title"` scaffolds a directory whose name does not match the
# slug bin/index will generate links for. ASCII-only corpus: the two
# implementations differ on how they segment multibyte characters, and no
# category in use is non-ASCII.
for title in \
  "Machine Learning" \
  "SE4AI" \
  "Tech Debt / ML" \
  "  spaced  out  " \
  "a--b" \
  "2024 Review" \
  "Effortless Parallel Execution with xargs" \
  "Don't Repeat Yourself!"
do
  work=$TMP/new-$RANDOM
  mkdir -p "$work"
  ( cd "$work" && "$REPO_ROOT/bin/new" -f -x -d 2020-01-01 "$title" >/dev/null )
  actual=$(cd "$work/blogs" && ls)
  assert_eq "$(slugify "$title")" "$actual" "bin/new agrees with slugify for '$title'"
done
