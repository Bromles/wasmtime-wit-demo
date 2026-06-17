package main

String :: struct {
	ptr: [^]u8,
	len: uint,
}

@(default_calling_convention = "c")
foreign {
	my_plugin_host_api_greet :: proc(name: ^String, ret: ^String) ---
	plugin_world_string_set :: proc(ret: ^String, s: cstring) ---
}

@(export, link_name = "exports_plugin_world_run")
exports_plugin_world_run :: proc "c" (ret: ^String) {
	name: String
	plugin_world_string_set(&name, "Odin")
	my_plugin_host_api_greet(&name, ret)
}
