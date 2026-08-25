#!/usr/bin/env bash
# 51-links: every internal link and asset reference resolves to a file that
# was actually built.
#
# Nothing in the build validates link targets. A renamed post directory, a
# page dropped from the Makefile, or an image that never got copied all
# produce a clean build and a 404. Relative cross-post links (../slug) are the
# most fragile kind, since they encode a directory name in prose.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
SITE=$REPO_ROOT/_site

assert_dir "$SITE" "the site is built" || exit 1

# resolve PAGE HREF -> the file the browser would fetch, or "" to skip.
# PAGE is relative to _site.
resolve() {
  local page=$1 href=$2 dir target
  href=${href%%#*}                       # drop the fragment
  [[ -z $href ]] && return 0             # same-page anchor
  case $href in
    http://*|https://*|mailto:*|tel:*|data:*|//*) return 0 ;;
  esac
  if [[ $href == /* ]]; then
    target=$SITE$href
  else
    dir=$(dirname "$page")
    target=$SITE/$dir/$href
  fi
  # A trailing slash, or an extensionless path that is a directory, means the
  # server serves index.html from it.
  if [[ $href == */ ]]; then
    target=$target"index.html"
  elif [[ -d $target ]]; then
    target=$target/index.html
  fi
  printf '%s' "$target"
}

# --- links in built pages --------------------------------------------------
broken=""
n_checked=0
while IFS= read -r f; do
  page=${f#"$SITE"/}
  # One href/src per line, attribute value only.
  while IFS= read -r href; do
    [[ -n $href ]] || continue
    target=$(resolve "$page" "$href")
    [[ -n $target ]] || continue
    n_checked=$((n_checked + 1))
    if [[ ! -e $target ]]; then
      broken="$broken
  $page -> $href"
    fi
  done < <(grep -oE '(href|src)="[^"]*"' "$f" | sed -E 's/^(href|src)="//; s/"$//')
done < <(site_html "$SITE")

assert_eq "" "$broken" "every internal link resolves to a built file"
note "checked $n_checked internal references across $(site_html "$SITE" | wc -l | tr -d ' ') pages"

# --- fragments -------------------------------------------------------------
# A cross-page #anchor that names no id is a softer failure, but it is still a
# link that does not go where it says.
bad_anchor=""
while IFS= read -r f; do
  page=${f#"$SITE"/}
  while IFS= read -r href; do
    case $href in *#*) ;; *) continue ;; esac
    frag=${href#*#}
    [[ -n $frag ]] || continue
    case $href in http*|mailto:*) continue ;; esac
    base=${href%%#*}
    if [[ -z $base ]]; then target=$f; else target=$(resolve "$page" "$base"); fi
    [[ -n $target && -f $target ]] || continue
    grep -q "id=\"$frag\"\|name=\"$frag\"" "$target" || bad_anchor="$bad_anchor
  $page -> $href"
  done < <(grep -oE 'href="[^"]*#[^"]*"' "$f" | sed -E 's/^href="//; s/"$//')
done < <(site_html "$SITE")
assert_eq "" "$bad_anchor" "every #fragment names an element that exists"

# --- post assets -----------------------------------------------------------
# Images live beside their post and are copied by the ASSET_OUT rule. A file
# added to blogs/ but not picked up by the wildcard would 404.
missing_asset=""
while IFS= read -r a; do
  [[ -f $SITE/$a ]] || missing_asset="$missing_asset $a"
done < <(find blogs -type f ! -name '*.md' | sort)
assert_eq "" "$missing_asset" "every post asset is copied into _site"

n_assets=$(find blogs -type f ! -name '*.md' | wc -l | tr -d ' ')
note "checked $n_assets post assets"

# --- the reverse direction -------------------------------------------------
# Every page in the nav must exist, or the whole site has a dead link on every
# page rather than just one.
while IFS= read -r href; do
  target=$(resolve "index.html" "$href")
  [[ -n $target ]] || continue
  assert_file "$target" "nav link $href resolves"
done < <(sed -n 's/^ *href: "\(.*\)"/\1/p' site.yaml)

# Nothing in _site should link to a path under /blogs/ that is not a real post
# directory, which is what a renamed post leaves behind.
posts=$(cd blogs && ls -d */ | sed 's#/##' | sort)
bad_post_link=""
while IFS= read -r slug; do
  [[ -n $slug ]] || continue
  case "
$posts" in
    *"
$slug"*) ;;
    *) bad_post_link="$bad_post_link $slug" ;;
  esac
done < <(grep -rhoE 'href="(\.\./|/blogs/)[a-z0-9-]+/?"' "$SITE" --include='*.html' \
  | sed -E 's#href="(\.\./|/blogs/)##; s#/?"$##' | grep -vx tags | sort -u)
assert_eq "" "$bad_post_link" "no link points at a post directory that does not exist"
