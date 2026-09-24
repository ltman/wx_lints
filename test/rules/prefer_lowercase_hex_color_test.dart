import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:wx_lints/src/rules/prefer_lowercase_hex_color.dart';

const _colorStub = '''
class Color {
  const Color(int value);
  const Color.fromARGB(int a, int r, int g, int b);
}
''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferLowercaseHexColorTest);
  });
}

@reflectiveTest
class PreferLowercaseHexColorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferLowercaseHexColor();
    super.setUp();
  }

  Future<void> test_flags_all_uppercase_hex() async {
    const literal = '0xFFFFFF';
    final content = '$_colorStub\nfinal c = Color($literal);\n';
    await assertDiagnostics(content, [
      lint(
        content.indexOf(literal),
        literal.length,
        correctionContains: 'lowercasing the hex digits',
      ),
    ]);
  }

  Future<void> test_flags_uppercase_x_prefix() async {
    const literal = '0XffffFF';
    final content = '$_colorStub\nfinal c = Color($literal);\n';
    await assertDiagnostics(content, [
      lint(content.indexOf(literal), literal.length),
    ]);
  }

  Future<void> test_flags_single_trailing_uppercase_digit() async {
    const literal = '0xfffffF';
    final content = '$_colorStub\nfinal c = Color($literal);\n';
    await assertDiagnostics(content, [
      lint(content.indexOf(literal), literal.length),
    ]);
  }

  Future<void> test_ignores_all_lowercase_hex() async {
    final content = '$_colorStub\nfinal c = Color(0xffffff);\n';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_hex_without_letters() async {
    final content = '$_colorStub\nfinal c = Color(0x123456);\n';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_named_constructor_with_multiple_arguments() async {
    final content =
        '$_colorStub\nfinal c = Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF);\n';
    await assertNoDiagnostics(content);
  }

  Future<void> test_ignores_non_integer_literal_argument() async {
    final content =
        '$_colorStub\nfinal value = 0xFFFFFF;\nfinal c = Color(value);\n';
    await assertNoDiagnostics(content);
  }
}
