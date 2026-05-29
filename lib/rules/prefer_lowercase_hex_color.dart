import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as error;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferLowercaseHexColor extends DartLintRule {
  const PreferLowercaseHexColor()
    : super(
        code: const LintCode(
          name: 'prefer_lowercase_hex_color',
          problemMessage:
              'Hex digits inside Color(0x...) should be lowercase.',
          errorSeverity: error.DiagnosticSeverity.WARNING,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression(
      (InstanceCreationExpression node) {
        if (node.constructorName.type.element?.name != 'Color') {
          return;
        }
        final arguments = node.argumentList.arguments;
        if (arguments.length != 1) {
          return;
        }
        final first = arguments.first;
        if (first is! IntegerLiteral) {
          return;
        }
        final lexeme = first.literal.lexeme;
        if (!_isUppercaseHexLiteral(lexeme)) {
          return;
        }
        reporter.atNode(first, code);
      },
    );
  }

  @override
  List<Fix> getFixes() => [_LowercaseHexColorFix()];
}

bool _isUppercaseHexLiteral(String lexeme) {
  if (!lexeme.startsWith('0x') && !lexeme.startsWith('0X')) {
    return false;
  }
  for (int i = 0; i < lexeme.length; i++) {
    final int unit = lexeme.codeUnitAt(i);
    // 'A'..'F' inclusive
    if (unit >= 0x41 && unit <= 0x46) {
      return true;
    }
    // 'X' in the prefix counts as well.
    if (i == 1 && unit == 0x58) {
      return true;
    }
  }
  return false;
}

class _LowercaseHexColorFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addInstanceCreationExpression(
      (InstanceCreationExpression node) {
        if (!node.sourceRange.intersects(analysisError.sourceRange)) return;
        if (node.constructorName.type.element?.name != 'Color') return;
        final arguments = node.argumentList.arguments;
        if (arguments.length != 1) return;
        final first = arguments.first;
        if (first is! IntegerLiteral) return;
        final lexeme = first.literal.lexeme;
        if (!_isUppercaseHexLiteral(lexeme)) return;

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Lowercase the hex digits',
          priority: 100,
        );
        changeBuilder.addDartFileEdit((DartFileEditBuilder builder) {
          final SourceRange range = first.sourceRange;
          builder.addSimpleReplacement(range, lexeme.toLowerCase());
        });
      },
    );
  }
}
