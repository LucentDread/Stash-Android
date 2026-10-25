#!/usr/bin/env bash
# One-off publishing of the version history: makes "main" the default
# branch, removes the old work branch, then creates the vX.Y.Z tags and
# the GitHub releases (notes taken from CHANGELOG.md).
#
# Needs git and the GitHub CLI (gh auth login). Run from a clone:
#   git clone https://github.com/LucentDread/Stash-Android && cd Stash-Android
#   bash scripts/publish-releases.sh [path/to/app-arm64-v8a-release.apk]
# The optional APK is attached to the latest release.
set -euo pipefail

repo=LucentDread/Stash-Android
old_branch=claude/stash-android-flutter-app-o9v0aq
apk=${1:-}

# "version commit", oldest first.
releases=(
  "1.0.0 d3583255fae20832a9914eb0ead6748cfbbe4b22"
  "1.1.0 aac367572559600e3b494051ebadf44c958d87ab"
  "1.1.1 a577b92f4246d4be62dc909933ebf672712f8e68"
  "1.2.0 ff470607d84fad63eeb019398c21b9932ee1428b"
  "1.2.1 d86e4e33e3e7a1755fc6f7f097bec6c56b6d255d"
  "1.3.0 ab58e6c270203c665855de16a2a4614281822860"
  "1.4.0 4b7660ce60d5660206e2636089d373b15729b839"
  "1.5.0 5d4bd415b79992584bdc256824192b7c3c8295dc"
  "1.6.0 61d5941e43ab3143bf6c276ed66ec8ec82ac523f"
  "1.7.0 befd8e8f2e1f8b33ed9161bec13b18b2dfa43a45"
  "1.7.1 37cebbf8c1a7cdfefa5320df21799e2bc5905603"
)

notes() {
  awk -v v="$1" '$0 == "## " v { on = 1; next } /^## / { on = 0 } on' CHANGELOG.md
}

git fetch --quiet origin --tags
gh repo edit "$repo" --default-branch main
if git ls-remote --exit-code --heads origin "$old_branch" > /dev/null; then
  # Not fatal: the tags and releases do not depend on it.
  git push origin --delete "$old_branch" ||
    echo "Branche $old_branch non supprimée (est-elle encore la branche par défaut ?)"
fi

latest=${releases[-1]%% *}
for entry in "${releases[@]}"; do
  version=${entry%% *}
  commit=${entry##* }
  tag="v$version"
  if ! git rev-parse -q --verify "refs/tags/$tag" > /dev/null; then
    git tag -a "$tag" "$commit" -m "Stash Android $version" -m "$(notes "$version")"
  fi
  git push --quiet origin "refs/tags/$tag"
  if gh release view "$tag" --repo "$repo" > /dev/null 2>&1; then
    echo "$tag : release déjà présente"
    continue
  fi
  assets=()
  if [[ "$version" == "$latest" && -n "$apk" ]]; then
    assets=("$apk#Stash-$version-arm64-v8a.apk")
  fi
  latest_flag=--latest=false
  [[ "$version" == "$latest" ]] && latest_flag=--latest
  gh release create "$tag" "${assets[@]}" --repo "$repo" --verify-tag \
    --title "Stash Android $version" --notes "$(notes "$version")" "$latest_flag"
  echo "$tag : release créée"
done
