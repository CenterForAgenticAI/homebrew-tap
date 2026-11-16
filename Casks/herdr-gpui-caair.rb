cask "herdr-gpui-caair" do
  version "20261115.1-caair.4"
  sha256 "4b5d6294a7ffe5a2804ba59af6e85e4105e61753e942d3d902973466b517171d"

  url "https://github.com/CenterForAgenticAI/herdr-gpui/releases/download/v#{version}/Sheprd-#{version}-universal-apple-darwin.dmg"
  name "Sheprd"
  desc "Sheprd (formerly Herdr UI) with herdr desktop regions, built from the CenterForAgenticAI fork"
  homepage "https://github.com/CenterForAgenticAI/herdr-gpui"

  conflicts_with cask: ["herdr-gpui", "sheprd"]
  depends_on macos: ">= :sonoma"

  app "Sheprd.app"

  # Self-signed and not notarized, so Gatekeeper refuses the quarantined copy.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Sheprd.app"]
  end
end
