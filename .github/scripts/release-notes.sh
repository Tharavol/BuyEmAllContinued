#!/bin/sh
# Prints the CHANGELOG.md section for a release tag, for the GitHub release body.
# Usage: sh .github/scripts/release-notes.sh v4.1.6
#
# A stable tag (vX.Y.Z) needs a "## [X.Y.Z]" section. A prerelease tag (vX.Y.Z-beta.N) uses the "## [X.Y.Z]" section
# if there is one yet, otherwise "## [Unreleased]".
set -eu

tag=${1:?usage: release-notes.sh <tag>}
version=${tag#v}
base=${version%%-*}

section() {
  # Lines after the "## [$1]" heading, up to the next "## [" heading, without leading/trailing blank lines.
  awk -v want="$1" '
    index($0, "## [" want "]") == 1 { found = 1; next }
    found && /^## \[/ { exit }
    found { print }
  ' CHANGELOG.md | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

notes=$(section "$base")
if [ -z "$notes" ] && [ "$version" != "$base" ]; then
  notes=$(section "Unreleased")
fi
if [ -z "$notes" ]; then
  echo "CHANGELOG.md has no section for $tag" >&2
  exit 1
fi
printf '%s\n' "$notes"
