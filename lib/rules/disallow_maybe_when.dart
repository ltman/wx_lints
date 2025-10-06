import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowMaybeWhen extends DartLintRule {
  const DisallowMaybeWhen()
    : super(
        code: const LintCode(
          name: 'disallow_maybe_when',
          problemMessage: 'Usage of the maybeWhen(...) method is not allowed.',
          errorSeverity: error.DiagnosticSeverity.WARNING,
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
      if (className == null ||
           !className.startsWith(r'Fragment$') &&
           !className.startsWith(r'Query$') &&
           !className.startsWith(r'Mutation$')) {
        return;
      }
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_MaybeWhenFix()];
}

class _MaybeWhenFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((MethodInvocation node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use when(...) instead',
        priority: 100,
      );

      changeBuilder.addDartFileEdit((DartFileEditBuilder builder) {
        final SourceRange sourceRange = node.methodName.sourceRange;
        builder.addSimpleReplacement(sourceRange, 'when');
      });
    });
  }
}
