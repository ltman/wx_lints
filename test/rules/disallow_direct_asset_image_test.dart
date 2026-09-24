import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:wx_lints/src/rules/disallow_direct_asset_image.dart';

const _assetGenImageStub = '''
class Widget {
  const Widget();
}

class AssetGenImage {
  const AssetGenImage();
  Widget image() => const Widget();
}
''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DisallowDirectAssetImageTest);
  });
}

@reflectiveTest
class DisallowDirectAssetImageTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisallowDirectAssetImage();
    super.setUp();
  }

  Future<void> test_flags_direct_image_call_outside_extension() async {
    const invocation = 'AssetGenImage().image()';
    final content = '$_assetGenImageStub\nfinal w = $invocation;\n';
    await assertDiagnostics(content, [
      lint(
        content.indexOf(invocation),
        invocation.length,
        correctionContains: "imageTint",
      ),
    ]);
  }

  Future<void> test_ignores_image_call_from_within_asset_gen_image_extension() async {
    final content =
        '''
$_assetGenImageStub

extension AssetGenImageTint on AssetGenImage {
  Widget imageTint() => image();
  Widget imageNoTint() => image();
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_image_method_on_unrelated_class() async {
    const content = '''
class Widget {
  const Widget();
}

class Foo {
  Widget image() => const Widget();
}

final w = Foo().image();
''';
    await assertNoDiagnostics(content);
  }
}
