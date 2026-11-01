#!/bin/bash
# Release herdr-caair: gate a fork commit, tag it v<upstream>-caair.<n>, and
# point the formula and the update-notice file at the tag.
#
#   scripts/release.sh <fork-commit-or-ref>     (default: origin/caair)
#
# Runs on the gate host (good-studio): it needs the fork-rebase herdr gate at
# $GATE. Pushing the tag to the fork and the formula to this tap are the only
# remote writes; both happen after the gate is green.
set -euo pipefail
FORK=${FORK:-CenterForAgenticAI/herdr}
GATE=${GATE:-$HOME/.local/share/fork-rebase/gates/herdr.sh}
WORK=${WORK:-$HOME/Library/Caches/fork-rebase/herdr-release}
tap=$(cd "$(dirname "$0")/.." && pwd)

[ -d "$WORK/.git" ] || git clone -q "https://github.com/$FORK" "$WORK"
git -C "$WORK" fetch -q --tags origin
ref=${1:-origin/caair}
sha=$(git -C "$WORK" rev-parse "$ref^{commit}")
git -C "$WORK" checkout -q --detach "$sha"
upstream=$(sed -n 's/^version = "\(.*\)"/\1/p' "$WORK/Cargo.toml" | head -1)
[ -n "$upstream" ] || { echo "no version in Cargo.toml" >&2; exit 1; }

existing=$(git -C "$WORK" tag --points-at "$sha" --list "v$upstream-caair.*" | head -1)
if [ -n "$existing" ]; then
  tag=$existing
  echo "commit $sha is already tagged $tag"
else
  n=$(git -C "$WORK" tag --list "v$upstream-caair.*" | sed "s/^v$upstream-caair\.//" | sort -n | tail -1)
  tag="v$upstream-caair.$(( ${n:-0} + 1 ))"
  echo "gating $sha for $tag"
  FORK_REBASE_GATE_LOG="$WORK.gate.log" "$GATE" "$WORK"
  git -C "$WORK" tag -a "$tag" -m "herdr-caair $tag (upstream $upstream)" "$sha"
  git -C "$WORK" push -q origin "refs/tags/$tag"
fi

version=${tag#v}
url="https://github.com/$FORK/archive/refs/tags/$tag.tar.gz"
sum=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
f="$tap/Formula/herdr-caair.rb"
sed -i '' -E \
  -e "s|^  url \".*\"|  url \"$url\"|" \
  -e "s|^  version \".*\"|  version \"$version\"|" \
  -e "s|^  sha256 \".*\"|  sha256 \"$sum\"|" "$f"
printf '{"versions":{"stable":"%s"}}\n' "$upstream" > "$tap/herdr-caair.json"
git -C "$tap" add Formula/herdr-caair.rb herdr-caair.json
if git -C "$tap" diff --cached --quiet; then
  echo "formula already at $tag"
  exit 0
fi
git -C "$tap" commit -q -m "herdr-caair $version"
git -C "$tap" push -q origin HEAD:main
echo "released $tag ($sha)"
