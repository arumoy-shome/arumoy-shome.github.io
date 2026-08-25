#!/usr/bin/env bash
# 32-tags: the /blogs/tags/<category>.html family — the one URL family added
# after the Quarto migration. Category pages are discovered only once
# bin/index has run, so the Makefile builds them with a recursive rule; that
# makes "a page exists for every category, and lists exactly the right posts"
# worth asserting directly.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
INDEX_LIB=1 . bin/index   # for slugify()
SITE=$(fixture_site) || exit 1
B=$SITE/build

# In the fixture: alpha has "Machine Learning" + "shell", beta has
# "productivity", gamma has "shell".

# --- one page per category -------------------------------------------------
assert_eq "machine-learning
productivity
shell" "$(cd "$B/tags" && ls *.md | sed 's/\.md$//' | sort)" "a page per distinct category"

assert_eq "3" "$(cut -d'|' -f1 "$B/tagmap.txt" | sort -u | wc -l | tr -d ' ')" \
  "tagmap agrees on the category count"

# The filename is the slug of the display name.
while IFS='|' read -r cslug cname _; do
  assert_eq "$(slugify "$cname")" "$cslug" "tagmap slug for '$cname'"
  assert_file "$B/tags/$cslug.md" "page exists for category '$cname'"
done <"$B/tagmap.txt"

# --- membership ------------------------------------------------------------
# Each page lists exactly its own posts, and nothing else. The delimiter is
# % rather than # because the pattern itself starts with "## ".
entries() { sed -n 's%^## \[.*\](/blogs/\([^/]*\)/)$%\1%p' "$1"; }

assert_eq "alpha"        "$(entries "$B/tags/machine-learning.md")" "Machine Learning: alpha only"
assert_eq "beta"         "$(entries "$B/tags/productivity.md")"     "productivity: beta only"
assert_eq "alpha
gamma"  "$(entries "$B/tags/shell.md")"  "shell: alpha and gamma, in newest-first order"

# A post must not leak onto a page it does not belong to.
assert_not_contains "$(cat "$B/tags/productivity.md")" "/blogs/alpha/" "alpha is not in productivity"
assert_not_contains "$(cat "$B/tags/machine-learning.md")" "/blogs/gamma/" "gamma is not in Machine Learning"

# --- page furniture --------------------------------------------------------
for cslug in machine-learning productivity shell; do
  page=$(cat "$B/tags/$cslug.md")
  assert_match "$page" '^---' "$cslug.md opens with frontmatter"
  assert_contains "$page" 'title: "Posts tagged ' "$cslug.md has a title"
  assert_contains "$page" "[All posts](/blogs.html)" "$cslug.md links back to the index"
done

# The title uses the display name, not the slug.
assert_contains "$(cat "$B/tags/machine-learning.md")" 'title: "Posts tagged Machine Learning"' \
  "title carries the display name"

# Fragments are shared with the index, so an entry looks identical in both.
assert_contains "$(cat "$B/tags/shell.md")" "$(head -1 "$B/frag/alpha.md")" \
  "tag entries reuse the listing fragment"

# --- the real site ---------------------------------------------------------
# Every category in use has a built HTML page, and every built page is
# reachable from the posts that reference it.
real_tags=$(cd "$REPO_ROOT/_site/blogs/tags" && ls *.html | sed 's/\.html$//' | sort)
n=0
for post in blogs/*/index.md; do
  meta=$(pandoc "$post" --template=templates/meta.txt -t plain)
  cats=${meta#*|}; cats=${cats%$'\n'}
  [[ -n $cats ]] || continue
  IFS=',' read -ra arr <<<"$cats"
  for c in "${arr[@]}"; do
    c="${c#"${c%%[![:space:]]*}"}"; c="${c%"${c##*[![:space:]]}"}"
    [[ -n $c ]] || continue
    s=$(slugify "$c")
    assert_file "$REPO_ROOT/_site/blogs/tags/$s.html" "tag page built for '$c'"
    n=$((n + 1))
  done
done
note "checked $n category references across the real posts"

# No orphan tag pages: every built page corresponds to a category in use.
in_use=$(for post in blogs/*/index.md; do
  meta=$(pandoc "$post" --template=templates/meta.txt -t plain)
  cats=${meta#*|}; cats=${cats%$'\n'}
  IFS=',' read -ra arr <<<"$cats"
  for c in "${arr[@]}"; do
    c="${c#"${c%%[![:space:]]*}"}"; c="${c%"${c##*[![:space:]]}"}"
    # slugify prints without a trailing newline, hence the explicit printf.
    [[ -n $c ]] && printf '%s\n' "$(slugify "$c")"
  done
done | sort -u)
assert_eq "$in_use" "$real_tags" "built tag pages match the categories in use"
