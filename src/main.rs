use anyhow::Result;
use my::plugin::host_api;
use wasmtime::component::{Component, HasSelf, Linker};
use wasmtime::{Config, Engine, Store};
use wasmtime_wasi::WasiCtxBuilder;

wasmtime::component::bindgen!({
    path: "wit",
    world: "plugin-world",
});

struct State {
    wasi: wasmtime_wasi::WasiCtx,
    table: wasmtime::component::ResourceTable,
}

impl wasmtime_wasi::WasiView for State {
    fn ctx(&mut self) -> wasmtime_wasi::WasiCtxView<'_> {
        wasmtime_wasi::WasiCtxView {
            ctx: &mut self.wasi,
            table: &mut self.table,
        }
    }
}

impl host_api::Host for State {
    fn greet(&mut self, name: String) -> String {
        format!("Hello, {}!", name)
    }
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        eprintln!("Usage: {} <plugin.wasm>", args[0]);
        std::process::exit(1);
    }

    let mut config = Config::new();
    config.wasm_component_model(true);
    let engine = Engine::new(&config)?;

    let wasi = WasiCtxBuilder::new().build();
    let table = wasmtime::component::ResourceTable::new();
    let mut store = Store::new(&engine, State { wasi, table });
    let mut linker = Linker::<State>::new(&engine);

    wasmtime_wasi::p2::add_to_linker_sync(&mut linker)?;
    PluginWorld::add_to_linker::<_, HasSelf<_>>(&mut linker, |state| state)?;

    let component = Component::from_file(&engine, &args[1])?;
    let instance = PluginWorld::instantiate(&mut store, &component, &linker)?;

    let result = instance.call_run(&mut store)?;
    println!("{}", result);

    Ok(())
}
