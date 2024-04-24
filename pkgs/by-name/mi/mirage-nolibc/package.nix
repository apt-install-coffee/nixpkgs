{ crossLibcStdenv, fetchFromGitHub, buildPackages }:

crossLibcStdenv.mkDerivation (finalAttrs: {
  pname = "mirage-nolibc";
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "mirage";
    repo = "ocaml-solo5";
    rev = "v${finalAttrs.version}";
    hash = "sha256-l4ELMX5AxknXatXyYn91FYQb/kLIbeSGYoC3YZS1QS4=";
  };

  NIX_CFLAGS_COMPILE = "-I${buildPackages.buildPackages.solo5-toolchain-unwrapped}/include/solo5/";

  postPatch = ''
    substituteInPlace openlibm/Make.inc \
      --replace "AR = ar" ""
    substituteInPlace ./configure.sh \
      --replace "CC=cc" ""
    substituteInPlace nolibc/Makefile \
      --replace "-Werror" ""
  '';
  configureScript = "./configure.sh";
  dontAddStaticConfigureFlags = true;
  configurePlatforms = [ "target" ];

  makeFlags = [ "nolibc/libnolibc.a" "openlibm/libopenlibm.a" ];
  installPhase = ''
    mkdir -p $out/lib
    cp -r nolibc/include/ $out
    cp nolibc/libnolibc.a openlibm/libopenlibm.a $out/lib
  '';

})
