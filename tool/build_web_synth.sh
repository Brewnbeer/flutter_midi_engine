#!/usr/bin/env bash
# Rebuilds the web synthesizer files in assets/web from SpessaSynth
# (https://github.com/spessasus/spessasynth_lib, Apache-2.0).
#
#   tool/build_web_synth.sh            # uses the versions below
#
# spessasynth_lib.min.js       = spessasynth_lib + spessasynth_core, one ES module
# spessasynth_processor.min.js = the AudioWorklet processor (already self-contained)
set -euo pipefail

LIB_VERSION=4.4.6
CORE_VERSION=4.4.8   # the core release that shipped alongside LIB_VERSION
ESBUILD_VERSION=0.25.10

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/web"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
cat > package.json <<JSON
{ "name": "fme-web-bundle", "private": true, "type": "module",
  "dependencies": { "spessasynth_lib": "$LIB_VERSION", "spessasynth_core": "$CORE_VERSION" },
  "overrides": { "spessasynth_core": "$CORE_VERSION" },
  "devDependencies": { "esbuild": "$ESBUILD_VERSION" } }
JSON
echo 'export { WorkletSynthesizer } from "spessasynth_lib";' > entry.js
npm install --ignore-scripts --no-audit --no-fund

mkdir -p "$OUT"
node node_modules/esbuild/bin/esbuild entry.js --bundle --format=esm --minify \
  --legal-comments=none --outfile="$OUT/spessasynth_lib.min.js"
# Drop the source map reference; the .map file is not shipped.
sed '/^\/\/# sourceMappingURL=/d' node_modules/spessasynth_lib/dist/spessasynth_processor.min.js \
  > "$OUT/spessasynth_processor.min.js"
cp node_modules/spessasynth_lib/LICENSE "$OUT/SPESSASYNTH_LICENSE"

echo "Done: $OUT"
