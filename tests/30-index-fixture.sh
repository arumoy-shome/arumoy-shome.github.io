#!/usr/bin/env bash
# 30-index-fixture: bin/index against tests/fixtures/site, a three-post corpus
# built to trip the pandoc traps documented in CLAUDE.md. Each is a silent
# corruption: the build still succeeds, the output is just wrong.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$(fixture_site) || exit 1
B=$SITE/build

ALPHA_TITLE="Reproducible Machine Learning Pipelines Without a Framework, a Deliberately Long Title"

# raw_yaml FILE KEY -- the value as bin/index literally wrote it, before any
# YAML parse. Needed to see escaping that a parser would resolve away.
raw_yaml() { sed -n "s/^$2: \"\(.*\)\"$/\1/p" "$1"; }

# --- inventory -------------------------------------------------------------
for slug in alpha beta gamma; do
  assert_file "$B/frag/$slug.md"    "frag for $slug"
  assert_file "$B/item/$slug.xml"   "feed item for $slug"
  assert_file "$B/meta/$slug.yaml"  "meta for $slug"
  assert_file "$B/order/$slug"      "order entry for $slug"
  assert_file "$B/title/$slug"      "title entry for $slug"
done
for f in blogs.md blogs.xml sitemap.xml order.txt; do
  assert_file "$B/$f" "driver output $f"
done
assert_eq "3" "$(find "$B/frag" -type f | wc -l | tr -d ' ')" "one fragment per post, no more"

# --- ordering --------------------------------------------------------------
assert_eq "2025-03-01|alpha
2024-07-15|beta
2023-01-20|gamma" "$(cat "$B/order.txt")" "order.txt is newest-first"

headings=$(grep '^## ' "$B/blogs.md" | sed 's#.*(/blogs/\([^/]*\)/)#\1#')
assert_eq "alpha
beta
gamma" "$headings" "blogs.md lists posts newest-first"

# --- the intro is the prefix ----------------------------------------------
assert_contains "$(cat "$B/blogs.md")" "FIXTURE_INTRO_MARKER" "intro prose is included"
first_heading_line=$(grep -n '^## ' "$B/blogs.md" | head -1 | cut -d: -f1)
marker_line=$(grep -n 'FIXTURE_INTRO_MARKER' "$B/blogs.md" | head -1 | cut -d: -f1)
assert_ok "intro precedes the first entry" -- test "$marker_line" -lt "$first_heading_line"

# --- --wrap=none on the markdown pass --------------------------------------
# Without it the markdown writer reflows at 72 columns, splitting
# `## [Title](url)` across two lines and destroying both the heading and the
# link. The fixture title is long enough to trigger that.
first_line=$(head -1 "$B/frag/alpha.md")
assert_eq "## [$ALPHA_TITLE](/blogs/alpha/)" "$first_line" "heading and link survive on one line"
assert_ok "the heading line is long enough to have wrapped (>72 cols)" -- \
  test "${#first_line}" -gt 72
assert_eq "1" "$(grep -c '^## ' "$B/frag/alpha.md")" "exactly one heading in the fragment"

# --- the plain-text description -------------------------------------------
# Feeding `abstract` straight to <meta name="description"> would put
# block-level HTML in an attribute; bin/index renders it to one plain line.
desc=$(raw_yaml "$B/meta/beta.yaml" description)
# raw_yaml only matches a value that opens and closes on one line, so a
# non-empty result is itself the single-line assertion. The shape of the file
# backs it up: every line is one key with a quoted scalar that closes on it.
assert_ne "" "$desc" "description is a single-line quoted scalar"
assert_eq "" "$(grep -vE '^[a-z-]+: ".*"$' "$B/meta/beta.yaml")" \
  "meta yaml is one line per quoted key"
assert_not_contains "$desc" "**"   "markdown emphasis is stripped"
assert_not_contains "$desc" "](" "markdown link syntax is stripped"
assert_contains "$desc" "bold text" "the words survive"
assert_contains "$desc" "link, all of which" "link text survives without its target"

# Quote and backslash must be escaped, or the YAML scalar is malformed. Both
# come from a code span: smart punctuation curls a quote written in prose.
assert_contains "$desc" '\"' "double quotes are backslash-escaped"
assert_contains "$desc" '\\n' "backslashes are doubled"

# The real proof: pandoc parses it back.
printf '$description$' >"$TMP/d.tpl"
assert_ok "meta yaml with escaped quotes parses" -- \
  pandoc /dev/null -f markdown -t plain --wrap=none \
    --template="$TMP/d.tpl" --metadata-file="$B/meta/beta.yaml"

for slug in alpha beta gamma; do
  assert_ok "meta/$slug.yaml is valid --metadata-file input" -- \
    pandoc /dev/null -f markdown -t plain --template="$TMP/d.tpl" \
      --metadata-file="$B/meta/$slug.yaml"
