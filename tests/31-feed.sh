#!/usr/bin/env bash
# 31-feed: blogs.xml and sitemap.xml, on the fixture and on the real site.
#
# The feed carries full post bodies inside CDATA, which creates two hazards
# bin/index handles by hand: image paths relative to the post directory (a
# feed reader has no way to resolve them) and a literal ]]> in the body
# (which would terminate the CDATA section early and break the whole feed,
# not just the one item).

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$(fixture_site) || exit 1
B=$SITE/build
FEED=$B/blogs.xml
gamma=$(cat "$B/item/gamma.xml")

have_xmllint=""
command -v xmllint >/dev/null 2>&1 && have_xmllint=1

# --- well-formedness -------------------------------------------------------
if [[ -n $have_xmllint ]]; then
  assert_ok "fixture feed is well-formed XML"    -- xmllint --noout "$FEED"
  assert_ok "fixture sitemap is well-formed XML" -- xmllint --noout "$B/sitemap.xml"
  assert_ok "real feed is well-formed XML"       -- xmllint --noout "$REPO_ROOT/_site/blogs.xml"
  assert_ok "real sitemap is well-formed XML"    -- xmllint --noout "$REPO_ROOT/_site/sitemap.xml"
else
  note "xmllint not installed; well-formedness unchecked"
fi

# --- the CDATA guard -------------------------------------------------------
# pandoc escapes > in ordinary text, so a bare ]]> only survives where it
# passes HTML through raw: an HTML comment, a <script>, a ```{=html} block.
# The fixture uses the first two of those.
assert_contains "$gamma" "]]&gt;" "a raw ]]> in the body is escaped"
assert_eq "2" "$(printf '%s' "$gamma" | grep -c ']]&gt;')" \
  "both raw occurrences are escaped (comment and raw block)"

# The item's own terminator must survive, exactly once. Escaping it too would
# make the feed unparseable; not escaping the body would truncate the item.
assert_eq "1" "$(printf '%s' "$gamma" | grep -c ']]></description>')" \
  "the real CDATA terminator survives, exactly once"
assert_contains "$gamma" "<description><![CDATA[" "CDATA section opens"

# No unescaped ]]> anywhere except the terminator.
stray=$(printf '%s' "$gamma" | sed 's#]]></description>##' | grep -c ']]>' || true)
assert_eq "0" "$stray" "no unescaped ]]> remains in the body"

# --- relative URL rewriting ------------------------------------------------
assert_contains "$gamma" 'src="https://fixture.example/blogs/gamma/pic.png"' \
  "a relative image src becomes absolute"
assert_not_contains "$gamma" 'src="pic.png"' "no relative src survives"

# Anything already resolvable is left exactly as it was.
assert_contains "$gamma" 'href="https://example.org/somewhere"' "absolute URL untouched"
assert_contains "$gamma" 'href="/blogs.html"' "root-relative URL untouched"
assert_contains "$gamma" 'href="#a-heading"' "anchor untouched"
assert_not_contains "$gamma" "fixture.example/blogs/gamma/https:" "no double-prefixing"
assert_not_contains "$gamma" "fixture.example/blogs/gamma/#" "anchors are not prefixed"

# --- channel and items -----------------------------------------------------
feed=$(cat "$FEED")
assert_match "$feed" '^<\?xml version="1\.0" encoding="UTF-8"\?>' "XML declaration first"
assert_contains "$feed" '<rss version="2.0"' "RSS 2.0"
assert_contains "$feed" "<title>Fixture Site</title>" "channel title from site.yaml"
assert_contains "$feed" "<link>https://fixture.example/blogs.html</link>" "channel link"
assert_contains "$feed" "<description>A synthetic site used by the test suite</description>" \
  "channel description from site.yaml"
assert_contains "$feed" '<atom:link href="https://fixture.example/blogs.xml"' "self link"
assert_eq "3" "$(grep -c '<item>' "$FEED")" "one item per post"

# Items in the same order as the index: newest first.
order=$(grep '<link>https://fixture.example/blogs/' "$FEED" | sed 's#.*/blogs/\([^/]*\)/.*#\1#')
assert_eq "alpha
beta
gamma" "$order" "feed items are newest-first"

# Every pubDate is RFC 822, which is what makes a reader show the right date.
RFC822_RE='<pubDate>(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} [A-Z][a-z]{2} [0-9]{4} 00:00:00 \+0000</pubDate>'
assert_eq "3" "$(grep -Ec "$RFC822_RE" "$FEED")" "every pubDate is RFC 822"

# Categories come through as elements, using the display name.
assert_contains "$feed" "<category>Machine Learning</category>" "category keeps its display name"

# --- sitemap ---------------------------------------------------------------
sm=$B/sitemap.xml
for p in "" blogs.html talks.html publications.html resume.html license.html blogs/tags/; do
  assert_contains "$(cat "$sm")" "<loc>https://fixture.example/$p</loc>" "sitemap lists /$p"
done
for slug in alpha beta gamma; do
  assert_contains "$(cat "$sm")" "<loc>https://fixture.example/blogs/$slug/</loc>" "sitemap lists $slug"
done
for cat in machine-learning productivity shell; do
  assert_contains "$(cat "$sm")" "<loc>https://fixture.example/blogs/tags/$cat.html</loc>" \
    "sitemap lists tag $cat"
done
assert_eq "3" "$(grep -c '<lastmod>' "$sm")" "each post carries a lastmod"
assert_contains "$(cat "$sm")" "<lastmod>2025-03-01</lastmod>" "lastmod is the post date"
assert_eq "13" "$(grep -c '<url>' "$sm")" "6 flat pages + the tag index + 3 posts + 3 tag pages"

# --- the real feed ---------------------------------------------------------
real=$REPO_ROOT/_site/blogs.xml
n_posts=$(find "$REPO_ROOT/blogs" -name index.md -maxdepth 2 | wc -l | tr -d ' ')
assert_eq "$n_posts" "$(grep -c '<item>' "$real")" "real feed has one item per post"
assert_contains "$(cat "$real")" "<link>https://arumoy.me/blogs.html</link>" "real channel link"
assert_eq "$n_posts" "$(grep -Ec '<pubDate>[A-Z][a-z]{2}, [0-9]{2} ' "$real")" \
  "every real pubDate is formatted"

# No relative src survived into the real feed either.
assert_eq "0" "$(grep -Eoc 'src="[^"#/][^":]*"' "$real" || true)" \
  "no unrewritten relative src in the real feed"

# Every sitemap <loc> must correspond to something that was actually built.
missing=""
while read -r loc; do
  rel=${loc#https://arumoy.me/}
  case $rel in
    "") path=index.html ;;
    */) path=$rel"index.html" ;;
    *)  path=$rel ;;
  esac
  [[ -f $REPO_ROOT/_site/$path ]] || missing="$missing $rel"
done < <(sed -n 's#.*<loc>\(.*\)</loc>.*#\1#p' "$REPO_ROOT/_site/sitemap.xml")
assert_eq "" "$missing" "every sitemap URL maps to a built file"
