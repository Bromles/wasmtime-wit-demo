#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Python plugin..."
uvx componentize-py -d ../../wit -w plugin-world componentize guest -o plugin.wasm --stub-wasi

echo "Done: plugin.wasm"
