{ lib, stdenv, fetchurl, pkg-config, libseccomp, util-linux, qemu, coreutils
, writeShellScriptBin
, pkgsHostHost
, pkgsHostTarget
, pkgsBuildTarget
, enableToolchain ? stdenv.targetPlatform.isSolo5
}:

let
  version = "0.8.1";

  hostTargetBintools = pkgsHostTarget.bintools;

  # gcc is theoretical, since we can't compile it with libc == null atm
  hostTargetCC =
    if stdenv.targetPlatform.useLLVM or false
    then pkgsHostTarget.llvmPackages.clang-unwrapped
    else pkgsHostTarget.gcc-unwrapped;

  unwrappedCompiler =
    /**/ if hostTargetCC.isClang or false then "clang"
    else if hostTargetCC.isGNU or false then "${targetPrefix}gcc"
    else "${targetPrefix}cc";

  # build->target uses wrapped ones, so stuff compiles properly
  buildTargetCC =
    if stdenv.targetPlatform.useLLVM or false
    then pkgsBuildTarget.llvmPackages.clangNoLibcxx
    else pkgsBuildTarget.gcc;

  targetPrefix = "${stdenv.targetPlatform.config}-";
in

if !(enableToolchain -> (with stdenv.targetPlatform; isx86_64 || isAarch64))
then throw "solo5 only supports aarch64 and x86_64 as targets"
else

stdenv.mkDerivation {
  pname =
    lib.optionalString enableToolchain targetPrefix
    + "solo5"
    + lib.optionalString (!enableToolchain) "-tools";
  inherit version;

  depsBuildTarget = [ buildTargetCC ];
  nativeBuildInputs = [ pkg-config ];
  buildInputs = lib.optional (stdenv.hostPlatform.isLinux) libseccomp;

  src = fetchurl {
    url = "https://github.com/Solo5/solo5/releases/download/v${version}/solo5-v${version}.tar.gz";
    sha256 = "sha256-J1xcL/AdcLQ7Ph3TFwEaS9l4cWjDQsTaXTdBDcT7p6E=";
  };

  hardeningEnable = [ "pie" ];
  # -fPIC is passed after -fPIE and removes the __PIE__ CPP macro, stopping
  # configure.sh from detecting PIE support.
  hardeningDisable = [ "pic" ];

  preConfigure = ''
    export HOST_CC=$CC
    export HOST_AR=$AR
    export HOST_PKG_CONFIG=$PKG_CONFIG

    makeFlagsArray+=(
      "SUBDIRS=elftool bindings tenders toolchain"
    )
  ''
  + lib.optionalString enableToolchain ''
    export TARGET_CC=$(command -v $CC_FOR_TARGET)
    export TARGET_LD=$(command -v $LD_FOR_TARGET)
    export TARGET_OBJCOPY=$(command -v $OBJCOPY_FOR_TARGET)
  '';

  configureScript = "./configure.sh";
  configurePlatforms = [ ]; # configure.sh doesn't know about these flags
  configureFlags = lib.optionals (!enableToolchain) [ "--disable-toolchain" ];

  makeFlags = [
    "HOSTAR=$(HOST_AR)" # TODO patch in HOST_AR for configure.sh
    #"V=1"
  ];

  enableParallelBuilding = false; # TODO

  doCheck = enableToolchain
    && stdenv.hostPlatform.isLinux
    && !stdenv.hostPlatform.isAarch64
    && false;
  checkInputs = [ util-linux qemu ];
  checkPhase = ''
    runHook preCheck
    make $makeFlags tests
    patchShebangs tests
    ./tests/bats-core/bats ./tests/tests.bats
    runHook postCheck
  '';

      #sed -i '2i export PATH=${
      #  lib.makeBinPath [ hostTargetCC hostTargetBintools coreutils ]
      #}' "$toolPath"
  postInstall = ''
    ls $out/bin
    for tool in cc ld objcopy; do
      toolPath="$out/bin/${stdenv.targetPlatform.parsed.cpu.name}-solo5-none-static-$tool"

      substituteInPlace "$toolPath" \
        --replace "exec $CC_FOR_TARGET" "exec ${hostTargetCC}/bin/${unwrappedCompiler}"

      ln -s "$toolPath" "$out/bin/${targetPrefix}$tool"
    done

    ln -sL "$out/bin/${targetPrefix}cc" "$out/bin/${unwrappedCompiler}"
  '' + lib.optionalString (stdenv.hostPlatform != stdenv.targetPlatform) ''
    cp -r ${pkgsHostHost.solo5-toolchain-unwrapped}/include/${stdenv.hostPlatform.parsed.cpu.name}-solo5-none-static/* $out/include/${stdenv.targetPlatform.parsed.cpu.name}-solo5-none-static
  '';

  passthru = {
    isClang = hostTargetCC.isClang or false;
    isGNU = hostTargetCC.isGNU or false;

    bintools = hostTargetBintools;

    inherit targetPrefix;
  };

  meta = with lib; {
    description = "Sandboxed execution environment";
    homepage = "https://github.com/solo5/solo5";
    license = licenses.isc;
    maintainers = [ maintainers.ehmry ];
    platforms = platforms.freebsd ++ platforms.linux ++ platforms.openbsd;
  };
}
