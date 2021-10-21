{ stdenv, yarnModulesConfig, mkYarnModulesFixed, server, sources, pin, nodejs, yarn, fetchYarnDeps }:
rec {
  modules = mkYarnModulesFixed rec {
    inherit (pin) version;
    pname = "peertube-tools-yarn-modules";
    name = "${pname}-${version}";
    packageJSON = "${sources}/server/tools/package.json";
    yarnLock = "${sources}/server/tools/yarn.lock";
    offlineCache = fetchYarnDeps {
      inherit yarnLock;
      sha256 = pin.toolsYarnHash;
    };
    pkgConfig = yarnModulesConfig;
  };
  dist = stdenv.mkDerivation {
    inherit (pin) version;
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
