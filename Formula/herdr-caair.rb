class HerdrCaair < Formula
  desc "Agent multiplexer that lives in your terminal (CAAIR fork with desktop regions)"
  homepage "https://github.com/CenterForAgenticAI/herdr"
  url "https://github.com/CenterForAgenticAI/herdr/archive/refs/tags/v0.9.5-caair.1.tar.gz"
  version "0.9.5-caair.1"
  sha256 "c9b6f252b5a91f580375a8f2f8870e351ce6223e25f6de8947cc1e19f03ce138"
  license "Apache-2.0"
  head "https://github.com/CenterForAgenticAI/herdr.git", branch: "caair"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+-caair\.\d+)$/i)
  end

  depends_on "rust" => :build
  depends_on "zig@0.16" => :build

  conflicts_with "herdr", because: "both install a `herdr` binary"

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
    cd "vendor/libghostty-vt" do
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
