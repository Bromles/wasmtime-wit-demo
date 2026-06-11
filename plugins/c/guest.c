#include "plugin_world.h"

void exports_plugin_world_run(plugin_world_string_t *ret) {
    plugin_world_string_t name;
    plugin_world_string_set(&name, "C");
    my_plugin_host_api_greet(&name, ret);
}
