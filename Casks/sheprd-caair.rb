cask "sheprd-caair" do
  version "20261115.1-caair.7"
  sha256 "b3e2cfba64973c7c7cf881e0ef27b5f27fa4c93b617ccf3999ca92968372c2e4"

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
