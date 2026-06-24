import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowAssetGenImage extends DartLintRule {
  const DisallowAssetGenImage()
    : super(
        code: const LintCode(
          name: 'disallow_asset_gen_image',
          problemMessage:
              'Avoid calling .image() on AssetGenImage directly.'
              'Use .imageTint() to apply the foreground color, '
              'or .imageNoTint() if the image should render without tinting.',
          errorSeverity: error.DiagnosticSeverity.WARNING,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'image') return;

      final receiverType = node.realTarget?.staticType;
      if (receiverType == null) return;
      if (receiverType.element?.name != 'AssetGenImage') return;

      reporter.atNode(node, code);
    });
  }
}
