import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowMaybeWhen extends DartLintRule {
  const DisallowMaybeWhen()
    : super(
        code: const LintCode(
          name: 'disallow_maybe_when',
          problemMessage: 'Usage of the maybeWhen(...) method is not allowed.',
          errorSeverity: error.DiagnosticSeverity.ERROR,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((MethodInvocation node) {
      final Element? element = node.methodName.element;
      if (element == null || element.name != 'maybeWhen') {
        return;
      }
      final enclosing = element.enclosingElement;
      if (!(enclosing is ExtensionElement)) {
        return;
      }
      final className = enclosing.extendedType.element?.name;
      if (className == null || !className.startsWith('Fragment\$')) {
        return;
      }
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [];
}
