import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _WxLinter();

class _WxLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const DisallowMaybeWhenMethod(),
  ];
}

class DisallowMaybeWhenMethod extends DartLintRule {
  const DisallowMaybeWhenMethod()
    : super(
        code: const LintCode(
          name: 'disallow_maybe_when',
          problemMessage: 'The maybeWhen(...) function is disallowed.',
          errorSeverity: error.DiagnosticSeverity.ERROR,
        ),
      );

  // @override
  // void run(
  //   CustomLintResolver resolver,
  //   DiagnosticReporter reporter,
  //   CustomLintContext context,
  // ) {
  // context.registry.addClassDeclaration((node) {
  //   final element = node.declaredFragment?.element;
  //   if (element == null) return;
  //   final className = node.name.lexeme;
  //   final hasPageInName = className.contains('Page');
  //   if (!hasPageInName) {
  //     reporter.atNode(node, code);
  //   }
  // });
  // }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // if (method.methodName.name != 'maybeWhen') {
      //   return;
      // }
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [];
}
