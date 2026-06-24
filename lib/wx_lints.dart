import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:wx_lints/rules/disallow_asset_gen_image.dart';
import 'package:wx_lints/rules/disallow_maybe_when.dart';
import 'package:wx_lints/rules/prefer_lowercase_hex_color.dart';

PluginBase createPlugin() => _WxLinter();

class _WxLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const DisallowMaybeWhen(),
    const PreferLowercaseHexColor(),
    const DisallowAssetGenImage(),
  ];
}
