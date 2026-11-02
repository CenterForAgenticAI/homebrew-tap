cask "herdr-gpui-caair" do
  version "20261102.2-caair.1"
  sha256 "496d5521da9499dbafb35df4def62c50d1f639d33cef982d982037fc6a2dfac5"

  url "https://github.com/CenterForAgenticAI/herdr-gpui/releases/download/v#{version}/Herdr-#{version}-universal-apple-darwin.dmg"
  name "Herdr"
  desc "Herdr UI with herdr desktop regions, built from the CenterForAgenticAI fork"
  homepage "https://github.com/CenterForAgenticAI/herdr-gpui"

  conflicts_with cask: "herdr-gpui"
  depends_on macos: ">= :sonoma"

  app "Herdr.app"

  # Self-signed and not notarized, so Gatekeeper refuses the quarantined copy.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Herdr.app"]
  end
end
