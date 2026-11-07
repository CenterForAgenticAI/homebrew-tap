#!/bin/bash
# Release herdr-gpui-caair: build the Sheprd app (formerly Herdr UI) from a CenterForAgenticAI/herdr-gpui
# commit, tag it v<upstream>-caair.<n>, attach its DMG to a GitHub release on
# the fork, and point Casks/herdr-gpui-caair.rb at it.
#
#   scripts/release-herdr-gpui.sh [fork commit or ref]     (default: origin/caair)
#
# Runs on the gate host (good-studio, macOS). <upstream> is the penso release
# the commit is built on, the newest v2* tag below it. The app keeps that
# version, so the remote hosts it sets up get penso's matching host builds,
# checked with penso's public update key. It is built with HERDR_UPDATES=package,
# so it never offers penso's release in place of itself; Homebrew updates it.
#
# It is signed with this host's self-signed identity, made on the first run in
# $SIGNING, so macOS keychain grants survive updates. It is not notarized; the
# cask clears the quarantine flag. RELEASE_GATED=1 skips the gate when the
# caller (fork-rebase.sh) has just gated this exact commit. PUBLISH=0 builds and
# signs, prints the DMG path, and changes nothing remote. Rerunning on a
# released commit changes nothing.
set -euo pipefail
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:/opt/homebrew/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# Git gets GitHub credentials from gh (a token file), not the macOS keychain,
# which is locked when no one is logged in and fails headless pushes.
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=credential.helper GIT_CONFIG_VALUE_0='' \
  GIT_CONFIG_KEY_1=credential.helper GIT_CONFIG_VALUE_1='!gh auth git-credential'
FORK=${FORK:-CenterForAgenticAI/herdr-gpui}
UPSTREAM=${UPSTREAM:-penso/herdr-gpui}
GATE=${GATE:-$HOME/.local/share/fork-rebase/gates/herdr-gpui.sh}
WORK=${WORK:-$HOME/Library/Caches/fork-rebase/herdr-gpui-release}
SIGNING=${SIGNING:-$HOME/.local/share/fork-rebase/signing/herdr-gpui}
PUBLISH=${PUBLISH:-1}
# penso's Ed25519 update verification key (public). It verifies
# host-manifest.sig of release v20261102.2 and is embedded in penso's app.
UPDATE_KEY=3c1723c89e341edf50b155a2c951f6090a4ad77d56c110639c59ad4b0843592f
SIGN_NAME="CAAIR Herdr Code Signing"
tap=$(cd "$(dirname "$0")/.." && pwd)
cask="$tap/Casks/herdr-gpui-caair.rb"
fail() { echo "$*" >&2; exit 1; }
[ "$(uname -s)" = Darwin ] || fail "macOS required"
[ "$PUBLISH" = 0 ] || git -C "$tap" pull -q --ff-only origin main

[ -d "$WORK/.git" ] || git clone -q "https://github.com/$FORK" "$WORK"
git -C "$WORK" fetch -q --prune origin '+refs/heads/*:refs/remotes/origin/*' '+refs/tags/*:refs/tags/*'
# The mirror copies no tags; the release tags come from penso. --no-prune:
# under fetch.prune=true this fetch would delete our v2*-caair.* tags, which
# penso lacks, and the next release would reuse a published tag.
git -C "$WORK" fetch -q --no-tags --no-prune "https://github.com/$UPSTREAM" '+refs/tags/v2*:refs/tags/v2*'
sha=$(git -C "$WORK" rev-parse "${1:-origin/caair}^{commit}")
base=$(git -C "$WORK" describe --tags --abbrev=0 --match 'v2*' --exclude '*-caair.*' "$sha") \
  || fail "no penso release tag below $sha"
