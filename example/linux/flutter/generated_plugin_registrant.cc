//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <media_meta_plus/media_meta_plus_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) media_meta_plus_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaMetaPlusPlugin");
  media_meta_plus_plugin_register_with_registrar(media_meta_plus_registrar);
}
