import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Whether [element] is a member of an extension on the generated
/// `AssetGenImage` class (e.g. the `imageTint`/`imageNoTint` extensions).
bool isAssetGenImageExtensionMember(Element element) {
  final enclosing = element.enclosingElement;
  if (enclosing is! ExtensionElement) {
    return false;
  }
  return enclosing.extendedType.element?.name == 'AssetGenImage';
}

/// Whether [element] is declared directly on the generated `AssetGenImage`
/// class itself (e.g. the built-in `image(...)` constructor method), as
/// opposed to an extension member such as `imageTint`/`imageNoTint`.
bool isAssetGenImageClassMember(Element element) {
  final enclosing = element.enclosingElement;
  if (enclosing is! InterfaceElement) {
    return false;
  }
  return enclosing.name == 'AssetGenImage';
}

/// Whether [node] is lexically inside an extension declared on the
/// generated `AssetGenImage` class (e.g. the body of the `AssetGenImageTint`
/// extension's `imageTint`/`imageNoTint` methods, which are the sanctioned
/// place to call `AssetGenImage.image(...)` directly).
bool isWithinAssetGenImageExtension(AstNode node) {
  final ExtensionDeclaration? extensionDecl = node
      .thisOrAncestorOfType<ExtensionDeclaration>();
  if (extensionDecl == null) {
    return false;
  }
  final ExtensionElement? extensionElement =
      extensionDecl.declaredFragment?.element;
  return extensionElement?.extendedType.element?.name == 'AssetGenImage';
}

/// Walks the property-access chain of an asset reference (e.g.
/// `Assets.images.static.imgArtPrimary`) and checks whether any segment of
/// the chain is named [segment] (e.g. `static` or `tintable`).
bool assetChainContainsSegment(Expression? expression, String segment) {
  if (expression == null) {
    return false;
  }
  if (expression is SimpleIdentifier) {
    return expression.name == segment;
  }
  if (expression is PrefixedIdentifier) {
    return expression.prefix.name == segment ||
        expression.identifier.name == segment;
  }
  if (expression is PropertyAccess) {
    return expression.propertyName.name == segment ||
        assetChainContainsSegment(expression.target, segment);
  }
  return false;
}
