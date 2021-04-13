{ stdenv, yarnModulesConfig, mkYarnModulesFixed, server, sources, version, nodejs, yarn }:
rec {
  modules = mkYarnModulesFixed rec {
    inherit version;
    pname = "peertube-tools-yarn-modules";
    name = "${pname}-${version}";
    packageJSON = "${sources}/server/tools/package.json";
    yarnLock = "${sources}/server/tools/yarn.lock";
    yarnNix = ./yarn/tools.nix;
    pkgConfig = yarnModulesConfig;
  };
  dist = stdenv.mkDerivation {
    inherit version;
    pname = "peertube-tools";
    src = sources;

    nativeBuildInputs = [ nodejs yarn ];

    postPatch = ''
      patchShebangs scripts
    '';

    buildPhase = ''
      ln -s ${server.modules}/node_modules .
      ln -s ${modules}/node_modules server/tools/
      npm run tsc -- --build ./server/tools/tsconfig.json
    '';

    installPhase = ''
      mkdir $out
      cp -a ./dist $out
    '';
  };
}
