# Varnish 6.6; homebrew moved to 7.x in September 2021

class VarnishAT66 < Formula
  desc "High-performance HTTP accelerator"
  homepage "https://www.varnish-cache.org/"
  url "https://varnish-cache.org/_downloads/varnish-6.6.1.tgz"
  mirror "https://fossies.org/linux/www/varnish-6.6.1.tgz"
  sha256 "ab1a6884332731f983c8dab675c636deb3883a206c8a0127a7c663af2422e628"
  license "BSD-2-Clause"

  bottle do
    rebuild 1
    sha256 arm64_big_sur: "46491a9c57df2f0c3152076fc632ef50e22186bf7759b690acec8b39a6fdbf19"
    sha256 big_sur:       "1c90d1916d4e6dc927cd98ab5ab109a256d16c70fb42526d7c89ff93d8f9b57c"
    sha256 catalina:      "b26e8b5d1432a83ec038b052bc84e6d01bea4e6c76b7271680d11db231de76c3"
    sha256 mojave:        "4560be9295105df0da5c68109f53a76feb071c7dd3a1ed5bfa2e698241af0ad7"
  end

  # replace varnish/6.6 with varnish to reuse existing brew bottles
  def fetch_bottle_tab
    return unless bottled?

    # alter the manifest URL
    manifest_dl = bottle.send(:github_packages_manifest_resource).downloader
    manifest_dl.instance_variable_set(:@url, manifest_dl.url.sub(%r{/varnish/6\.6/}, "/varnish/"))
    
    # do the same with the bottle URL
    bottle_dl = bottle.resource.downloader
    bottle_dl.instance_variable_set(:@url, bottle_dl.url.sub(%r{/varnish/6\.6/}, "/varnish/"))

    # hook into bottle.stage, so we can redirect the extracted files to the right location
    bottle.instance_variable_set(:@_rack, rack)
    def bottle.stage
      @_rack.mkdir unless @_rack.exist?
      @_rack.cd do
        resource.downloader.stage do
          nested = @_rack / "varnish"
          FileUtils.mv(nested.children, @_rack)
          nested.rmdir
        end
      end
    end

    super
  end

  depends_on "docutils" => :build
  depends_on "graphviz" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "sphinx-doc" => :build
  depends_on "pcre"

  def install
    ENV["PYTHON"] = Formula["python@3.9"].opt_bin/"python3"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--localstatedir=#{var}"
    system "make", "install"
    (etc/"varnish").install "etc/example.vcl" => "default.vcl"
    (var/"varnish").mkpath
  end

  service do
    run [opt_sbin/"varnishd", "-n", var/"varnish", "-f", etc/"varnish/default.vcl", "-s", "malloc,1G", "-T",
         "127.0.0.1:2000", "-a", "0.0.0.0:8080", "-F"]
    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"varnish/varnish.log"
    error_log_path var/"varnish/varnish.log"
  end

  test do
    assert_match version.to_s, shell_output("#{sbin}/varnishd -V 2>&1")
  end
end
