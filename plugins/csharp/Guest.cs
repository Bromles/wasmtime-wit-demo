namespace PluginWorldWorld;

public static class PluginWorldWorldImpl
{
    public static string Run()
    {
        return wit.imports.my.plugin.HostApiInterop.Greet("C#");
    }
}
