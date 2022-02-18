class VarnishModules < Formula
  desc "Varnish module collection by Varnish Software"
  homepage "https://github.com/varnish/varnish-modules/"
  license "BSD-2-Clause"
  url "https://github.com/varnish/varnish-modules/releases/download/0.19.0/varnish-modules-0.19.0.tar.gz"
  sha256 "7279f5ff745ab9c03fab19a1c71bf27dd399dcb4e14f415c3071c97367b71dfb"
  version "0.19.0"

  depends_on "docutils" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "sphinx-doc" => :build
  depends_on "varnish"


  def install
    ENV["PYTHON"] = Formula["python@3.9"].opt_bin/"python3"
    configure_args = std_configure_args.select { |arg| arg != "--disable-debug" }
    system "./configure", *configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    testvcl = testpath/"varnish_modules_test.vcl"
    testvcl.write <<~EOS
      vcl 4.1;
      backend default none;
      import accept;
      import bodyaccess;
      import header;
      import saintmode;
      import str;
      import tcp;
      import var;
      import vsthrottle;
      import xkey;
    EOS
    system "#{HOMEBREW_PREFIX}/sbin/varnishd",
      "-p", "vmod_path=#{lib}/varnish/vmods",
      "-C", "-f", "#{testvcl}"
  end
end
