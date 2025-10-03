import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:wx_lints/rules/disallow_maybe_when.dart';

PluginBase createPlugin() => _WxLinter();

class _WxLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const DisallowMaybeWhen(),
  ];
}
