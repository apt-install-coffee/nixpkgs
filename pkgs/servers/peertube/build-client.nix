{ lib, stdenv, yarnModulesConfig, mkYarnModulesFixed, buildGoModule, fetchFromGitHub, server, sources, version, nodejs, esbuild }:
rec {
  modules = mkYarnModulesFixed rec {
    inherit version;
    pname = "peertube-client-yarn-modules";
    name = "${pname}-${version}";
    packageJSON = "${sources}/client/package.json";
    yarnLock = "${sources}/client/yarn.lock";
    yarnNix = ./yarn/client.nix;
    pkgConfig = yarnModulesConfig;
  };
  dist = let
    esbuild_locked = buildGoModule rec {
      pname = "esbuild";
      version = "0.12.17";

      src = fetchFromGitHub {
        owner = "evanw";
        repo = "esbuild";
        rev = "v${version}";
        sha256 = "sha256-wZOBjNOgGmwIQNCrhzwGPmI/fW/yZiDqq8l4oSDTvZs=";
      };
      vendorSha256 = "sha256-2ABWPqhK2Cf4ipQH7XvRrd+ZscJhYPc3SV2cGT0apdg=";
    };
  in stdenv.mkDerivation {
    inherit version;
    pname = "peertube-client";
    src = sources;

    nativeBuildInputs = [ nodejs ];

    postPatch = ''
      patchShebangs scripts
    '';

    buildPhase = ''
      export ESBUILD_BINARY_PATH="${esbuild_locked}/bin/esbuild"
      ln -s ${server.modules}/node_modules .
      cp -a ${modules}/node_modules client
      chmod -R +w ./client/node_modules
      npm run build:client
    '';

    installPhase = ''
      mkdir $out
      cp -a ./client/dist $out
    '';
  };
}