done

# --- posts carry `abstract`, not `description` -----------------------------
# templates/listing.md reads `abstract` directly, inherited from Quarto's
# listing fallback. Renaming it would empty every index entry.
for slug in alpha beta gamma; do
  assert_eq "0" "$(grep -c '^description:' "$SITE/blogs/$slug/index.md")" \
    "$slug frontmatter has no description: field"
done
assert_contains "$(cat "$B/frag/alpha.md")" "An abstract containing" "alpha's abstract reaches the listing"
assert_contains "$(cat "$B/frag/beta.md")"  "An abstract that spans"  "beta's abstract reaches the listing"
assert_contains "$(cat "$B/frag/gamma.md")" "Exercises the feed"      "gamma's abstract reaches the listing"

# The listing must carry the abstract as MARKDOWN, not the flattened
# description. Both start with the same words, so checking the prose alone
# cannot tell them apart: swapping $abstract$ for $description$ in
# templates/listing.md would still produce plausible-looking output. The
# markup is what distinguishes them.
frag_alpha=$(cat "$B/frag/alpha.md")
assert_contains "$frag_alpha" "[a markdown link](https://example.org/alpha)" \
  "the listing keeps the abstract's markdown link"
assert_contains "$frag_alpha" "*emphasis*" "the listing keeps the abstract's emphasis"
assert_contains "$(cat "$B/frag/beta.md")" "[link](https://example.org/beta)" \
  "beta's listing keeps its markdown link too"

# The description is the flattened form, and must NOT be what the listing shows.
assert_not_contains "$(raw_yaml "$B/meta/alpha.yaml" description)" "](" \
  "the description is flattened, confirming the two differ"

# --- prev/next navigation --------------------------------------------------
# Neighbours cannot be known inside render_post, which runs before order.txt
# exists; the driver appends these keys once every worker has finished. The
# fixture is ordered alpha (newest), beta, gamma (oldest), so it covers all
# three cases: no newer, both, no older.
assert_eq "/blogs/beta/"  "$(raw_yaml "$B/meta/alpha.yaml" older-url)" "alpha's older neighbour is beta"
assert_eq ""              "$(raw_yaml "$B/meta/alpha.yaml" newer-url)" "the newest post has no newer neighbour"
assert_eq "/blogs/beta/"  "$(raw_yaml "$B/meta/gamma.yaml" newer-url)" "gamma's newer neighbour is beta"
assert_eq ""              "$(raw_yaml "$B/meta/gamma.yaml" older-url)" "the oldest post has no older neighbour"
assert_eq "/blogs/gamma/" "$(raw_yaml "$B/meta/beta.yaml" older-url)"  "beta's older neighbour is gamma"
assert_eq "/blogs/alpha/" "$(raw_yaml "$B/meta/beta.yaml" newer-url)"  "beta's newer neighbour is alpha"

# The flag that wraps the <nav>: pandoc templates have no $if(a or b)$, so a
# post with any neighbour at all needs one key to key the block off.
for slug in alpha beta gamma; do
  assert_eq "true" "$(raw_yaml "$B/meta/$slug.yaml" postnav)" "$slug carries the postnav flag"
done

# Neighbour titles, and the escaping they need. gamma's title carries a code
# span holding a literal double quote and a backslash, so beta -- the only
# post that names gamma -- is the regression test: an unescaped quote closes
# the scalar early and the whole meta file stops parsing.
assert_eq "$ALPHA_TITLE" "$(raw_yaml "$B/meta/beta.yaml" newer-title)" "beta names alpha's full title"
gamma_title=$(raw_yaml "$B/meta/beta.yaml" older-title)
assert_contains "$gamma_title" '\"' "a quote in a neighbour title is backslash-escaped"
assert_contains "$gamma_title" '\\n' "a backslash in a neighbour title is doubled"
assert_contains "$gamma_title" "Content" "the rest of the title survives the escaping"

# --wrap=none on the frontmatter pass. The plain writer reflows at 72 columns,
# and the title is the last field, so a wrap would truncate it mid-sentence.
assert_eq "$ALPHA_TITLE" "$(cat "$B/title/alpha")" "the long title survives the frontmatter pass unwrapped"
assert_ok "the title is long enough to have wrapped (>72 cols)" -- \
  test "${#ALPHA_TITLE}" -gt 72

# --- pubdate ---------------------------------------------------------------
assert_eq "Sat, 01 Mar 2025 00:00:00 +0000" "$(raw_yaml "$B/meta/alpha.yaml" pubdate)" "alpha pubdate"
assert_eq "https://fixture.example" "$(raw_yaml "$B/meta/alpha.yaml" site-url)" "site-url comes from site.yaml"
assert_eq "alpha" "$(raw_yaml "$B/meta/alpha.yaml" slug)" "slug is the directory name"
