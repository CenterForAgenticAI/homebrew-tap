cask "sheprd-caair" do
  version "20261118.1-caair.3"
  sha256 "3b2c40349c4cf6b107ded7ba7194678d4778a0e22ed531701eb49c1a92f3055b"

  url "https://github.com/CenterForAgenticAI/sheprd/releases/download/v#{version}/Sheprd-#{version}-universal-apple-darwin.dmg"
  name "Sheprd"
  desc "Sheprd (formerly Herdr UI) with herdr desktop regions, built from the CenterForAgenticAI fork"
  homepage "https://github.com/CenterForAgenticAI/sheprd"

  conflicts_with cask: ["herdr-gpui", "sheprd"]
  depends_on macos: ">= :sonoma"

  app "Sheprd.app"

  # Self-signed and not notarized, so Gatekeeper refuses the quarantined copy.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Sheprd.app"]
  end
end
