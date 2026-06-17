#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# --- toolchain checks -------------------------------------------------------
if ! command -v odin &>/dev/null; then
    echo "Error: 'odin' not found in PATH (https://odin-lang.org)." >&2
    exit 1
fi

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

# --- WASI reactor adapter (Odin's runtime imports wasi_snapshot_preview1) ----
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

# --- build ------------------------------------------------------------------
echo "Generating C bindings..."
wit-bindgen c ../../wit --world plugin-world

echo "Compiling Odin guest to wasm object..."
odin build guest.odin -target:wasi_wasm32 -build-mode:obj -out:guest -o:speed -file

echo "Compiling C glue..."
clang --target=wasm32-wasip1 --sysroot="$WASI_SYSROOT" -O2 -c plugin_world.c -o plugin_world.o

echo "Linking to WebAssembly..."
clang --target=wasm32-wasip1 --sysroot="$WASI_SYSROOT" -O2 -nostartfiles -nodefaultlibs -Wl,--no-entry \
    -o plugin_raw.wasm \
    guest.wasm plugin_world.o plugin_world_component_type.o \
    "$WASI_SYSROOT/lib/wasm32-wasip1/libc.a"

echo "Creating component..."
wasm-tools component new plugin_raw.wasm -o plugin.wasm --adapt "$WASI_REACTOR"
rm -f plugin_raw.wasm guest.wasm plugin_world.o

echo "Done: plugin.wasm"
