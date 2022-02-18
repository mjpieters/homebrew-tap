# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class LibvfpBrotli < Formula
  desc "Varnish Fetch Processor for brotli de-/compression"
  homepage "https://code.uplex.de/uplex-varnish/libvfp-brotli"
  license "BSD-2-Clause"
  head "https://gitlab.com/mjpieters/libvfp-brotli.git"
  url "https://gitlab.com/mjpieters/libvfp-brotli/-/archive/6.2+macos.0/libvfp-brotli-6.2+macos.0.tar.bz2"
  sha256 "584e854614623a30d957ba643d7a29e30390be17d88de39b056139eccc70c178"
  version "6.2+macos.0"

  depends_on "autoconf" => :build
  depends_on "autoconf-archive" => :build
  depends_on "automake" => :build
  depends_on "docutils" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "brotli"
  depends_on "varnish"

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    system "./autogen.sh"
    configure_args = std_configure_args.select { |arg| arg != "--disable-debug" }
    system "./configure", *configure_args, "--disable-silent-rules"
    system "make", "install" # if this fails, try separate make/make install steps
  end

  test do
    testvcl = testpath/"vmod_brotli_test.vcl"
    testvcl.write <<~EOS
      vcl 4.1;
      backend default none;
      import brotli;
    EOS
    system "#{HOMEBREW_PREFIX}/sbin/varnishd",
      "-p", "vmod_path=#{lib}/varnish/vmods",
      "-C", "-f", "#{testvcl}"
  end
end
