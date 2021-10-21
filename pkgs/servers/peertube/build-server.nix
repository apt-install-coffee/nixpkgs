{ stdenv, yarnModulesConfig, mkYarnModulesFixed, sources, pin, nodejs, fetchYarnDeps }:
rec {
  modules = mkYarnModulesFixed rec {
    inherit (pin) version;
    pname = "peertube-server-yarn-modules";
    name = "${pname}-${pin.version}";
    packageJSON = "${sources}/package.json";
    yarnLock = "${sources}/yarn.lock";
    offlineCache = fetchYarnDeps {
      inherit yarnLock;
      sha256 = pin.serverYarnHash;
    };
    pkgConfig = yarnModulesConfig;
  };
  dist = stdenv.mkDerivation {
    inherit (pin) version;
    pname = "peertube-server";
    src = sources;

    nativeBuildInputs = [ nodejs ];

    postPatch = ''
      patchShebangs scripts
    '';

    buildPhase = ''
      ln -s ${modules}/node_modules .
      npm run build:server
    '';

    installPhase = ''
      mkdir $out
      cp -a ./dist $out
    '';
  };
}
