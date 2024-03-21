class Qcachegrind < Formula
  desc "Visualize data generated by Cachegrind and Calltree"
  homepage "https://apps.kde.org/kcachegrind/"
  url "https://download.kde.org/stable/release-service/24.02.1/src/kcachegrind-24.02.1.tar.xz"
  sha256 "74dd958c439249bbfb3e6a8f08210733887a6f98157ed32fe6c26fd402f71015"
  license "GPL-2.0-or-later"
  head "https://invent.kde.org/sdk/kcachegrind.git", branch: "master"

  # We don't match versions like 19.07.80 or 19.07.90 where the patch number
  # is 80+ (beta) or 90+ (RC), as these aren't stable releases.
  livecheck do
    url "https://download.kde.org/stable/release-service/"
    regex(%r{href=.*?v?(\d+\.\d+\.(?:(?![89]\d)\d+)(?:\.\d+)*)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "080613ecd3eb5f6f7057e71b27d998b11bb2b77b195e4f2a77392cd7041eba69"
    sha256 cellar: :any,                 arm64_ventura:  "080613ecd3eb5f6f7057e71b27d998b11bb2b77b195e4f2a77392cd7041eba69"
    sha256 cellar: :any,                 arm64_monterey: "0848fb96885b07660cb52e8dff650b7ae927012a9540155c0d9ac8c6dddee071"
    sha256 cellar: :any,                 sonoma:         "abb85b519480fe185fd24d38de324309daab37601b617a555714df329b585722"
    sha256 cellar: :any,                 ventura:        "abb85b519480fe185fd24d38de324309daab37601b617a555714df329b585722"
    sha256 cellar: :any,                 monterey:       "99c1f38da79dfd7b2827112a2e61c7bec2b033d6f2dd043536d22cfef5f3ae1f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "e7a3dd4ae5be833f996b409c8db1908baff72e5f053a118bb7b8f496dc829b5a"
  end

  depends_on "graphviz"
  depends_on "qt"

  fails_with gcc: "5"

  def install
    args = %w[-config release]
    if OS.mac?
      spec = (ENV.compiler == :clang) ? "macx-clang" : "macx-g++"
      args += %W[-spec #{spec}]
    end

    qt = Formula["qt"]
    system qt.opt_bin/"qmake", *args
    system "make"

    if OS.mac?
      prefix.install "qcachegrind/qcachegrind.app"
      bin.install_symlink prefix/"qcachegrind.app/Contents/MacOS/qcachegrind"
    else
      bin.install "qcachegrind/qcachegrind"
    end
  end
end
