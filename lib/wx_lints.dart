import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:wx_lints/rules/disallow_direct_asset_image.dart';
import 'package:wx_lints/rules/disallow_image_in_wx_button_v2.dart';
import 'package:wx_lints/rules/disallow_maybe_when.dart';
import 'package:wx_lints/rules/disallow_static_image_tint.dart';
import 'package:wx_lints/rules/disallow_tintable_image_no_tint.dart';
import 'package:wx_lints/rules/prefer_lowercase_hex_color.dart';

PluginBase createPlugin() => _WxLinter();

class _WxLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const DisallowMaybeWhen(),
    const PreferLowercaseHexColor(),
    const DisallowImageInWxButtonV2(),
    const DisallowStaticImageTint(),
    const DisallowTintableImageNoTint(),
    const DisallowDirectAssetImage(),
  ];
}
