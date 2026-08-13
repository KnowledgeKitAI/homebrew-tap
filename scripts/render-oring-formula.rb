# typed: strict
# frozen_string_literal: true

path, version, darwin_arm64, darwin_x64, linux_arm64, linux_x64 = ARGV
release = "https://github.com/KnowledgeKitAI/oring/releases/download/v#{version}"

content = <<~FORMULA
  class Oring < Formula
    desc "Agentic development toolkit for specs, sessions, and Git workflows"
    homepage "https://github.com/KnowledgeKitAI/oring"
    version "#{version}"
    license "MIT"

    on_macos do
      if Hardware::CPU.arm?
        url "#{release}/oring-v#{version}-darwin-arm64.tar.gz"
        sha256 "#{darwin_arm64}"
      else
        url "#{release}/oring-v#{version}-darwin-x64.tar.gz"
        sha256 "#{darwin_x64}"
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        url "#{release}/oring-v#{version}-linux-arm64.tar.gz"
        sha256 "#{linux_arm64}"
      else
        url "#{release}/oring-v#{version}-linux-x64.tar.gz"
        sha256 "#{linux_x64}"
      end
    end

    def install
      bin.install "oring"
    end

    test do
      assert_match version.to_s, shell_output("\#{bin}/oring --version")
      assert_match "Agentic development toolkit", shell_output("\#{bin}/oring --help")
      assert_match '"sessions"', shell_output("\#{bin}/oring tui --demo --json")
    end
  end
FORMULA

File.write(path, content)
