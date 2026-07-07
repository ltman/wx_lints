import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wx_lints/src/asset_gen_image_utils.dart';

class DisallowDirectAssetImage extends DartLintRule {
  const DisallowDirectAssetImage()
    : super(
        code: const LintCode(
          name: 'disallow_direct_asset_image',
          problemMessage:
              'Do not call AssetGenImage.image(...) directly; use '
              'imageTint(...) or imageNoTint(...) from the AssetGenImageTint '
              'extension instead.',
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
      if (element == null || element.name != 'image') {
        return;
      }
      if (!isAssetGenImageClassMember(element)) {
        return;
      }
      if (isWithinAssetGenImageExtension(node)) {
        return;
      }
      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_DirectImageFix()];
}

class _DirectImageFix extends DartFix {
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

      final String replacement;
      if (assetChainContainsSegment(node.target, 'static')) {
        replacement = 'imageNoTint';
      } else if (assetChainContainsSegment(node.target, 'tintable')) {
        replacement = 'imageTint';
      } else {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement(...) instead',
        priority: 100,
      );

      changeBuilder.addDartFileEdit((DartFileEditBuilder builder) {
        final SourceRange sourceRange = node.methodName.sourceRange;
        builder.addSimpleReplacement(sourceRange, replacement);
      });
    });
  }
}
