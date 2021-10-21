{ lib, stdenv, callPackage, fetchurl, fetchFromGitHub
, nodejs, jq, nodePackages, yarn2nix-moretea, youtube-dl
}:

/*
Updating json packages:
cd pkgs/servers/peertube
./update-yarn.sh
*/

let
  pin = builtins.fromJSON (builtins.readFile ./pin.json);

  source = fetchFromGitHub {
    owner = "Chocobozzz";
    repo = "PeerTube";
    rev = "v${pin.version}";
    sha256 = pin.sourceHash;
  };

  yarnModulesConfig = {
    bcrypt = {
      buildInputs = [ nodePackages.node-pre-gyp ];

      postInstall = let
        bcrypt_version = "5.0.1";
        bcrypt_lib = fetchurl {
          url = "https://github.com/kelektiv/node.bcrypt.js/releases/download/v${bcrypt_version}/bcrypt_lib-v${bcrypt_version}-napi-v3-linux-x64-glibc.tar.gz";
          sha256 = "3R3dBZyPansTuM77Nmm3f7BbTDkDdiT2HQIrti2Ottc=";
        };
      in ''
        if [ "${bcrypt_version}" != "$(cat package.json | ${jq}/bin/jq -r .version)" ]; then
          echo "Mismatching version please update bcrypt in derivation"
          exit
        fi
        mkdir -p ./lib/binding && tar -C ./lib/binding -xf ${bcrypt_lib}
        patchShebangs ../@mapbox/node-pre-gyp/bin/node-pre-gyp
        npm run install
      '';
    };

    utf-8-validate = {
      buildInputs = [ nodePackages.node-gyp-build ];
    };

    youtube-dl = {
      postInstall = ''
        mkdir bin
        ln -s ${youtube-dl}/bin/youtube-dl ./bin/youtube-dl
        cat > ./bin/details <<EOF
        {"version":"${youtube-dl.version}","path":null,"exec":"youtube-dl"}
        EOF
      '';
    };
  };

  mkYarnModulesFixed = args: (yarn2nix-moretea.mkYarnModules args).overrideAttrs(old: {
    # This hack permits to workaround the fact that the yarn.lock
    # file doesn't respect the semver requirements
    buildPhase = lib.replaceStrings [" ./package.json"] [" /dev/null; cp ./deps/*/package.json ."] old.buildPhase;
  });

  server = callPackage ./build-server.nix {
    inherit pin yarnModulesConfig mkYarnModulesFixed;
    sources = source;
  };

  tools = callPackage ./build-tools.nix {
    inherit server pin yarnModulesConfig mkYarnModulesFixed;
    sources = source;
  };

  client = callPackage ./build-client.nix {
    inherit server pin yarnModulesConfig mkYarnModulesFixed;
    sources = source;
  };

in stdenv.mkDerivation rec {
  inherit (pin) version;
  pname = "peertube";
  src = source;
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/{client/dist,dist/server/tools}
    cp -a $src/config $out/config
    cp -a $src/scripts $out/scripts
    cp -a $src/support $out/support
    cp $src/{CREDITS.md,FAQ.md,LICENSE,README.md,package.json,tsconfig.json,yarn.lock} $out
    ln -s ${server.modules}/node_modules $out/dist
    cp -a ${server.dist}/dist $out
    ln -s ${tools.modules}/node_modules $out/dist/server/tools
    cp -a ${tools.dist}/dist/server/tools $out/dist/server
    ln -s ${client.modules}/node_modules $out/client
    cp -a ${client.dist}/dist $out/client
    cp $src/client/{package.json,yarn.lock} $out/client
  '';

  meta = with lib; {
    description = "A free software to take back control of your videos";
    longDescription = ''
      PeerTube aspires to be a decentralized and free/libre alternative to video
      broadcasting services.
      PeerTube is not meant to become a huge platform that would centralize
      videos from all around the world. Rather, it is a network of
      inter-connected small videos hosters.
      Anyone with a modicum of technical skills can host a PeerTube server, aka
      an instance. Each instance hosts its users and their videos. In this way,
      every instance is created, moderated and maintained independently by
      various administrators.
      You can still watch from your account videos hosted by other instances
      though if the administrator of your instance had previously connected it
      with other instances.
    '';
    license = licenses.agpl3Plus;
    homepage = "https://joinpeertube.org/";
    platforms = platforms.unix;
    maintainers = with maintainers; [ immae stevenroose ];
  };
}
