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

import 'package:wx_lints/src/asset_gen_image_utils.dart';

class DisallowTintableImageNoTint extends AnalysisRule {
  static const LintCode code = LintCode(
    'disallow_tintable_image_no_tint',
    'Tintable assets must not use imageNoTint(); use imageTint() instead.',
    correctionMessage: "Try replacing 'imageNoTint' with 'imageTint'.",
    severity: DiagnosticSeverity.WARNING,
  );

  DisallowTintableImageNoTint()
    : super(
        name: 'disallow_tintable_image_no_tint',
        description:
            'Disallows calling imageNoTint() on AssetGenImage assets that live '
            'under a tintable asset group; those assets are meant to be '
            'tinted.',
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
    if (element == null || element.name != 'imageNoTint') {
      return;
    }
    if (!isAssetGenImageExtensionMember(element)) {
      return;
    }
    if (!assetChainContainsSegment(node.target, 'tintable')) {
      return;
    }
    rule.reportAtNode(node);
  }
}

/// Replaces `imageNoTint()` with `imageTint()` on tintable assets.
class ReplaceImageNoTintWithImageTint extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'wx_lints.fix.replaceImageNoTintWithImageTint',
    DartFixKindPriority.standard,
    'Use imageTint() instead',
  );

  static const _multiFixKind = FixKind(
    'wx_lints.fix.replaceImageNoTintWithImageTint.multi',
    DartFixKindPriority.inFile,
    'Use imageTint() in file',
  );

  ReplaceImageNoTintWithImageTint({required super.context});

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
        'imageTint',
      );
    });
  }
}
