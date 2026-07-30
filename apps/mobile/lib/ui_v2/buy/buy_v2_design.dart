import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../features/buy/buy_v2_models.dart';

final NumberFormat _buyV2Currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String buyV2Money(num value) => _buyV2Currency.format(value);

abstract final class BuyV2Colors {
  static const navy = Color(0xFF000080);
  static const royal = Color(0xFF1515B8);
  static const orange = Color(0xFFFF9933);
  static const green = Color(0xFF138808);
  static const ink = Color(0xFF11132F);
  static const muted = Color(0xFF626780);
  static const line = Color(0xFFE0E2EE);
  static const canvas = Color(0xFFF4F5FB);
  static const softOrange = Color(0xFFFFF0DE);
  static const softGreen = Color(0xFFEAF7E8);
  static const softBlue = Color(0xFFEDECFF);
}

abstract final class BuyV2Metrics {
  static const maxWidth = 520.0;
  static const railWidth = 94.0;
  static const dockHeight = 54.0;
  static const radius = 16.0;
  static const compactRadius = 12.0;
  static const minimumTap = 44.0;
}

abstract final class BuyV2Motion {
  static const press = Duration(milliseconds: 110);
  static const stateChange = Duration(milliseconds: 180);
  static const contentChange = Duration(milliseconds: 240);
  static const pressScale = .985;

  static Duration resolved(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

class BuyV2TricolourLine extends StatelessWidget {
  const BuyV2TricolourLine({super.key, this.height = 3});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: BuyV2Colors.orange)),
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: BuyV2Colors.green)),
        ],
      ),
    );
  }
}

enum BuyV2ProductMediaKind { exactProduct, category }

@immutable
class BuyV2ProductMediaSource {
  const BuyV2ProductMediaSource({
    required this.assetPath,
    required this.cell,
    required this.kind,
  });

  final String assetPath;
  final int cell;
  final BuyV2ProductMediaKind kind;
}

class BuyV2ProductPackshot extends StatelessWidget {
  const BuyV2ProductPackshot({
    super.key,
    required this.product,
    this.borderRadius = 14,
  });

  static const productAtlasPath =
      'assets/prototype/moolsocial-product-packshot-atlas-v2-2026.png';
  static const categoryAtlasAPath =
      'assets/prototype/moolsocial-category-media-atlas-v3a-2026.png';
  static const categoryAtlasBPath =
      'assets/prototype/moolsocial-category-media-atlas-v3b-2026.png';
  static const categoryAtlasCPath =
      'assets/prototype/moolsocial-category-media-atlas-v3c-2026.png';
  static const medicineAtlasPath =
      'assets/prototype/moolsocial-medicine-media-atlas-v3d-2026.png';

