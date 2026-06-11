#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if [ -z "${WASI_SYSROOT:-}" ]; then
    if [ -d "/opt/wasi-sdk/share/wasi-sysroot" ]; then
        WASI_SYSROOT="/opt/wasi-sdk/share/wasi-sysroot"
    elif command -v brew &>/dev/null && [ -d "$(brew --prefix wasi-libc)/share/wasi-sysroot" ]; then
        WASI_SYSROOT="$(brew --prefix wasi-libc)/share/wasi-sysroot"
    elif [ -n "${WASI_SDK_PATH:-}" ] && [ -d "$WASI_SDK_PATH/share/wasi-sysroot" ]; then
        WASI_SYSROOT="$WASI_SDK_PATH/share/wasi-sysroot"
    fi
fi

if [ -z "${WASI_SYSROOT:-}" ] || [ ! -d "$WASI_SYSROOT" ]; then
    echo "Error: WASI sysroot not found. Set WASI_SYSROOT env var." >&2
    echo "  macOS:   brew install wasi-libc" >&2
    echo "  Linux:   install wasi-sdk to /opt/wasi-sdk or set WASI_SDK_PATH" >&2
    exit 1
fi

echo "Generating C bindings..."
wit-bindgen c ../../wit --world plugin-world

echo "Compiling C bindings..."
clang --target=wasm32-wasip1 --sysroot="$WASI_SYSROOT" -O2 -c plugin_world.c -o plugin_world.o

echo "Compiling C++ guest..."
clang++ --target=wasm32-wasip1 --sysroot="$WASI_SYSROOT" -O2 -c guest.cpp -o guest.o

echo "Linking..."
clang++ --target=wasm32-wasip1 --sysroot="$WASI_SYSROOT" -O2 \
    -nostartfiles -nodefaultlibs \
    -Wl,--no-entry \
    -o plugin_raw.wasm \
    guest.o plugin_world.o plugin_world_component_type.o \
    "$WASI_SYSROOT/lib/wasm32-wasip1/libc.a"

echo "Creating component..."
wasm-tools component new plugin_raw.wasm -o plugin.wasm
rm -f plugin_raw.wasm plugin_world.o guest.o

echo "Done: plugin.wasm"
