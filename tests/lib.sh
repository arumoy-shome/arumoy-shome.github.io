# lib.sh: assertion helpers, sourced by every tests/[0-9]*.sh.
#
# Every helper returns 0 and records failures in a counter rather than
# returning non-zero. Test files that source bin/index inherit its
# `set -euo pipefail`, and a helper returning 1 would abort the file at the
# first failure instead of reporting all of them.
#
# The driver sets COUNT_FILE, TMP, REPO_ROOT and TESTDIR. Running a test file
# directly works too; the fallbacks below cover that.

: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${TESTDIR:=$REPO_ROOT/tests}"
: "${COUNT_FILE:=}"
_lib_tmp_owned=""
if [[ -z ${TMP:-} ]]; then
  TMP=$(mktemp -d)
  _lib_tmp_owned=1  # cleaned up by _report; the driver owns TMP otherwise
fi
export REPO_ROOT TESTDIR TMP

_pass=0
_fail=0
_skip=0
_skip_reason=""

# Where the failing assertion was written. BASH_LINENO[0] is the line in the
# caller of the helper; walk out one more frame when a helper calls a helper.
_where() {
  local depth=${1:-1}
  printf '%s:%s' "$(basename "${BASH_SOURCE[depth + 1]}")" "${BASH_LINENO[depth]}"
}

_ok() { _pass=$((_pass + 1)); return 0; }

# _bad WHERE MSG [DETAIL...]
_bad() {
  local where=$1 msg=$2
  shift 2
  _fail=$((_fail + 1))
  printf '    FAIL %s: %s\n' "$where" "$msg" >&2
  local line
  for line in "$@"; do printf '         %s\n' "$line" >&2; done
  return 0
}

