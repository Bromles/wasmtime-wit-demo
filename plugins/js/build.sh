#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building TypeScript plugin..."
npx --yes @bytecodealliance/jco componentize guest.js \
    -w ../../wit \
    -n plugin-world \
    -o plugin.wasm \
    --disable all

echo "Done: plugin.wasm"
