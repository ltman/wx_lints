import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class PreferLowercaseHexColor extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_lowercase_hex_color',
    'Hex digits inside Color(0x...) should be lowercase.',
    correctionMessage: 'Try lowercasing the hex digits.',
    severity: DiagnosticSeverity.WARNING,
  );

  PreferLowercaseHexColor()
    : super(
        name: 'prefer_lowercase_hex_color',
        description:
            'Prefers lowercase hex digits in Color(0x...) literals, so that '
            'colors are written consistently across the codebase.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final literal = uppercaseHexArgumentOf(node);
    if (literal == null) {
      return;
    }
    rule.reportAtNode(literal);
  }
}

/// Returns the single `Color(0x...)` argument of [node] when it is an integer
/// literal containing uppercase hex characters, or `null` otherwise.
IntegerLiteral? uppercaseHexArgumentOf(InstanceCreationExpression node) {
  if (node.constructorName.type.element?.name != 'Color') {
    return null;
  }
  final arguments = node.argumentList.arguments;
  if (arguments.length != 1) {
    return null;
  }
  final first = arguments.first;
  if (first is! IntegerLiteral) {
    return null;
  }
  if (!isUppercaseHexLiteral(first.literal.lexeme)) {
    return null;
  }
  return first;
}

bool isUppercaseHexLiteral(String lexeme) {
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

/// Lowercases the hex digits of a `Color(0x...)` literal.
class LowercaseHexColor extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'wx_lints.fix.lowercaseHexColor',
    DartFixKindPriority.standard,
    'Lowercase the hex digits',
  );

  static const _multiFixKind = FixKind(
    'wx_lints.fix.lowercaseHexColor.multi',
    DartFixKindPriority.inFile,
    'Lowercase hex digits in file',
  );

  LowercaseHexColor({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind? get multiFixKind => _multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The diagnostic is reported at the integer literal itself.
    final literal = node.thisOrAncestorOfType<IntegerLiteral>();
    if (literal == null) {
      return;
    }
    final lexeme = literal.literal.lexeme;
    if (!isUppercaseHexLiteral(lexeme)) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(literal.sourceRange, lexeme.toLowerCase());
    });
  }
}
