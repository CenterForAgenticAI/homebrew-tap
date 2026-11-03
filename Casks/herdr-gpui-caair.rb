cask "herdr-gpui-caair" do
  version "20261103.1-caair.1"
  sha256 "5b217bd524366fc5d33a5f77aede1f904000786d61f7e3a56a288cb946f9513f"

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
