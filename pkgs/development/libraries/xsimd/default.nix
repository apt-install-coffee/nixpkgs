{ lib
, stdenv
, fetchFromGitHub
, cmake
, doctest
}:

stdenv.mkDerivation rec {
  pname = "xsimd";
  version = "11.1.0";
  src = fetchFromGitHub {
    owner = "xtensor-stack";
    repo = "xsimd";
    rev = version;
    sha256 = "sha256-l6IRzndjb95hIcFCCm8zmlNHWtKduqy2t/oml/9Xp+w=";
  };
  patches = [
    # Ideally, Accelerate/Accelerate.h should be used for this implementation,
    # but it doesn't work... Needs a Darwin user to debug this. We apply this
    # patch unconditionally, because the #if macros make sure it doesn't
    # interfer with the Linux implementations.
    ./fix-darwin-exp10-implementation.patch
  ] ++ lib.optionals stdenv.isDarwin [
    # Upstream reports:
    # https://github.com/xtensor-stack/xsimd/issues/807
    # https://github.com/xtensor-stack/xsimd/issues/917
    ./disable-darwin-failing-tests.patch

  ] ++ lib.optionals stdenv.hostPlatform.isMusl [
    # https://github.com/xtensor-stack/xsimd/issues/798
    ./disable-musl-failing-tests.patch
  ];

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-DBUILD_TESTS=${if (doCheck && stdenv.hostPlatform == stdenv.buildPlatform) then "ON" else "OFF"}"
  ];

  doCheck = true;
  nativeCheckInputs = [
    doctest
  ];
  checkTarget = "xtest";

  meta = with lib; {
    description = "C++ wrappers for SIMD intrinsics";
    homepage = "https://github.com/xtensor-stack/xsimd";
    license = licenses.bsd3;
    maintainers = with maintainers; [ tobim ];
    platforms = platforms.all;
  };
}