  final BuyV2Product product;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final source = resolveMedia(product);
    if (source == null) {
      return Semantics(
        image: true,
        label: 'Category visual for ${product.title}',
        child: _BuyV2ProductMediaFallback(
          key: ValueKey('buy-product-media-fallback-${product.id}'),
          product: product,
          borderRadius: borderRadius,
        ),
      );
    }
    final cell = source.cell;
    final column = cell % 4;
    final row = cell ~/ 4;
    return Semantics(
      image: true,
      label: source.kind == BuyV2ProductMediaKind.exactProduct
          ? 'Product photo of ${product.title}'
          : 'Category photo for ${product.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth;
              final cellHeight = constraints.maxHeight;
              return Transform.scale(
                scale: 1.04,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: _BuyV2ProductMediaFallback(
                          product: product,
                          borderRadius: borderRadius,
                        ),
                      ),
                    ),
                    Positioned(
                      key: ValueKey(
                        'buy-packshot-sprite-${product.id}-'
                        '${source.assetPath}-$cell',
                      ),
                      left: -column * cellWidth,
                      top: -row * cellHeight,
                      width: cellWidth * 4,
                      height: cellHeight * 3,
                      child: Image.asset(
                        source.assetPath,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: BuyV2Colors.navy,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static BuyV2ProductMediaSource? resolveMedia(BuyV2Product product) {
    final medicineCell = switch (product.id) {
      'm-paracetamol-500' => 0,
      'm-pain-relief-gel' => 1,
      'm-metformin-500' => 2,
      'm-glucose-strips' => 3,
      'm-telmisartan-40' => 4,
      'm-atorvastatin-10' => 5,
      'm-pantoprazole-40' => 6,
      'm-ors' => 7,
      _ => null,
    };
    if (medicineCell != null) {
      return BuyV2ProductMediaSource(
        assetPath: medicineAtlasPath,
        cell: medicineCell,
        kind: BuyV2ProductMediaKind.exactProduct,
      );
    }

    final canonicalId = product.canonicalId.toLowerCase();
    final exactProductCell = switch (canonicalId) {
      'tomato' => 0,
      'rice' => 1,
      'atta' => 2,
      'oil' => 3,
      'soap' => 4,
      'notebook' => 5,
      'milk' => 6,
      'bread' => 7,
      'water' => 11,
      _ => null,
    };
    if (exactProductCell != null) {
      return BuyV2ProductMediaSource(
        assetPath: productAtlasPath,
        cell: exactProductCell,
        kind: BuyV2ProductMediaKind.exactProduct,
      );
    }

    final categoryId = product.categoryId.toLowerCase();
    final categorySource = switch (categoryId) {
      'fruits-vegetables' => (categoryAtlasAPath, 0),
      'dairy-bakery' => (categoryAtlasAPath, 1),
      'eggs-poultry' => (categoryAtlasAPath, 2),
      'meat-seafood' => (categoryAtlasAPath, 3),
      'flour-rice-grains' || 'dals-staples' => (categoryAtlasAPath, 4),
      'oils-ghee' => (categoryAtlasAPath, 5),
      'ground-spices' => (categoryAtlasAPath, 6),
      'whole-spices' => (categoryAtlasAPath, 7),
      'breakfast-cereals' => (categoryAtlasAPath, 8),
      'instant-foods' => (categoryAtlasAPath, 9),
      'biscuits-chocolate' => (categoryAtlasAPath, 10),
      'namkeen-chips' => (categoryAtlasAPath, 11),
      'tea-coffee' => (categoryAtlasBPath, 0),
      'juices-water' => (categoryAtlasBPath, 1),
      'frozen-foods' => (categoryAtlasBPath, 2),
      'icecream-cheese' => (categoryAtlasBPath, 3),
      'oral-care' => (categoryAtlasBPath, 4),
      'bath-hand-care' => (categoryAtlasBPath, 5),
      'hair-care' => (categoryAtlasBPath, 6),
      'skin-care' => (categoryAtlasBPath, 7),
      'surface-cleaners' => (categoryAtlasBPath, 8),
      'laundry-dishwash' => (categoryAtlasBPath, 9),
      'air-waste-care' => (categoryAtlasBPath, 10),
      'diapers-wipes' => (categoryAtlasBPath, 11),
      'baby-care' => (categoryAtlasCPath, 0),
      'health-wellness' => (categoryAtlasCPath, 1),
      'dog-care' => (categoryAtlasCPath, 2),
      'cat-care' => (categoryAtlasCPath, 3),
      'food-storage-packs' || 'horeca-food-packs' => (categoryAtlasCPath, 4),
      'cups-tissues' || 'horeca-tableware' => (categoryAtlasCPath, 5),
      'shop-supplies' || 'retail-supplies' => (categoryAtlasCPath, 6),
      'school-office' || 'stationery-office' => (categoryAtlasCPath, 7),
      'sauces-spreads' => (categoryAtlasCPath, 8),
      _ => null,
    };
    if (categorySource != null) {
      return BuyV2ProductMediaSource(
        assetPath: categorySource.$1,
        cell: categorySource.$2,
        kind: BuyV2ProductMediaKind.category,
      );
    }
    return null;
  }
}

class _BuyV2ProductMediaFallback extends StatelessWidget {
  const _BuyV2ProductMediaFallback({
    super.key,
    required this.product,
    required this.borderRadius,
  });

  final BuyV2Product product;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = constraints.biggest.shortestSide;
            final iconSize = (shortest * .38).clamp(20.0, 46.0);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _fallbackIcon(product.categoryId),
                    size: iconSize,
                    color: BuyV2Colors.navy,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.visualLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BuyV2Colors.muted,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _fallbackIcon(String categoryId) {
    final category = categoryId.toLowerCase();
    if (category.contains('egg') || category.contains('poultry')) {
      return Icons.egg_alt_outlined;
    }
    if (category.contains('meat') || category.contains('seafood')) {
      return Icons.restaurant_outlined;
    }
    if (category.contains('spice') ||
        category.contains('grain') ||
        category.contains('staple')) {
      return Icons.grain_rounded;
    }
    if (category.contains('breakfast') || category.contains('instant')) {
      return Icons.breakfast_dining_outlined;
    }
    if (category.contains('biscuit') ||
        category.contains('chocolate') ||
        category.contains('namkeen') ||
        category.contains('chip')) {
      return Icons.cookie_outlined;
    }
    if (category.contains('tea') ||
        category.contains('coffee') ||
        category.contains('juice')) {
      return Icons.local_cafe_outlined;
    }
    if (category.contains('frozen') ||
        category.contains('icecream') ||
        category.contains('cheese')) {
      return Icons.ac_unit_rounded;
    }
    if (category.contains('care') ||
        category.contains('wash') ||
        category.contains('clean') ||
        category.contains('laundry')) {
      return Icons.spa_outlined;
    }
    if (category.contains('baby') ||
        category.contains('diaper') ||
        category.contains('wipe')) {
      return Icons.child_care_outlined;
    }
    if (category.contains('dog') || category.contains('cat')) {
      return Icons.pets_outlined;
    }
    if (category.contains('paper') ||
        category.contains('school') ||
        category.contains('stationery') ||
        category.contains('suppl')) {
      return Icons.inventory_2_outlined;
    }
    if (category.contains('health') ||
        category.contains('wellness') ||
        product.destination == BuyV2Destination.medicine) {
      return Icons.health_and_safety_outlined;
    }
    return Icons.inventory_2_outlined;
  }
}

BoxDecoration buyV2CardDecoration({
  Color color = Colors.white,
  Color border = BuyV2Colors.line,
  double radius = BuyV2Metrics.radius,
  bool shadow = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: shadow
        ? const [
            BoxShadow(
              color: Color(0x13000040),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ]
        : null,
  );
}

class BuyV2PromotionCard extends StatelessWidget {
  const BuyV2PromotionCard({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.accent = BuyV2Colors.orange,
    this.width = 220,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $detail',
      button: true,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: .15),
                    Colors.white,
                    BuyV2Colors.softGreen.withValues(alpha: .72),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BuyV2Colors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: .4)),
                    ),
                    child: Icon(icon, color: BuyV2Colors.navy, size: 21),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.muted,
                            fontSize: 8,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension BuyV2TextStyles on BuildContext {
  TextStyle get buyEyebrow => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: .55,
  );

  TextStyle get buyTitle => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 22,
    height: 1.08,
    fontWeight: FontWeight.w900,
    letterSpacing: -.5,
  );

  TextStyle get buyBody => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  TextStyle get buyMeta => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
}
