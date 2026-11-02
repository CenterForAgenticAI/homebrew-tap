# CenterForAgenticAI Homebrew tap

## herdr-caair

[herdr](https://github.com/herdrdev/herdr) built from the [CenterForAgenticAI fork](https://github.com/CenterForAgenticAI/herdr) branch `caair`: upstream herdr plus desktop regions, which let plugins add docked side and bottom panels.

```bash
brew tap centerforagenticai/tap
brew trust --tap centerforagenticai/tap
brew install herdr-caair
```

Homebrew 7 and later refuse to load a formula from a tap you have not trusted, so the `brew trust` step is required.

It builds from source (Rust and Zig 0.16) and conflicts with the upstream `herdr` formula, because both install a `herdr` binary. Uninstall `herdr` first.

Update with `brew update && brew upgrade herdr-caair`. Herdr's own `herdr update` is disabled for Homebrew installs; the update notice reads `herdr-caair.json` in this repository.

Versions are `<upstream version>-caair.<n>`, tagged `v<upstream>-caair.<n>` on the fork.

## herdr-gpui-caair

The Herdr desktop app built from the [CenterForAgenticAI fork](https://github.com/CenterForAgenticAI/herdr-gpui) branch `caair`: the latest Herdr UI release plus the desktop region panels that show herdr-caair's plugin regions.

```bash
brew uninstall --cask herdr-gpui   # if installed; it is the same app
brew install --cask centerforagenticai/tap/herdr-gpui-caair
```

It replaces `herdr-gpui` rather than sitting beside it: it keeps the app's identity, so settings, pairings and sign-ins carry over. It is signed with our own certificate, not Apple-notarized, so the cask clears the download quarantine. macOS asks once to let it use the keychain items the official app saved.

Update with `brew upgrade --cask herdr-gpui-caair`; the app's own updater is off. Versions are `<upstream version>-caair.<n>`; the DMG is on the fork's GitHub release `v<version>`.

## Releasing

On the gate host, from a clone of this repository:

```bash
scripts/release.sh [fork commit or ref, default origin/caair]
```

For Herdr UI, run `scripts/release-herdr-gpui.sh` the same way; it builds the app on macOS, publishes the DMG as a release on the fork, and updates the cask.

The script runs the fork's gate on the commit, tags it, pushes the tag to the fork, and commits the new formula URL, version and checksum here. The `formula` workflow then builds and tests the formula on macOS.

Releases are automatic. The fork's rebase pipeline ([fork-sync](https://github.com/CenterForAgenticAI/fork-sync) `rebase/`) runs this script through `RELEASE_CMD` each time it publishes a new `caair` without needing review. A run that needs review publishes nothing, so nothing is released until a person publishes it and the next run picks it up.
