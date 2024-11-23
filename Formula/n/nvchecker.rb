class Nvchecker < Formula
  include Language::Python::Virtualenv

  desc "New version checker for software releases"
  homepage "https://github.com/lilydjwg/nvchecker"
  url "https://files.pythonhosted.org/packages/7b/60/fd880c869c6a03768fcfe44168d7667f036e2499c8816dd106440e201332/nvchecker-2.15.1.tar.gz"
  sha256 "a2e2b0a8dd4545e83e0032e8d4a4d586c08e2d8378a61b637b45fdd4556f1167"
  license "MIT"
  revision 2

  bottle do
    rebuild 1
    sha256 cellar: :any,                 arm64_sequoia: "fe0db13d1224d35fc9cc7179cdad99e77f96d31ce777ebb5d83c5fce836c2873"
    sha256 cellar: :any,                 arm64_sonoma:  "0e07c5535aac4fb997747f3b0475cb9b690e79306d190c6120bb2450863abe38"
    sha256 cellar: :any,                 arm64_ventura: "b987f3a4e9e0f13c3ab8f0992af81a91a5451a720f8810c5f9d3daecc0d9e63e"
    sha256 cellar: :any,                 sonoma:        "00452573b0f565bf9c082c4ee374830da8a53bf9a144f4bef238d4151f10dcee"
    sha256 cellar: :any,                 ventura:       "81b83f83053cc80abd52e0f1d13b80942f444e01f61baa50806c38b557526328"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "20cdb4c36148d20d550cdecb17f052f5684c4ec7afce1f946fd182b560974c16"
  end

  depends_on "jq" => :test
  depends_on "curl"
  depends_on "openssl@3"
  depends_on "python@3.13"

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/d0/63/68dbb6eb2de9cb10ee4c9c14a0148804425e13c4fb20d61cce69f53106da/packaging-24.2.tar.gz"
    sha256 "c228a6dc5e932d346bc5739379109d49e8853dd8223571c7c5b55260edc0b97f"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/13/fc/128cc9cb8f03208bdbf93d3aa862e16d376844a14f9a0ce5cf4507372de4/platformdirs-4.3.6.tar.gz"
    sha256 "357fb2acbc885b0419afd3ce3ed34564c13c9b95c89360cd9563f73aa5e2b907"
  end

  resource "pycurl" do
    url "https://files.pythonhosted.org/packages/c9/5a/e68b8abbc1102113b7839e708ba04ef4c4b8b8a6da392832bb166d09ea72/pycurl-7.45.3.tar.gz"
    sha256 "8c2471af9079ad798e1645ec0b0d3d4223db687379d17dd36a70637449f81d6b"
  end

  resource "structlog" do
    url "https://files.pythonhosted.org/packages/78/a3/e811a94ac3853826805253c906faa99219b79951c7d58605e89c79e65768/structlog-24.4.0.tar.gz"
    sha256 "b27bfecede327a6d2da5fbc96bd859f114ecc398a6389d664f62085ee7ae6fc4"
  end

  resource "tornado" do
    url "https://files.pythonhosted.org/packages/59/45/a0daf161f7d6f36c3ea5fc0c2de619746cc3dd4c76402e9db545bd920f63/tornado-6.4.2.tar.gz"
    sha256 "92bad5b4746e9879fd7bf1eb21dce4e3fc5128d71601f80005afa39237ad620b"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    file = testpath/"example.toml"
    file.write <<~EOS
      [nvchecker]
      source = "pypi"
      pypi = "nvchecker"
    EOS

    out = shell_output("#{bin}/nvchecker -c #{file} --logger=json | jq '.[\"version\"]' ").strip
    assert_equal "\"#{version}\"", out
  end
end
