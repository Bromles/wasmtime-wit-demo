const String = extern struct {
    ptr: [*]u8,
    len: usize,
};

extern fn my_plugin_host_api_greet(name: *String, ret: *String) void;
extern fn plugin_world_string_set(ret: *String, s: [*:0]const u8) void;

export fn exports_plugin_world_run(ret: *String) void {
    var name: String = undefined;
    plugin_world_string_set(&name, "Zig");
    my_plugin_host_api_greet(&name, ret);
}
