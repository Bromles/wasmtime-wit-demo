package export_wit_world

import "wit_component/my_plugin_host_api"

func Run() string {
	return my_plugin_host_api.Greet("Go")
}
