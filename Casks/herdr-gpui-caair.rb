cask "herdr-gpui-caair" do
  version "0"
  sha256 :no_check

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
