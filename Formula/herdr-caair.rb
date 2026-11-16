class HerdrCaair < Formula
  desc "Agent multiplexer that lives in your terminal (CAAIR fork with desktop regions)"
  homepage "https://github.com/CenterForAgenticAI/herdr"
  url "https://github.com/CenterForAgenticAI/herdr/archive/refs/tags/v0.9.5-caair.2.tar.gz"
  version "0.9.5-caair.2"
  sha256 "6d7b357d9535ceeb777db9544bb5aee82ed3ce060f16e7760fbac2d24976e89b"
  license "Apache-2.0"
  head "https://github.com/CenterForAgenticAI/herdr.git", branch: "caair"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+-caair\.\d+)$/i)
  end

  depends_on "rust" => :build
  depends_on "zig@0.16" => :build

  conflicts_with "herdr", because: "both install a `herdr` binary"

  # zig's own HTTPS client fails with TlsInitializationFailed inside Homebrew's
  # sandboxed fetch phase on Homebrew 7.0.13 for these two hosts (Let's Encrypt
  # chains), while its other dependencies download fine. Homebrew downloads
  # these with curl instead; `fetch` hands them to zig. Pins match
  # vendor/libghostty-vt/build.zig.zon and pkg/fontconfig/build.zig.zon.
  resource "translate-c" do
    url "https://codeberg.org/vancluever/translate-c/archive/4e879eb8aba615de112eabd1231ea6e01920cead.tar.gz"
    sha256 "8fb0f5c6a3e8b3bf0e35225d3abc1230bcf6f1fdf162467f1f747ec2fa5eda07"
  end

  resource "fontconfig" do
    url "https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/2.18.3/fontconfig-2.18.3.tar.xz"
    sha256 "4f7b554a38cdf78c033f666c8871f3749e14a094f65a07f630c91ed0b43d35e3"
  end

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
    cd "vendor/libghostty-vt" do
      # Seed zig's package cache from the resources above (already downloaded
      # by Homebrew); zig skips any dependency whose hash is already cached.
      %w[translate-c fontconfig].each do |name|
        system "zig", "fetch", resource(name).cached_download
      end
      system "zig", "build", "--fetch=all"
    end
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"herdr", "completion")
  end

  test do
    # The binary reports the upstream version it was built from, without -caair.N.
    upstream = version.to_s.sub(/-caair\.\d+\z/, "")
    assert_match upstream, shell_output("#{bin}/herdr --version")

    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["HERDR_CONFIG_PATH"] = (testpath/"config.toml").to_s
    ENV["HERDR_SOCKET_PATH"] = (testpath/"herdr.sock").to_s

    pid = spawn bin/"herdr", "server"
    status = ""
    10.times do
      status = shell_output("#{bin}/herdr status server")
      break if status.include?("status: running")

      sleep 1
    end
    assert_match "status: running", status
    assert_match "version: #{upstream}", status

    output = shell_output("#{bin}/herdr workspace create --label brew-test --no-focus")
    workspace = JSON.parse(output).dig("result", "workspace")
    assert_equal "brew-test", workspace["label"]

    output = shell_output("#{bin}/herdr region list")
    assert_kind_of Array, JSON.parse(output).dig("result", "regions")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