upstream=${base#v}
[[ $upstream =~ ^[1-9][0-9]{7}\.[1-9][0-9]*$ ]] || fail "unexpected upstream tag $base"

existing=$(git -C "$WORK" tag --points-at "$sha" --list "v$upstream-caair.*" | sort -t. -k3 -n | tail -1)
if [ -n "$existing" ] && grep -q "^  version \"${existing#v}\"$" "$cask"; then
  echo "already released $existing"
  exit 0
fi
if [ -n "$existing" ]; then
  tag=$existing
else
  n=$(git -C "$WORK" tag --list "v$upstream-caair.*" | sed "s/^v$upstream-caair\.//" | sort -n | tail -1)
  tag="v$upstream-caair.$(( ${n:-0} + 1 ))"
fi
# Never publish a commit under a tag the fork already gave another commit.
published=$(git -C "$WORK" ls-remote origin "refs/tags/$tag^{}" | cut -f1)
[ -z "$published" ] || [ "$published" = "$sha" ] \
  || fail "$tag already names $published on $FORK, not $sha"
version=${tag#v}
asset="Sheprd-$version-universal-apple-darwin.dmg"
git -C "$WORK" checkout -q --detach "$sha"
git -C "$WORK" clean -qfd

# A temporary keychain holding the signing identity, on the user search list
# only while signing: codesign ignores --keychain when it looks up an identity.
keychain=""
saved=()
cleanup() {
  [ -n "$keychain" ] || return 0
  [ ${#saved[@]} = 0 ] || security list-keychains -d user -s "${saved[@]}"
  security delete-keychain "$keychain" 2>/dev/null || true
}
trap cleanup EXIT
signing_setup() {
  mkdir -p "$SIGNING" && chmod 700 "$SIGNING"
  if [ ! -f "$SIGNING/identity.p12" ]; then
    local tmp; tmp=$(mktemp -d)
    printf '%s\n' '[req]' 'distinguished_name=dn' 'x509_extensions=ext' 'prompt=no' \
      '[dn]' "CN=$SIGN_NAME" \
      '[ext]' 'basicConstraints=critical,CA:false' 'keyUsage=critical,digitalSignature' \
      'extendedKeyUsage=critical,codeSigning' > "$tmp/req.cnf"
    /usr/bin/openssl req -x509 -newkey rsa:3072 -nodes -days 3650 -config "$tmp/req.cnf" \
      -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
    (umask 077; /usr/bin/openssl rand -hex 16 > "$SIGNING/password")
    /usr/bin/openssl pkcs12 -export -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
      -passout "file:$SIGNING/password" -out "$SIGNING/identity.p12"
    chmod 600 "$SIGNING/identity.p12"
    rm -rf "$tmp"
  fi
  local password; password=$(/usr/bin/openssl rand -hex 16)
  keychain="$SIGNING/build.keychain-db"
  security delete-keychain "$keychain" 2>/dev/null || true
  security create-keychain -p "$password" "$keychain"
  security set-keychain-settings -lut 7200 "$keychain"
  security unlock-keychain -p "$password" "$keychain"
  security import "$SIGNING/identity.p12" -k "$keychain" -P "$(cat "$SIGNING/password")" \
    -T /usr/bin/codesign >/dev/null
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
  local line
  while IFS= read -r line; do
    line=${line#"${line%%[![:space:]]*}"}; line=${line#\"}; line=${line%\"}
    [ -n "$line" ] && saved+=("$line")
  done < <(security list-keychains -d user)
  security list-keychains -d user -s "$keychain" ${saved[@]+"${saved[@]}"}
  HERDR_SIGN_IDENTITY=$(security find-certificate -c "$SIGN_NAME" -Z "$keychain" | awk '/SHA-1/ { print $NF; exit }')
  [ -n "$HERDR_SIGN_IDENTITY" ] || fail "signing identity missing from $keychain"
  export HERDR_SIGN_IDENTITY
}

# The fork's build-macos.sh sources the checkout's .envrc for herdr_sign; this
# one signs with the identity above and makes the DMG it expects. The helper
# list is package-macos.sh's: each companion plus its legacy herdr-* copy.
write_envrc() {
  cat > "$WORK/.envrc" <<'ENVRC'
herdr_sign() {
  local version=$1 app=$2 out=$3 executable image
  local entitlements="$release_root/assets/macos/Sheprd.entitlements"
  for executable in sheprd-acp sheprd-remote-control sheprd-automate sheprd-nearby herdr-core \
      herdr-acp herdr-remote-control herdr-automate herdr-nearby; do
    codesign --force --sign "$HERDR_SIGN_IDENTITY" --options runtime --timestamp=none "$app/Contents/MacOS/$executable"
  done
  codesign --force --sign "$HERDR_SIGN_IDENTITY" --options runtime --timestamp=none --entitlements "$entitlements" "$app/Contents/MacOS/sheprd"
  codesign --force --sign "$HERDR_SIGN_IDENTITY" --options runtime --timestamp=none --entitlements "$entitlements" "$app"
  codesign --verify --deep --strict "$app"
  image=$(mktemp -d)
  ditto "$app" "$image/Sheprd.app"
  ln -s /Applications "$image/Applications"
  hdiutil create -quiet -volname Sheprd -srcfolder "$image" -format UDZO -ov "$out/Sheprd-$version-universal-apple-darwin.dmg"
  rm -rf "$image"
}
ENVRC
}

build() {
  rm -rf "$WORK/target/distribution/$upstream"
  signing_setup
  write_envrc
  (cd "$WORK" && HERDR_UPDATE_PUBLIC_KEY=$UPDATE_KEY HERDR_UPDATES=package \
    bash scripts/release/build-macos.sh "$upstream" >&2)
  printf '%s\n' "$WORK/target/distribution/$upstream/Sheprd-$upstream-universal-apple-darwin.dmg"
}

dmg=""
if [ "$PUBLISH" != 0 ] && gh release view "$tag" -R "$FORK" --json assets -q '.assets[].name' 2>/dev/null | grep -qx "$asset"; then
  echo "$tag already has $asset"
else
  if [ -z "$existing" ] && [ "${RELEASE_GATED:-0}" != 1 ]; then
    echo "gating $sha for $tag"
    FORK_REBASE_GATE_LOG="$WORK.gate.log" "$GATE" "$WORK"
  fi
  echo "building $sha as $version (app version $upstream)"
  # Not dmg=$(build): signing_setup must run in this shell so the EXIT trap
  # restores the keychain search list.
  build > "$WORK.dmg-path"
  dmg=$(cat "$WORK.dmg-path")
  [ -s "$dmg" ] || fail "build left no DMG at $dmg"
  if [ "$PUBLISH" = 0 ]; then
    echo "$dmg"
    exit 0
  fi
  if [ -z "$existing" ]; then
    git -C "$WORK" tag -a "$tag" -m "herdr-gpui-caair $version (penso $base)" "$sha"
    git -C "$WORK" push -q origin "refs/tags/$tag"
  fi
  upload="$(dirname "$dmg")/$asset"
  cp "$dmg" "$upload"
  if gh release view "$tag" -R "$FORK" >/dev/null 2>&1; then
    gh release upload "$tag" "$upload" -R "$FORK" --clobber
  else
    gh release create "$tag" "$upload" -R "$FORK" --verify-tag --title "Sheprd $version" \
      --notes "Sheprd $upstream (penso $base) with herdr desktop regions and GitLab custom headers. Install with: brew install --cask centerforagenticai/tap/herdr-gpui-caair"
  fi
fi

if [ -n "$dmg" ]; then
  sum=$(shasum -a 256 "$dmg" | cut -d' ' -f1)
else
  sum=$(gh release download "$tag" -R "$FORK" -p "$asset" -O - | shasum -a 256 | cut -d' ' -f1)
fi
sed -i '' -E \
  -e "s|^  version \".*\"|  version \"$version\"|" \
  -e "s|^  sha256 .*|  sha256 \"$sum\"|" "$cask"
git -C "$tap" add Casks/herdr-gpui-caair.rb
if git -C "$tap" diff --cached --quiet; then
  echo "cask already at $tag"
  exit 0
fi
git -C "$tap" commit -q -m "herdr-gpui-caair $version"
git -C "$tap" push -q origin HEAD:main
echo "released $tag ($sha)"
