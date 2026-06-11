#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

rm -rf bin obj

echo "Building C# component..."
docker run --rm --platform linux/amd64 \
  -v "$(pwd)/../..":/work \
  -w /work/plugins/csharp \
  mcr.microsoft.com/dotnet/sdk:10.0-preview \
  bash -c "dotnet restore Plugin.csproj -r linux-x64 && dotnet restore Plugin.csproj -r wasi-wasm && dotnet build Plugin.csproj -c Release --no-restore"

cp bin/Release/net10.0/wasi-wasm/publish/Plugin.wasm plugin.wasm

echo "Done: plugin.wasm"
