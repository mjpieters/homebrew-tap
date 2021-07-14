class Keyboardswitcher < Formula
  desc ""
  homepage ""
  url "https://github.com/Lutzifer/keyboardSwitcher/archive/1.0.2.tar.gz"
  version "1.0.2"
  sha256 "25ebbe0a2c57fad9ce37b1dfbde2f9b612b3f72af87002ddb17903b396adb1d9"

  def install
   xcodebuild
   bin.install("build/release/keyboardSwitcher")
  end

  test do
    system "keyboardSwitcher"
  end
end
