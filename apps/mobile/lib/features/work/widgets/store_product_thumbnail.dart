import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../ui_v2/buy/buy_v2_design.dart';
import '../work_models.dart';
import '../work_session.dart';
import '../work_services.dart' show storeEntryEvaluationPhotoAsset;

/// Store presentation of the same identity-bound media used by Buy.
/// Square bounds prevent a narrow list slot from shrinking a complete pack.
/// Buy retains ownership of photo admission, contain fitting, illustrations,
/// disclosure and loading/error fallbacks; no crop or alternate SKU is invented.
class StoreProductThumbnail extends StatefulWidget {
  const StoreProductThumbnail({
    super.key,
    required this.product,
    required this.extent,
    this.session,
  });

  final WorkspaceCatalogueItem product;
  final double extent;
  final WorkSession? session;

  static double gridExtent(double cardWidth) =>
      (cardWidth - 14).clamp(40.0, 48.0);

  @override
  State<StoreProductThumbnail> createState() => _StoreProductThumbnailState();
}

class _StoreProductThumbnailState extends State<StoreProductThumbnail> {
  String? _mediaKey;
  Future<Uint8List>? _bytes;

  Widget _missing() => Semantics(
    image: true,
    label:
        'Product photo unavailable for ${widget.product.title}, ${widget.product.pack}',
    child: Tooltip(
      message: 'Product photo unavailable',
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (widget.extent * .45).clamp(16.0, 24.0),
        color: BuyV2Colors.muted,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => widget.session == null
      ? _buildPhoto(context)
      : AnimatedBuilder(
          animation: widget.session!,
          builder: (context, _) => _buildPhoto(context),
        );

  Widget _buildPhoto(BuildContext context) {
    final product = widget.product;
    final extent = widget.extent;
    if (product.privatePhoto case final photo?) {
      final session = widget.session;
      // MoolSocial catalogue media always retains its owner. A private image
      // cannot silently override it even if malformed imported data asks to.
      if (session?.catalogueManagesProductPhoto(product) != true) {
        if (!photo.matches(product)) {
          _mediaKey = null;
          _bytes = null;
          return SizedBox.square(dimension: extent, child: _missing());
        }
        final store = session?.privateProductPhotos;
        final key = '${store?.owner}:${photo.toJson()}';
        if (_mediaKey != key) {
          _mediaKey = key;
          _bytes = store?.read(product);
        }
        return SizedBox.square(
          dimension: extent,
          child: FutureBuilder<Uint8List>(
            key: ValueKey(key),
            future: _bytes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  !snapshot.hasData ||
                  store == null ||
                  !store.isCurrent()) {
                return _missing();
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                semanticLabel: '${product.title}, ${product.pack}',
                errorBuilder: (_, error, trace) => _missing(),
              );
            },
          ),
        );
      }
    }
    _mediaKey = null;
    _bytes = null;
    final evaluationAsset = storeEntryEvaluationPhotoAsset(product);
    if (evaluationAsset != null) {
      return SizedBox.square(
        dimension: extent,
        child: Image.asset(
          evaluationAsset,
          fit: BoxFit.contain,
          semanticLabel: '${product.title}, ${product.pack}, evaluation image',
          errorBuilder: (_, error, trace) => _missing(),
        ),
      );
    }
    final preview = product.toCataloguePreviewProduct();
    final missing =
        preview.mediaAssets.isEmpty &&
        BuyV2ProductPackshot.resolveMedia(preview) == null;
    return SizedBox.square(
      dimension: extent,
      child: missing
          ? _missing()
          : BuyV2ProductPackshot(
              product: preview,
              // Zero radius also removes the shared renderer's photo padding.
              // Preserve the whole exact pack, not a stretched or cropped substitute.
              borderRadius: 0,
            ),
    );
  }
}
