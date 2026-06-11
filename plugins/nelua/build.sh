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
    exit 1
fi

CC="clang --target=wasm32-wasip1 --sysroot=$WASI_SYSROOT"

echo "Generating C bindings..."
wit-bindgen c ../../wit --world plugin-world

echo "Generating Nelua C code..."
nelua --no-cache guest.nelua --output guest.c

echo "Patching for wasm32 target..."
sed -i.bak \
    -e 's/NELUA_STATIC_ASSERT(sizeof(void\*) == 8 && NELUA_ALIGNOF(void\*) == 8, "[^"]*")/;/g' \
    -e 's/NELUA_STATIC_ASSERT(sizeof(nluint8_arr16) == 16 && NELUA_ALIGNOF(nluint8_arr16) == 1, "[^"]*")/;/g' \
    guest.c
rm -f guest.c.bak

echo "Compiling to WebAssembly..."
$CC -O2 -c guest.c -o guest.o -DNELUA_STATIC_ASSERT\(X,Y\)=
$CC -O2 -c plugin_world.c -o plugin_world.o
$CC -O2 -nostartfiles -nodefaultlibs -Wl,--no-entry \
    -o plugin_raw.wasm \
    guest.o plugin_world.o plugin_world_component_type.o \
    "$WASI_SYSROOT/lib/wasm32-wasip1/libc.a"

echo "Creating component..."
wasm-tools component new plugin_raw.wasm -o plugin.wasm
rm -f plugin_raw.wasm guest.o plugin_world.o guest.c

echo "Done: plugin.wasm"
