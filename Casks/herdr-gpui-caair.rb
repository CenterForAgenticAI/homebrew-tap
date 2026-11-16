cask "herdr-gpui-caair" do
  version "20261115.1-caair.2"
  sha256 "a2272565a283e89bed6e03be4e8d1d381c28ce88f7afc582439d51af487097ec"

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
