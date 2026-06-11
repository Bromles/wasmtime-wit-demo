type
  PluginWorldString {.importc: "plugin_world_string_t", header: "plugin_world.h", bycopy.} = object
    p: pointer
    len: csize_t

proc greet(name, ret: ptr PluginWorldString) {.
  importc: "my_plugin_host_api_greet", header: "plugin_world.h".}

proc stringSet(ret: ptr PluginWorldString; s: cstring) {.
  importc: "plugin_world_string_set", header: "plugin_world.h".}

proc exports_plugin_world_run(ret: ptr PluginWorldString) {.exportc.} =
  var name: PluginWorldString
  stringSet(addr name, "Nim")
  greet(addr name, ret)
