use crate::my::plugin::host_api;

wit_bindgen::generate!({
    world: "plugin-world",
    path: "../../wit",
});

struct Component;

impl Guest for Component {
    fn run() -> String {
        host_api::greet("Rust")
    }
}

export!(Component);
