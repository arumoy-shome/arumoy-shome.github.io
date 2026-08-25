#!/usr/bin/env bash
# 11-rfc822: the BSD/GNU date split.
#
# rfc822() branches on `date -j` succeeding: a no-op on BSD, an error on GNU.
# A wrong branch yields an empty <pubDate> or one a feed reader rejects.
#
# Do NOT assume "macOS means BSD". A Homebrew coreutils install puts GNU date
# ahead of /bin on PATH, so a Mac can take the GNU branch too — which is the
# case on at least one machine this site is built on. Testing only "whichever
# flavour PATH happens to select" would then leave the BSD branch covered
# nowhere at all, since CI is Ubuntu. So: find every date(1) implementation on
# the box and run the table through each.

. "${TESTDIR:-$(dirname "$0")}/lib.sh"

cd "$REPO_ROOT"
INDEX_LIB=1 . bin/index

RFC822_RE='^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), [0-9]{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{4} 00:00:00 \+0000$'

# The expected output for each input, as two parallel lists (bash 3.2 has no
# associative arrays).
DATES="2022-02-28 2021-06-16 2023-11-29 2024-02-29 2000-01-01 1999-12-31 2025-07-01 2025-01-05"
EXPECT="Mon,_28_Feb_2022 Wed,_16_Jun_2021 Wed,_29_Nov_2023 Thu,_29_Feb_2024 Sat,_01_Jan_2000 Fri,_31_Dec_1999 Tue,_01_Jul_2025 Sun,_05_Jan_2025"

# check_table LABEL PATHVALUE -- run every known date through rfc822 with PATH
# set so a particular date(1) wins, and check the formatted result.
check_table() {
  local label=$1 pathval=$2
  local -a ds es
  read -ra ds <<<"$DATES"
  read -ra es <<<"$EXPECT"
  local i want got
  for i in "${!ds[@]}"; do
    want="${es[i]//_/ } 00:00:00 +0000"
    got=$(PATH=$pathval; rfc822 "${ds[i]}")
    assert_eq "$want" "$got" "[$label] ${ds[i]}"
  done
}

# --- locate the available date(1) implementations --------------------------
bsd_path=""
gnu_path=""
for d in /bin /usr/bin; do
  if [[ -x $d/date ]] && "$d/date" -j >/dev/null 2>&1; then bsd_path=$d; break; fi
done
# GNU date is whatever answers to -d; prefer PATH, fall back to gdate's dir.
if date -u -d 2000-01-01 >/dev/null 2>&1; then
  gnu_path=$(dirname "$(command -v date)")
elif command -v gdate >/dev/null 2>&1; then
  note "only gdate available; GNU branch checked via a shim"
  mkdir -p "$TMP/gnubin" && ln -sf "$(command -v gdate)" "$TMP/gnubin/date"
  gnu_path=$TMP/gnubin
fi

note "PATH date(1): $(command -v date)"
note "BSD date: ${bsd_path:-none found} · GNU date: ${gnu_path:-none found}"

if [[ -z $bsd_path && -z $gnu_path ]]; then
  fail "no usable date(1) implementation found"
fi

[[ -n $bsd_path ]] && check_table BSD "$bsd_path:$PATH"
[[ -n $gnu_path ]] && check_table GNU "$gnu_path:$PATH"

# Where both exist, the two branches must produce identical output. This is
# the only single-host check that the split itself is correct.
if [[ -n $bsd_path && -n $gnu_path ]]; then
  a=$(PATH=$bsd_path:$PATH; rfc822 2022-02-28)
  b=$(PATH=$gnu_path:$PATH; rfc822 2022-02-28)
  assert_eq "$a" "$b" "BSD and GNU branches agree"
else
  note "only one flavour present; cross-check needs the other platform (see CI)"
fi

# --- every real post date, as the build will actually format it ------------
n=0
for post in blogs/*/index.md; do
  meta=$(pandoc "$post" --template=templates/meta.txt -t plain)
  d=${meta%%|*}
  out=$(rfc822 "$d")
  assert_match "$out" "$RFC822_RE" "$(basename "$(dirname "$post")"): $d -> '$out'"
  n=$((n + 1))
done
note "formatted $n real post dates"
