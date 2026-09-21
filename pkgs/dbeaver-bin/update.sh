#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

latestVersion=$(curl "https://api.github.com/repos/dbeaver/dbeaver/tags" | jq -r '.[0].name')
currentVersion=$(nix-instantiate --eval -E "with import <nixpkgs> {}; dbeaver-bin.version" | tr -d '"')

echo "latest  version: $latestVersion"
echo "current version: $currentVersion"

if [[ "$latestVersion" == "$currentVersion" ]]; then
    echo "package is up-to-date"
    exit 0
fi

for i in \
    "x86_64-linux linux-x86_64.tar.gz"
do
    set -- $i
    prefetch=$(nix-prefetch-url "https://github.com/dbeaver/dbeaver/releases/download/$latestVersion/dbeaver-ce-$latestVersion-$2")
    hash=$(nix-hash --type sha256 --to-sri $prefetch)
    echo $hash

    #update-source-version dbeaver-bin $latestVersion $hash --system=$1
done
