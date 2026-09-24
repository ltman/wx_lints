# wx_lints

A collection of custom lint rules for Dart and Flutter projects, designed to enforce best practices and prevent common issues.

## Features

This package provides the following custom lint rules:

### `disallow_maybe_when`

This rule disallows the use of the `maybeWhen` method on generated GraphQL fragment classes. Using `when` instead of `maybeWhen` ensures that all possible states are handled.

**Example**

Let's assume you have a fragment that can be one of two types: `TypeA` or `TypeB`.

With `maybeWhen`, you might handle only one case and forget about the others:

```dart
myFragment.maybeWhen(
  onTypeA: (data) => print('Data: $data'),
  orElse: () => print('Something else'), 
);
```

This rule encourages using `when` to ensure all cases are handled explicitly. This makes your code more robust against changes in your GraphQL schema.

The lint rule provides a quick fix to replace `maybeWhen` with `when`.

```dart
myFragment.when(
onTypeA: (data) => print('Data: $data'),
onTypeB: (data) => print('This is TypeB'),
orElse: () => print('Something else'),
);
```

### `disallow_static_image_tint`

This rule disallows calling the `imageTint()` extension on `AssetGenImage` assets that live under a `static` asset group. Static assets are not meant to be tinted, so `imageNoTint()` must be used instead.

**Example**

```dart
// Not allowed:
child: Assets.images.static.imgArtPrimary.imageTint(color: Colors.red),

// Allowed:
child: Assets.images.static.imgArtPrimary.imageNoTint(),
```

The lint rule provides a quick fix to replace `imageTint` with `imageNoTint`.

### `disallow_tintable_image_no_tint`

This rule disallows calling the `imageNoTint()` extension on `AssetGenImage` assets that live under a `tintable` asset group. Tintable assets are meant to be tinted, so `imageTint()` must be used instead.

**Example**

```dart
// Not allowed:
child: Assets.images.tintable.img24OutlineSearch.imageNoTint(),

// Allowed:
child: Assets.images.tintable.img24OutlineSearch.imageTint(color: Colors.red),
```

The lint rule provides a quick fix to replace `imageNoTint` with `imageTint`.

### `disallow_direct_asset_image`

This rule disallows calling the generated `AssetGenImage.image(...)` method directly. It bypasses the `imageTint`/`imageNoTint` extensions (from `AssetGenImageTint`), which is where tint handling lives, so callers must go through one of those instead. Calls to `image(...)` made from inside an extension declared on `AssetGenImage` (i.e. the `AssetGenImageTint` extension's own implementation of `imageTint`/`imageNoTint`) are exempt, since that's the sanctioned place for the underlying call.

**Example**

```dart
// Not allowed:
child: Assets.images.static.imgArtPrimary.image(),

// Allowed:
child: Assets.images.static.imgArtPrimary.imageNoTint(),
child: Assets.images.tintable.img24OutlineSearch.imageTint(color: Colors.red),
```

Where the asset chain unambiguously refers to a `static` or `tintable` asset, the lint rule provides a quick fix to replace `image` with `imageNoTint` or `imageTint` respectively.

## Getting started

`wx_lints` is a [Dart analyzer plugin](https://dart.dev/tools/analyzer-plugins).
It requires Dart 3.10 or later and does **not** need `custom_lint`.

Enable it from the consuming project's `analysis_options.yaml`. Note that
`plugins` is a **top-level** key -- it is *not* nested under `analyzer:`:

```yaml
plugins:
  wx_lints:
    path: ../wx_lints
```

The plugin does not need to be listed in `pubspec.yaml`; the analysis server
resolves it from the `plugins` entry directly.

## Usage

All five rules are registered as **warning rules**, so they are enabled by
default and reported by the regular analyzer:

```sh
dart analyze
```

```sh
flutter analyze
```

They also appear live in any IDE backed by the Dart Analysis Server, along with
their quick fixes.

### Disabling a rule

Warning rules are on by default. Turn individual rules off under `diagnostics`:

```yaml
plugins:
  wx_lints:
    path: ../wx_lints
    diagnostics:
      prefer_lowercase_hex_color: false
```

### Suppressing a single report

Ignore comments must be **prefixed with the plugin name**:

```dart
// ignore: wx_lints/disallow_maybe_when
myFragment.maybeWhen(orElse: () {});
```

```dart
// ignore_for_file: wx_lints/prefer_lowercase_hex_color
```

A bare `// ignore: disallow_maybe_when` (the old `custom_lint` form) does
**not** suppress these diagnostics.

### Quick fixes

Every rule ships a quick fix, offered through the IDE's lightbulb / "Quick Fix"
action.

Four of the five also offer a **"... in file"** variant that fixes every
occurrence of that diagnostic in the current file at once:

| Rule | Fix-all-in-file |
| --- | --- |
| `disallow_maybe_when` | Use when(...) in file |
| `prefer_lowercase_hex_color` | Lowercase hex digits in file |
| `disallow_static_image_tint` | Use imageNoTint() in file |
| `disallow_tintable_image_no_tint` | Use imageTint() in file |
| `disallow_direct_asset_image` | -- (replacement varies per call site) |

The in-file variant only appears when the file contains **two or more** reports
of the same rule.

`dart fix --apply` does **not** apply these. Analyzer plugins expose only
`edit.getFixes` and `edit.getAssists`, both of which are point queries; the
`edit.bulkFixes` request that `dart fix` uses has no plugin handler. Note that
this is a capability regression from `custom_lint`, which supported
`dart run custom_lint --fix`; there is currently no equivalent.

## Developing this plugin

The plugin entry point is `lib/main.dart`, which must expose a top-level
`plugin` variable. Rules and their fixes live in `lib/src/rules/`, and each one
is registered in `WxLintsPlugin.register`.

`print` does not work inside plugin code, since the plugin runs in a separate
isolate. If the plugin misbehaves, check the analyzer diagnostics pages
(**Dart: Open Analyzer Diagnostics** in VS Code) for the plugin's status and any
crash output.

### Testing

Each rule has a test suite under `test/rules/`, built on `package:analyzer_testing`'s
`AnalysisRuleTest` harness. It resolves a snippet of Dart source in-memory,
registers the rule under test, and asserts exactly which diagnostics are
reported (and at which offsets):

```dart
@reflectiveTest
class DisallowMaybeWhenTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisallowMaybeWhen();
    super.setUp();
  }

  Future<void> test_flags_fragment_maybeWhen() async {
    await assertDiagnostics(content, [lint(offset, length)]);
  }
}
```

Run the suite with:

```sh
dart test
```

Tests cover each rule's detection logic (positive, negative, and edge cases)
against minimal local stub classes, so they don't depend on real Flutter or
GraphQL codegen output. They don't cover the exact rewritten output of each
quick fix, since there's no stable public harness for invoking a
`ResolvedCorrectionProducer` outside the Dart SDK's own analysis_server test
infrastructure.
