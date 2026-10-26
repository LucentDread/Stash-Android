#!/usr/bin/env bash
# Creates the vX.Y.Z tags and GitHub releases that are missing.
#
# Versions come from the history of pubspec.yaml: each version is tagged on
# the last commit that has it. Only versions with a "## X.Y.Z" section in
# CHANGELOG.md are published; the section is the release notes, and
# existing releases are updated when it changes.
#
# Runs in GitHub Actions (.github/workflows/publish-releases.yml) or from a
# clone with git and an authenticated GitHub CLI:
#   bash scripts/publish-releases.sh [--apks DIR]
# With --apks, DIR/Stash-X.Y.Z-arm64-v8a.apk is attached to release X.Y.Z.
set -euo pipefail

apks=
if [[ "${1:-}" == --apks ]]; then
  apks=$2
fi

notes() {
  awk -v v="$1" '$0 == "## " v { on = 1; next } /^## / { on = 0 } on' CHANGELOG.md
}

# Text without carriage returns or trailing blank space, to compare notes.
trimmed() {
  printf '%s' "$1" | tr -d '\r' | sed -e 's/[[:space:]]*$//' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

git fetch --quiet origin --tags

# version -> last commit with that version, oldest version first.
declare -A last
order=()
while read -r commit; do
  version=$(git show "$commit:pubspec.yaml" 2> /dev/null |
    sed -n 's/^version: *\([0-9][0-9.]*\).*/\1/p')
  [[ -z "$version" ]] && continue
  [[ -z "${last[$version]:-}" ]] && order+=("$version")
  last[$version]=$commit
done < <(git log --reverse --first-parent --format=%H HEAD)

latest=
for version in "${order[@]}"; do
  [[ -n "$(notes "$version")" ]] && latest=$version
done

for version in "${order[@]}"; do
  body=$(notes "$version")
  if [[ -z "$body" ]]; then
    echo "$version: no section in CHANGELOG.md, skipped"
    continue
  fi
  tag="v$version"
  if ! git rev-parse -q --verify "refs/tags/$tag" > /dev/null; then
    git tag -a "$tag" "${last[$version]}" -m "Stash Android $version" -m "$body"
    git push --quiet origin "refs/tags/$tag"
    echo "$tag: tag created on ${last[$version]:0:7}"
  fi

  apk=
  if [[ -n "$apks" && -f "$apks/Stash-$version-arm64-v8a.apk" ]]; then
    apk="$apks/Stash-$version-arm64-v8a.apk"
  fi
  if current=$(gh release view "$tag" --json body -q .body 2> /dev/null); then
    if [[ "$(trimmed "$current")" != "$(trimmed "$body")" ]]; then
      gh release edit "$tag" --notes "$body" > /dev/null
      echo "$tag: release notes updated"
    fi
    if [[ -n "$apk" ]]; then
      gh release upload "$tag" "$apk" --clobber
      echo "$tag: APK updated"
    fi
    continue
  fi
  latest_flag=--latest=false
  [[ "$version" == "$latest" ]] && latest_flag=--latest
  gh release create "$tag" ${apk:+"$apk"} --verify-tag \
    --title "Stash Android $version" --notes "$body" "$latest_flag"
  echo "$tag: release created${apk:+ with the APK}"
done
