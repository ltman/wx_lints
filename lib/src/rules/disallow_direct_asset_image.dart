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

class DisallowDirectAssetImage extends AnalysisRule {
  static const LintCode code = LintCode(
    'disallow_direct_asset_image',
    'Do not call AssetGenImage.image(...) directly; use imageTint(...) or '
        'imageNoTint(...) from the AssetGenImageTint extension instead.',
    correctionMessage:
        "Try using 'imageTint(...)' or 'imageNoTint(...)' instead.",
    severity: DiagnosticSeverity.WARNING,
  );

  DisallowDirectAssetImage()
    : super(
        name: 'disallow_direct_asset_image',
        description:
            'Disallows calling the generated AssetGenImage.image(...) method '
            'directly, since it bypasses the imageTint/imageNoTint extensions '
            'where tint handling lives.',
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
    if (element == null || element.name != 'image') {
      return;
    }
    if (!isAssetGenImageClassMember(element)) {
      return;
    }
    if (isWithinAssetGenImageExtension(node)) {
      return;
    }
    rule.reportAtNode(node);
  }
}

/// Replaces a direct `image(...)` call with `imageNoTint` or `imageTint`,
/// but only where the asset chain unambiguously identifies which one applies.
class ReplaceDirectImageCall extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'wx_lints.fix.replaceDirectImageCall',
    DartFixKindPriority.standard,
    'Use {0}(...) instead',
  );

  ReplaceDirectImageCall({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String> get fixArguments => [_replacement ?? ''];

  String? _replacement;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) {
      return;
    }

    final String replacement;
    if (assetChainContainsSegment(invocation.target, 'static')) {
      replacement = 'imageNoTint';
    } else if (assetChainContainsSegment(invocation.target, 'tintable')) {
      replacement = 'imageTint';
    } else {
      // Ambiguous asset chain: offer no fix.
      return;
    }
    _replacement = replacement;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        invocation.methodName.sourceRange,
        replacement,
      );
    });
  }
}
