import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:wx_lints/src/rules/disallow_static_image_tint.dart';

const _assetGenStub = '''
class Color {
  const Color();
}

class Widget {
  const Widget();
}

class AssetGenImage {
  const AssetGenImage();
  Widget image() => const Widget();
}

extension AssetGenImageTint on AssetGenImage {
  Widget imageTint(Color color) => image();
  Widget imageNoTint() => image();
}

class _StaticAssets {
  const _StaticAssets();
  AssetGenImage get imgPrimary => const AssetGenImage();
}

class _TintableAssets {
  const _TintableAssets();
  AssetGenImage get imgPrimary => const AssetGenImage();
}

class _Assets {
  const _Assets();
  _StaticAssets get static => const _StaticAssets();
  _TintableAssets get tintable => const _TintableAssets();
  AssetGenImage get imgPrimary => const AssetGenImage();
}

const assets = _Assets();
const color = Color();
''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DisallowStaticImageTintTest);
  });
}

@reflectiveTest
class DisallowStaticImageTintTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisallowStaticImageTint();
    super.setUp();
  }

  Future<void> test_flags_imageTint_on_static_asset() async {
    const invocation = 'assets.static.imgPrimary.imageTint(color)';
    final content = '$_assetGenStub\nfinal w = $invocation;\n';
    await assertDiagnostics(content, [
      lint(
        content.indexOf(invocation),
        invocation.length,
        correctionContains: "imageNoTint",
      ),
    ]);
  }

  Future<void> test_ignores_imageTint_on_tintable_asset() async {
    final content =
        '$_assetGenStub\nfinal w = assets.tintable.imgPrimary.imageTint(color);\n';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_imageTint_without_static_or_tintable_segment() async {
    final content = '$_assetGenStub\nfinal w = assets.imgPrimary.imageTint(color);\n';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_imageTint_not_declared_on_asset_gen_image_extension() async {
    final content =
        '''
class Foo {
  Object imageTint(Object color) => this;
}

final foo = Foo();
final w = foo.imageTint(1);
''';
    await assertNoDiagnostics(content);
  }
}
