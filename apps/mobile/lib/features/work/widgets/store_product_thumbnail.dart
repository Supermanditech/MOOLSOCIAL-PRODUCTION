import 'package:flutter/material.dart';

import '../../../ui_v2/buy/buy_v2_design.dart';
import '../work_models.dart';

/// Store presentation of the same identity-bound media used by Buy.
/// Square bounds prevent a narrow list slot from shrinking a complete pack.
/// Buy retains ownership of photo admission, contain fitting, illustrations,
/// disclosure and loading/error fallbacks; no crop or alternate SKU is invented.
class StoreProductThumbnail extends StatelessWidget {
  const StoreProductThumbnail({
    super.key,
    required this.product,
    required this.extent,
  });

  final WorkspaceCatalogueItem product;
  final double extent;

  static double gridExtent(double cardWidth) =>
      (cardWidth - 14).clamp(40.0, 48.0);

  @override
  Widget build(BuildContext context) {
    final preview = product.toCataloguePreviewProduct();
    final missing =
        preview.mediaAssets.isEmpty &&
        BuyV2ProductPackshot.resolveMedia(preview) == null;
    return SizedBox.square(
      dimension: extent,
      child: missing
          ? Semantics(
              image: true,
              label:
                  'Product photo unavailable for ${product.title}, ${product.pack}',
              child: Tooltip(
                message: 'Product photo unavailable',
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: (extent * .45).clamp(16.0, 24.0),
                  color: BuyV2Colors.muted,
                ),
              ),
            )
          : BuyV2ProductPackshot(
              product: preview,
              // Zero radius also removes the shared renderer's photo padding.
              // Preserve the whole exact pack, not a stretched or cropped substitute.
              borderRadius: 0,
            ),
    );
  }
}
