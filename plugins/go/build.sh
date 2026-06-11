#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

REACTOR_CACHE="$HOME/.cache/wasm-component-tools/wasi_snapshot_preview1.reactor.wasm"

find_reactor() {
    if [ -n "${WASI_REACTOR:-}" ] && [ -f "$WASI_REACTOR" ]; then
        echo "$WASI_REACTOR"
        return
    fi
    if [ -f "$REACTOR_CACHE" ]; then
        echo "$REACTOR_CACHE"
        return
    fi
    find "$HOME/.npm" -path '*/jco/lib/wasi_snapshot_preview1.reactor.wasm' -print -quit 2>/dev/null && return
    find /usr -name 'wasi_snapshot_preview1.reactor.wasm' -print -quit 2>/dev/null && return
    find "$HOME" -maxdepth 5 -path '*/node_modules/*/wasi_snapshot_preview1.reactor.wasm' -print -quit 2>/dev/null && return
}

WASI_REACTOR=$(find_reactor)

if [ -z "$WASI_REACTOR" ]; then
    echo "Downloading WASI reactor adapter..."
    mkdir -p "$(dirname "$REACTOR_CACHE")"
    curl -fsSL -o "$REACTOR_CACHE" \
        "https://github.com/bytecodealliance/wasmtime/releases/download/v29.0.0/wasi_snapshot_preview1.reactor.wasm"
    WASI_REACTOR="$REACTOR_CACHE"
fi

echo "Generating Go bindings..."
rm -f core.wasm embedded.wasm
wit-bindgen go ../../wit --world plugin-world --out-dir .
mkdir -p export_wit_world
go mod tidy

echo "Compiling to WebAssembly..."
GOARCH=wasm GOOS=wasip1 go build -buildmode=c-shared -ldflags=-checklinkname=0 -o core.wasm .

echo "Creating component..."
wasm-tools component embed -w plugin-world ../../wit core.wasm -o embedded.wasm
wasm-tools component new embedded.wasm -o plugin.wasm --adapt "$WASI_REACTOR"
rm -f core.wasm embedded.wasm

echo "Done: plugin.wasm"
