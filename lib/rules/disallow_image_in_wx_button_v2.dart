import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowImageInWxButtonV2 extends DartLintRule {
  const DisallowImageInWxButtonV2()
    : super(
        code: const LintCode(
          name: 'disallow_image_in_wx_button_v2',
          problemMessage:
              'Use .imageTintForeground() instead of .image() inside WxButtonV2. '
              'If the icon must not be tinted, use .imageNoTint() instead.',
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
      if (node.methodName.name != 'image') return;

      final receiverType = node.realTarget?.staticType;
      if (receiverType == null) return;
      if (receiverType.element?.name != 'AssetGenImage') return;

      // Walk up the AST to find a WxButtonV2 ancestor.
      AstNode? parent = node.parent;
      while (parent != null) {
        if (parent is InstanceCreationExpression) {
          final typeName = parent.constructorName.type.name.lexeme;
          if (typeName == 'WxButtonV2') {
            reporter.atNode(node, code);
            return;
          }
        }
        parent = parent.parent;
      }
    });
  }
}
