#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Rust component..."
cargo build --target wasm32-wasip2 --release

cp target/wasm32-wasip2/release/plugin_rust.wasm plugin.wasm

echo "Done: plugin.wasm"
