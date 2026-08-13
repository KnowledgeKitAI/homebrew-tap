class Oring < Formula
  desc "Agentic development toolkit for specs, sessions, and Git workflows"
  homepage "https://github.com/KnowledgeKitAI/oring"
  url "https://registry.npmjs.org/@knowledgekit/oring/-/oring-0.0.6.tgz"
  sha256 "baad2140b56d9be0ed6940587651f59a47ae26e92938df6a190d6ccd103a8126"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oring --version")
    assert_match "Agentic development toolkit", shell_output("#{bin}/oring --help")
  end
end
