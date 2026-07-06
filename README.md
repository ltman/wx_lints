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

To use this package, add `wx_lints` and `custom_lint` as a dev dependencies in your `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_lint:
  wx_lints:
```

Next, enable the custom lint in your `analysis_options.yaml` file:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## Usage

To run the linter, execute the following command in your terminal:

```sh
dart run custom_lint
```

This will analyze your code and report any violations of the custom lint rules.
