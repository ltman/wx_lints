import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wx_lints/src/asset_gen_image_utils.dart';

class DisallowTintableImageNoTint extends DartLintRule {
  const DisallowTintableImageNoTint()
    : super(
        code: const LintCode(
          name: 'disallow_tintable_image_no_tint',
          problemMessage:
              'Tintable assets must not use imageNoTint(); use imageTint() instead.',
          errorSeverity: DiagnosticSeverity.WARNING,
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
      if (element == null || element.name != 'imageNoTint') {
        return;
      }
      if (!isAssetGenImageExtensionMember(element)) {
        return;
      }
      if (!assetChainContainsSegment(node.target, 'tintable')) {
        return;
      }
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_ImageNoTintFix()];
}

class _ImageNoTintFix extends DartFix {
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
        message: 'Use imageTint() instead',
        priority: 100,
      );

      changeBuilder.addDartFileEdit((DartFileEditBuilder builder) {
        final SourceRange sourceRange = node.methodName.sourceRange;
        builder.addSimpleReplacement(sourceRange, 'imageTint');
      });
    });
  }
}
