# wasmtime-wit-demo

A demo showing how to compile some languages to [Wasm components](https://component-model.bytecodealliance.org/) and run
them via a shared [WIT](https://component-model.bytecodealliance.org/design/wit.html) interface
using [Wasmtime](https://wasmtime.dev/).

## Interface

[`wit/plugin.wit`](wit/plugin.wit) defines the contract:

- **Import** `host-api.greet(name: string) -> string` — the host provides this
- **Export** `run() -> string` — each guest implements this

Each guest calls `greet("LangName")` and returns the result through the host.

## Running

```sh
cargo run -- plugins/<lang>/plugin.wasm
```

## Languages

| Language   | Build        | Toolchain                         |
|------------|--------------|-----------------------------------|
| C          | `./build.sh` | wasi-libc + wit-bindgen           |
| C++        | `./build.sh` | wasi-libc + wit-bindgen           |
| Go         | `./build.sh` | `GOOS=wasip1` + reactor adapter   |
| JavaScript | `./build.sh` | `jco componentize`                |
| Python     | `./build.sh` | `componentize-py`                 |
| Zig        | `./build.sh` | `zig cc` + reactor adapter        |
| C#         | `./build.sh` | `componentize-dotnet` (Docker)    |
| Rust       | `./build.sh` | `wasm32-wasip2`                   |
| Nelua      | `./build.sh` | Nelua → C → clang                 |
| Nim        | `./build.sh` | Nim → C → clang + reactor adapter |

## License

Licensed under either of Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0) or MIT
license (http://opensource.org/licenses/MIT), at your option.
