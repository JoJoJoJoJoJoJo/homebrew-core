class Prestodb < Formula
  include Language::Python::Shebang

  desc "Distributed SQL query engine for big data"
  homepage "https://prestodb.io"
  url "https://search.maven.org/remotecontent?filepath=com/facebook/presto/presto-server/0.291/presto-server-0.291.tar.gz", using: :nounzip
  sha256 "257702209ddfcc49dd6764ab8ea959d441313f3b74bb9b86c45c9a8a63a0a691"
  license "Apache-2.0"

  # Upstream has said that we should check Maven for Presto version information
  # and the highest version found there is newest:
  # https://github.com/prestodb/presto/issues/16200
  livecheck do
    url "https://search.maven.org/remotecontent?filepath=com/facebook/presto/presto-server/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "17327469b90b34fed7a4ec15f9de93dade68120221296b8962f53db98f0f66b4"
  end

  depends_on "openjdk@17"
  depends_on "python@3.13"

  resource "presto-cli" do
    url "https://search.maven.org/remotecontent?filepath=com/facebook/presto/presto-cli/0.291/presto-cli-0.291-executable.jar"
    sha256 "3919eb122ad7090364430b500478465024e6524c8399fbf54181e9ac4ebb176b"

    livecheck do
      formula :parent
    end
  end

  def install
    java_version = "17"
    odie "presto-cli resource needs to be updated" if version != resource("presto-cli").version

    # Manually extract tarball to avoid multiple copies/moves of over 2GB of files
    libexec.mkpath
    system "tar", "-C", libexec.to_s, "--strip-components", "1", "-xzf", "presto-server-#{version}.tar.gz"

    (libexec/"etc/node.properties").write <<~EOS
      node.environment=production
      node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
      node.data-dir=#{var}/presto/data
    EOS

    (libexec/"etc/jvm.config").write <<~EOS
      -server
      -Xmx16G
      -XX:+UseG1GC
      -XX:G1HeapRegionSize=32M
      -XX:+UseGCOverheadLimit
      -XX:+ExplicitGCInvokesConcurrent
      -XX:+HeapDumpOnOutOfMemoryError
      -XX:+ExitOnOutOfMemoryError
      -Djdk.attach.allowAttachSelf=true
    EOS

    (libexec/"etc/config.properties").write <<~EOS
      coordinator=true
      node-scheduler.include-coordinator=true
      http-server.http.port=8080
      query.max-memory=5GB
      query.max-memory-per-node=1GB
      discovery-server.enabled=true
      discovery.uri=http://localhost:8080
    EOS

    (libexec/"etc/log.properties").write "com.facebook.presto=INFO"

    (libexec/"etc/catalog/jmx.properties").write "connector.name=jmx"

    rewrite_shebang detected_python_shebang, libexec/"bin/launcher.py"
    env = Language::Java.overridable_java_home_env(java_version)
    (bin/"presto-server").write_env_script libexec/"bin/launcher", env

    resource("presto-cli").stage do
      libexec.install "presto-cli-#{version}-executable.jar"
      bin.write_jar_script(libexec/"presto-cli-#{version}-executable.jar", "presto", java_version:)
    end

    # Remove incompatible pre-built binaries
    libprocname_dirs = (libexec/"bin/procname").children
    # Keep the Linux-x86_64 directory to make bottles identical
    libprocname_dirs.reject! { |dir| dir.basename.to_s == "Linux-x86_64" }
    libprocname_dirs.reject! { |dir| dir.basename.to_s == "#{OS.kernel_name}-#{Hardware::CPU.arch}" }
    rm_r libprocname_dirs
  end

  def post_install
    (var/"presto/data").mkpath
  end

  def caveats
    <<~EOS
      Add connectors to #{opt_libexec}/etc/catalog/. See:
      https://prestodb.io/docs/current/connector.html
    EOS
  end

  service do
    run [opt_bin/"presto-server", "run"]
    working_dir opt_libexec
  end

  test do
    port = free_port
    cp libexec/"etc/config.properties", testpath/"config.properties"
    inreplace testpath/"config.properties", "8080", port.to_s
    server = fork do
      exec bin/"presto-server", "run", "--verbose",
                                       "--data-dir", testpath,
                                       "--config", testpath/"config.properties"
    end
    sleep 60

    query = "SELECT state FROM system.runtime.nodes"
    output = shell_output(bin/"presto --debug --server localhost:#{port} --execute '#{query}'")
    assert_match "\"active\"", output
  ensure
    Process.kill("TERM", server)
    Process.wait server
  end
end
