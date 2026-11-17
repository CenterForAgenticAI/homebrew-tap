cask "herdr-gpui-caair" do
  version "20261115.1-caair.6"
  sha256 "9c52845c7c28aece69716bf54921c63219d9c6b7c31560ed1f2812ddcf88463e"

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
