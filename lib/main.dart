import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:wx_lints/src/rules/disallow_direct_asset_image.dart';
import 'package:wx_lints/src/rules/disallow_maybe_when.dart';
import 'package:wx_lints/src/rules/disallow_static_image_tint.dart';
import 'package:wx_lints/src/rules/disallow_tintable_image_no_tint.dart';
import 'package:wx_lints/src/rules/prefer_lowercase_hex_color.dart';

/// The entry point that the Dart Analysis Server looks for.
final plugin = WxLintsPlugin();

class WxLintsPlugin extends Plugin {
  @override
  String get name => 'wx_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(DisallowMaybeWhen());
    registry.registerWarningRule(PreferLowercaseHexColor());
    registry.registerWarningRule(DisallowStaticImageTint());
    registry.registerWarningRule(DisallowTintableImageNoTint());
    registry.registerWarningRule(DisallowDirectAssetImage());

    registry.registerFixForRule(
      DisallowMaybeWhen.code,
      ReplaceMaybeWhenWithWhen.new,
    );
    registry.registerFixForRule(
      PreferLowercaseHexColor.code,
      LowercaseHexColor.new,
    );
    registry.registerFixForRule(
      DisallowStaticImageTint.code,
      ReplaceImageTintWithImageNoTint.new,
    );
    registry.registerFixForRule(
      DisallowTintableImageNoTint.code,
      ReplaceImageNoTintWithImageTint.new,
    );
    registry.registerFixForRule(
      DisallowDirectAssetImage.code,
      ReplaceDirectImageCall.new,
    );
  }
}