# Truncate long values so a failing diff of a whole HTML file stays readable.
_trunc() {
  local s=$1 n=${2:-200}
  if (( ${#s} > n )); then printf '%s… (%d chars)' "${s:0:n}" "${#s}"; else printf '%s' "$s"; fi
}

note() { printf '         %s\n' "$*" >&2; }

skip() {
  _skip=1
  _skip_reason=$*
  return 0
}

fail() { _bad "$(_where)" "$*"; }

assert_eq() {
  local expected=$1 actual=$2 msg=${3:-values differ}
  if [[ $expected == "$actual" ]]; then _ok; else
    _bad "$(_where)" "$msg" \
      "expected: $(_trunc "$expected")" \
      "actual:   $(_trunc "$actual")"
  fi
}

assert_ne() {
  local a=$1 b=$2 msg=${3:-values should differ}
  if [[ $a != "$b" ]]; then _ok; else
    _bad "$(_where)" "$msg" "both were: $(_trunc "$a")"
  fi
}

assert_contains() {
  local haystack=$1 needle=$2 msg=${3:-substring not found}
  if [[ $haystack == *"$needle"* ]]; then _ok; else
    _bad "$(_where)" "$msg" \
      "looking for: $(_trunc "$needle")" \
      "in:          $(_trunc "$haystack")"
  fi
}

assert_not_contains() {
  local haystack=$1 needle=$2 msg=${3:-substring should be absent}
  if [[ $haystack != *"$needle"* ]]; then _ok; else
    _bad "$(_where)" "$msg" \
      "should not contain: $(_trunc "$needle")" \
      "in:                 $(_trunc "$haystack")"
  fi
}

# assert_match STRING ERE [MSG]
assert_match() {
  local s=$1 re=$2 msg=${3:-pattern did not match}
  if printf '%s' "$s" | grep -Eq -- "$re"; then _ok; else
    _bad "$(_where)" "$msg" "pattern: $re" "subject: $(_trunc "$s")"
  fi
}

assert_not_match() {
  local s=$1 re=$2 msg=${3:-pattern should not match}
  if printf '%s' "$s" | grep -Eq -- "$re"; then
    _bad "$(_where)" "$msg" "pattern: $re" "subject: $(_trunc "$s")"
  else _ok; fi
}

assert_file() {
  local p=$1 msg=${2:-file missing}
  if [[ -f $p ]]; then _ok; else _bad "$(_where)" "$msg" "no such file: $p"; fi
}

assert_no_file() {
  local p=$1 msg=${2:-file should not exist}
  if [[ ! -e $p ]]; then _ok; else _bad "$(_where)" "$msg" "unexpectedly present: $p"; fi
}

# assert_no_file_newer PATH REF [MSG] -- PATH was not modified after REF.
assert_no_file_newer() {
  local p=$1 ref=$2 msg=${3:-file was rebuilt}
  if [[ -e $p && $p -nt $ref ]]; then
    _bad "$(_where)" "$msg" "$p is newer than $ref"
  else _ok; fi
}

assert_dir() {
  local p=$1 msg=${2:-directory missing}
  if [[ -d $p ]]; then _ok; else _bad "$(_where)" "$msg" "no such directory: $p"; fi
}

# assert_ok MSG -- CMD...   (runs CMD, expects exit 0)
assert_ok() {
  local msg=$1; shift
  [[ ${1:-} == -- ]] && shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  if (( rc == 0 )); then _ok; else
    _bad "$(_where)" "$msg" "command: $*" "exit:    $rc" "output:  $(_trunc "$out")"
  fi
}

assert_fails() {
  local msg=$1; shift
  [[ ${1:-} == -- ]] && shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  if (( rc != 0 )); then _ok; else
    _bad "$(_where)" "$msg" "command unexpectedly succeeded: $*" "output: $(_trunc "$out")"
  fi
}

# assert_same_tree DIR_A DIR_B [MSG] -- byte-identical recursive comparison.
assert_same_tree() {
  local a=$1 b=$2 msg=${3:-trees differ}
  local out
  if out=$(diff -r "$a" "$b" 2>&1); then _ok; else
    _bad "$(_where)" "$msg" "diff -r $a $b" "$(_trunc "$out" 800)"
  fi
}

# Every .html file under the built site. Populated lazily; callers use
# "$(site_html)" in a for loop.
site_html() { find "${1:-$REPO_ROOT/_site}" -name '*.html' -type f | LC_ALL=C sort; }

# visible_text FILE -- the page with code blocks and inline code removed, for
# checks that must not fire on a post documenting the syntax they look for.
visible_text() { awk -f "$TESTDIR/strip-code.awk" "$1"; }

# make_in DIR ARGS... -- run make in DIR as a user would, not as a sub-make.
#
# When the suite is invoked through `make test`, MAKELEVEL and MAKEFLAGS are
# already in the environment. GNU make then treats the inner call as recursive
# and prints "Entering directory", which is not silence; worse, it inherits
# flags, so a `make -j8 test` would quietly make the tests' own `make -j1` run
# in parallel and defeat the comparison. Scrub all three.
make_in() {
  local dir=$1; shift
  ( cd "$dir" && env -u MAKELEVEL -u MAKEFLAGS -u MFLAGS make "$@" )
}

# repo_copy DEST -- a scratch copy of the working tree without generated or
# VCS directories, for tests that build but must not disturb the tree they
# were launched from.
repo_copy() {
  local dest=$1
  rm -rf "$dest"; mkdir -p "$dest"
  ( cd "$REPO_ROOT" && tar -cf - \
      --exclude=_site --exclude=build --exclude=.git --exclude=.claude . ) \
    | ( cd "$dest" && tar -xf - )
}

# --- the fixture site ------------------------------------------------------
# tests/fixtures/site is a self-contained mini-site: bin/index uses only
# relative paths, so it runs anywhere the expected layout exists.

# fixture_copy DEST -- copy the fixture with working links to the templates
# and the citation style. Both committed symlinks are relative (so bin/index
# can be run inside the fixture directory by hand for debugging) and have to
# be re-pointed once copied. The fixture keeps its own bibliography.bib, but
# there is no point in a second copy of a vendored CSL.
fixture_copy() {
  local dest=$1
  rm -rf "$dest"; mkdir -p "$dest"
  ( cd "$TESTDIR/fixtures/site" && tar -cf - . ) | ( cd "$dest" && tar -xf - )
  ln -sfn "$REPO_ROOT/templates" "$dest/templates"
  ln -sfn "$REPO_ROOT/association-for-computing-machinery.csl" \
    "$dest/association-for-computing-machinery.csl"
}

# fixture_build DEST [JOBS] -- copy, then run bin/index in it.
fixture_build() {
  local dest=$1 jobs=${2:-1}
  fixture_copy "$dest"
  if ! ( cd "$dest" && JOBS=$jobs "$REPO_ROOT/bin/index" ) >"$dest.log" 2>&1; then
    _bad "$(_where 2)" "bin/index failed on the fixture site (JOBS=$jobs)" \
      "$(_trunc "$(cat "$dest.log")" 600)"
    return 1
  fi
  return 0
}

# fixture_site -- path to a built fixture, built once per tests/run invocation
# and shared between test files (they run sequentially, so no locking needed).
fixture_site() {
  local dir
  dir=$(dirname "$TMP")/fixture-site
  [[ -f $dir/build/blogs.md ]] || fixture_build "$dir" >/dev/null || return 1
  printf '%s' "$dir"
}

# Report counts to the driver and set the file's exit status.
_report() {
  local rc=$?
  trap - EXIT
  if (( rc != 0 && _fail == 0 && _skip == 0 )); then
    printf '    FAIL test file exited with status %d\n' "$rc" >&2
    _fail=$((_fail + 1))
  fi
  if [[ -n $COUNT_FILE ]]; then
    printf '%d %d %d %s\n' "$_pass" "$_fail" "$_skip" "$_skip_reason" >"$COUNT_FILE"
  fi
  [[ -n ${_lib_tmp_owned:-} ]] && rm -rf "$TMP"
  if (( _fail > 0 )); then exit 1; fi
  exit 0
}
trap _report EXIT
