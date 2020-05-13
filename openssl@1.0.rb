# This formula tracks 1.0.2 branch of OpenSSL, not the 1.1.0 branch.
# It was removed from homebrew-core in November 2019, see
# https://github.com/Homebrew/homebrew-core/pull/46876
# because OpenSSL 1.0.x reached EOL on 2019-12-31
# This formula is only there to support legacy software that can't be made to
# work with newer versions.
class OpensslAT10 < Formula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.0.2t.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.0.2t.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.0.2t.tar.gz"
  sha256 "14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc"

  keg_only :shadowed_by_macos, "macOS provides LibreSSL"

  def configure_args
    %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      no-ssl3
      no-zlib
      shared
      enable-cms
    ]
  end

  def install
    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = Formula["perl"].opt_bin/"perl" if which("perl") == Formula["perl"].opt_bin/"perl"

    arch_args = %w[darwin64-x86_64-cc enable-ec_nistp_64_gcc_128]

    ENV.deparallelize
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make", "depend"
    system "make"
    system "make", "test"
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
  end

  def openssldir
    etc/"openssl@1.0"
  end

  def post_install
    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(
      /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m,
    )

    valid_certs = certs.select do |cert|
      IO.popen("#{bin}/openssl x509 -inform pem -checkend 0 -noout >/dev/null", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    openssldir.mkpath
    (openssldir/"cert.pem").atomic_write(valid_certs.join("\n") << "\n")
  end

  def caveats
    <<~EOS
      A CA file has been bootstrapped using certificates from the system
      keychain. To add additional certificates, place .pem files in
      #{openssldir}/certs

    and run
      #{opt_bin}/c_rehash
  EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_predicate pkgetc/"openssl.cnf", :exist?,
            "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
