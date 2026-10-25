#include <stdio.h>
#include "suricata-plugin.h"

static void ShouldNotRun(void)
{
    puts("BAD_API_PLUGIN_INITIALIZER_EXECUTED");
}

static SCPlugin plugin = {
    .version = 0x0800,
    .suricata_version = "8.0-test",
    .name = "wrong-api-research",
    .plugin_version = "0.0.0",
    .license = "GPL-2.0-only",
    .author = "Research probe",
    .Init = ShouldNotRun,
};

__declspec(dllexport) SCPlugin *SCPluginRegister(void)
{
    return &plugin;
}
