#!/bin/sh
# Checks the packaged release zip in .release/: the addon files are there under BuyEmAll/, and the dev-only files
# .pkgmeta ignores are not. Shared by the CI, release and pre-release workflows.
set -eu

zip=$(ls .release/*.zip)
listing=$(unzip -l "$zip")
echo "$listing"

for f in BuyEmAll.toc BuyEmAll.lua BuyEmAll.xml Calc.lua init.lua LICENSE localisation/index.xml localisation/enUS.lua; do
  echo "$listing" | grep -q "BuyEmAll/$f" || { echo "missing BuyEmAll/$f" >&2; exit 1; }
done

# A bare `!` here would be exempt from set -e and silently not fail.
for f in .github/ .luacheckrc tests/ CHANGELOG.md; do
  if echo "$listing" | grep -q "BuyEmAll/$f"; then
    echo "BuyEmAll/$f should not ship in the release archive (see .pkgmeta)" >&2
    exit 1
  fi
done
