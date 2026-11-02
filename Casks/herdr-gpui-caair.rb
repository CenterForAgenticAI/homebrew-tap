cask "herdr-gpui-caair" do
  version "20261102.2-caair.2"
  sha256 "d27a5eed59ddc8c8e4e9dd601d49e9379dd7c2190c475935e14606a47e980f4c"

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
