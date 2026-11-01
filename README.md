# CenterForAgenticAI Homebrew tap

## herdr-caair

[herdr](https://github.com/herdrdev/herdr) built from the [CenterForAgenticAI fork](https://github.com/CenterForAgenticAI/herdr) branch `caair`: upstream herdr plus desktop regions, which let plugins add docked side and bottom panels.

```bash
brew install centerforagenticai/tap/herdr-caair
```

It builds from source (Rust and Zig 0.16) and conflicts with the upstream `herdr` formula, because both install a `herdr` binary. Uninstall `herdr` first.

Update with `brew update && brew upgrade herdr-caair`. Herdr's own `herdr update` is disabled for Homebrew installs; the update notice reads `herdr-caair.json` in this repository.

Versions are `<upstream version>-caair.<n>`, tagged `v<upstream>-caair.<n>` on the fork.

## Releasing

On the gate host, from a clone of this repository:

```bash
scripts/release.sh [fork commit or ref, default origin/caair]
```

The script runs the fork's gate on the commit, tags it, pushes the tag to the fork, and commits the new formula URL, version and checksum here. The `formula` workflow then builds and tests the formula on macOS.
