{ lib, stdenv, fetchgit, cmake, elfutils, zlib, musl-obstack, argp-standalone }:

stdenv.mkDerivation rec {
  pname = "pahole";
  version = "1.22";
  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/devel/pahole/pahole.git";
    rev = "v${version}";
    sha256 = "sha256-U1/i9WNlLphPIcNysC476sqil/q9tMYmu+Y6psga8I0=";
    fetchSubmodules = true;
  };

  patches = [
    # fixes musl build
    # adapted from void: https://github.com/void-linux/void-packages/blob/master/srcpkgs/pahole/patches/fix_always_inline.patch
    ./fix_always_inline.patch
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    elfutils zlib
  ] ++ lib.optionals stdenv.targetPlatform.isMusl [
    musl-obstack argp-standalone
  ];

  # Put libraries in "lib" subdirectory, not top level of $out
  cmakeFlags = [ "-D__LIB=lib" ];

  meta = with lib; {
    homepage = "https://git.kernel.org/cgit/devel/pahole/pahole.git/";
    description = "Pahole and other DWARF utils";
    license = licenses.gpl2Only;

    platforms = platforms.linux;
    maintainers = [ maintainers.bosu ];
  };
}
