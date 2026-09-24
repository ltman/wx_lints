import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:wx_lints/src/rules/disallow_maybe_when.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DisallowMaybeWhenTest);
  });
}

@reflectiveTest
class DisallowMaybeWhenTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisallowMaybeWhen();
    super.setUp();
  }

  Future<void> test_flags_fragment_maybeWhen() async {
    const invocation = "foo.maybeWhen(orElse: () => 1)";
    final content =
        '''
class Fragment\$Foo {}

extension Fragment\$FooExtension on Fragment\$Foo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(Fragment\$Foo foo) {
  $invocation;
}
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf(invocation),
        invocation.length,
        correctionContains: "when(...)",
      ),
    ]);
  }

  Future<void> test_flags_query_maybeWhen() async {
    const invocation = "foo.maybeWhen(orElse: () => 1)";
    final content =
        '''
class Query\$Foo {}

extension Query\$FooExtension on Query\$Foo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(Query\$Foo foo) {
  $invocation;
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf(invocation), invocation.length),
    ]);
  }

  Future<void> test_flags_mutation_maybeWhen() async {
    const invocation = "foo.maybeWhen(orElse: () => 1)";
    final content =
        '''
class Mutation\$Foo {}

extension Mutation\$FooExtension on Mutation\$Foo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(Mutation\$Foo foo) {
  $invocation;
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf(invocation), invocation.length),
    ]);
  }

  Future<void> test_ignores_non_generated_class() async {
    await assertNoDiagnostics(r'''
class Foo {}

extension FooExtension on Foo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(Foo foo) {
  foo.maybeWhen(orElse: () => 1);
}
''');
  }

  Future<void> test_ignores_class_name_missing_dollar_prefix() async {
    await assertNoDiagnostics(r'''
class FragmentFoo {}

extension FragmentFooExtension on FragmentFoo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(FragmentFoo foo) {
  foo.maybeWhen(orElse: () => 1);
}
''');
  }

  Future<void> test_ignores_method_declared_directly_on_class() async {
    await assertNoDiagnostics(r'''
class Fragment$Foo {
  R maybeWhen<R>({required R Function() orElse}) => orElse();
}

void f(Fragment$Foo foo) {
  foo.maybeWhen(orElse: () => 1);
}
''');
  }

  Future<void> test_ignores_differently_named_method() async {
    await assertNoDiagnostics(r'''
class Fragment$Foo {}

extension Fragment$FooExtension on Fragment$Foo {
  R maybeWhen2<R>({required R Function() orElse}) => orElse();
}

void f(Fragment$Foo foo) {
  foo.maybeWhen2(orElse: () => 1);
}
''');
  }
}
