import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class DisallowMaybeWhen extends AnalysisRule {
  static const LintCode code = LintCode(
    'disallow_maybe_when',
    'Usage of the maybeWhen(...) method is not allowed.',
    correctionMessage: "Try using 'when(...)' so that every case is handled.",
    severity: DiagnosticSeverity.WARNING,
  );

  DisallowMaybeWhen()
    : super(
        name: 'disallow_maybe_when',
        description:
            'Disallows maybeWhen(...) on generated GraphQL fragment, query '
            'and mutation classes, so that every case is handled explicitly.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final Element? element = node.methodName.element;
    if (element == null || element.name != 'maybeWhen') {
      return;
    }
    final enclosing = element.enclosingElement;
    if (enclosing is! ExtensionElement) {
      return;
    }
    final className = enclosing.extendedType.element?.name;
    if (className == null ||
        !className.startsWith(r'Fragment$') &&
            !className.startsWith(r'Query$') &&
            !className.startsWith(r'Mutation$')) {
      return;
    }
    rule.reportAtNode(node);
  }
}

/// Replaces `maybeWhen(...)` with `when(...)`.
class ReplaceMaybeWhenWithWhen extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'wx_lints.fix.replaceMaybeWhenWithWhen',
    DartFixKindPriority.standard,
    'Use when(...) instead',
  );

  static const _multiFixKind = FixKind(
    'wx_lints.fix.replaceMaybeWhenWithWhen.multi',
    DartFixKindPriority.inFile,
    'Use when(...) in file',
  );

  ReplaceMaybeWhenWithWhen({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind? get multiFixKind => _multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        invocation.methodName.sourceRange,
        'when',
      );
    });
  }
}
