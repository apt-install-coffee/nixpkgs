{ stdenv, yarnModulesConfig, mkYarnModulesFixed, sources, version, nodejs }:
rec {
  modules = mkYarnModulesFixed rec {
    inherit version;
    pname = "peertube-server-yarn-modules";
    name = "${pname}-${version}";
    packageJSON = "${sources}/package.json";
    yarnLock = "${sources}/yarn.lock";
    yarnNix = ./yarn/server.nix;
    pkgConfig = yarnModulesConfig;
  };
  dist = stdenv.mkDerivation {
    inherit version;
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
