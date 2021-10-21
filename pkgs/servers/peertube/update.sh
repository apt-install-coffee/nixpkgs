#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=../../../ -i bash -p jq prefetch-yarn-deps nix-prefetch-github

version="$1"

set -euo pipefail

if [ -z "$version" ]; then
  version=$(curl --silent https://api.github.com/repos/Chocobozzz/PeerTube/releases/latest | jq -r '.tag_name')
fi

# strip leading "v"
version="${version#v}"

PEERTUBE_WEB_SRC="https://raw.githubusercontent.com/Chocobozzz/PeerTube/v$version"

echo "Running nix-prefetch-github"
source_hash=$(nix-prefetch-github Chocobozzz PeerTube --rev v$version 2>/dev/null | jq -r .sha256)

echo "Running prefetch-yarn-deps"

echo "for peertube-client module..."
curl --silent "$PEERTUBE_WEB_SRC/client/yarn.lock" -o tmp-client.lock
client_yarn_hash=$(prefetch-yarn-deps tmp-client.lock)
rm tmp-client.lock

echo "for peertube-server module..."
curl --silent "$PEERTUBE_WEB_SRC/yarn.lock" -o tmp-server.lock
server_yarn_hash=$(prefetch-yarn-deps tmp-server.lock)
rm tmp-server.lock

echo "for peertube-tools module..."
curl --silent "$PEERTUBE_WEB_SRC/server/tools/yarn.lock" -o tmp-tools.lock
tools_yarn_hash=$(prefetch-yarn-deps tmp-tools.lock)
rm tmp-tools.lock

echo "prefetch-yarn-deps completed"

cat > pin.json << EOF
{
  "version": "$version",
  "sourceHash": "$source_hash",
  "clientYarnHash": "$client_yarn_hash",
  "serverYarnHash": "$server_yarn_hash",
  "toolsYarnHash": "$tools_yarn_hash"
}
EOF
echo "Wrote pin.json"
