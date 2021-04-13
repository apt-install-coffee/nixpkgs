#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=../../../ -i bash -p jq yarn2nix

set -euo pipefail

version=$(curl --silent https://api.github.com/repos/Chocobozzz/PeerTube/releases/latest | jq -r '.tag_name')
PEERTUBE_WEB_SRC="https://raw.githubusercontent.com/Chocobozzz/PeerTube/$version"

echo Running update json packages

echo Update json packages for peertube-client module
curl --silent "$PEERTUBE_WEB_SRC/client/yarn.lock" -o ./yarn/tmp-client.lock
yarn2nix --lockfile=./yarn/tmp-client.lock > ./yarn/client.nix
rm ./yarn/tmp-client.lock

echo Update json packages for peertube-server module
curl --silent "$PEERTUBE_WEB_SRC/yarn.lock" -o ./yarn/tmp-server.lock
yarn2nix --lockfile=./yarn/tmp-server.lock > ./yarn/server.nix
rm ./yarn/tmp-server.lock

echo Update json packages for peertube-tools module
curl --silent "$PEERTUBE_WEB_SRC/server/tools/yarn.lock" -o ./yarn/tmp-tools.lock
yarn2nix --lockfile=./yarn/tmp-tools.lock > ./yarn/tools.nix
rm ./yarn/tmp-tools.lock

echo Update json packages completed
