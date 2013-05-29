require 'formula'

class DbusPython < Formula
  homepage 'http://dbus.freedesktop.org/doc/dbus-python/'
  url 'http://dbus.freedesktop.org/releases/dbus-python/dbus-python-1.2.0.tar.gz'
  sha1 '7a00f7861d26683ab7e3f4418860bd426deed9b5'

  depends_on :x11
  depends_on 'pkg-config' => :build
  depends_on 'd-bus'
  depends_on 'dbus-glib'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make install"
  end

  def test
    system "python -c 'import dbus'"
  end
end
