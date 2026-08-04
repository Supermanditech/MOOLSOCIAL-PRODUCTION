import 'buy_v2_models.dart';

/// Deterministic, local relevance for the current Buy catalogue boundary.
///
/// Exact/literal matches always precede nearby spellings. This deliberately
/// does not infer popularity, history, personalization, inventory, service
/// availability or a backend correction. Offer IDs remain literal-only.
abstract final class BuyV2SearchRelevance {
  static final RegExp _separator = RegExp(r'[^a-z0-9]+');
  static final RegExp _offerIdQuery = RegExp(r'^[a-z]-[a-z0-9-]+$');

  static List<BuyV2Product> rankProducts(
    Iterable<BuyV2Product> products,
    String query,
  ) {
    final candidates = products.toList(growable: false);
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return candidates;

    final literalQuery = query.trim().toLowerCase();
    final offerIdOnly = _offerIdQuery.hasMatch(literalQuery);
    final ranked = <_RankedBuyV2Product>[];
    for (var index = 0; index < candidates.length; index++) {
      final product = candidates[index];
      final score = _scoreProduct(
        product,
        literalQuery: literalQuery,
        normalizedQuery: normalizedQuery,
        offerIdOnly: offerIdOnly,
      );
      if (score == null) continue;
      ranked.add(
        _RankedBuyV2Product(
          product: product,
          catalogueIndex: index,
          score: score,
        ),
      );
    }

    final hasDirectMatch = ranked.any((entry) => entry.score < 1000);
    if (hasDirectMatch) {
      ranked.removeWhere((entry) => entry.score >= 1000);
    }

    ranked.sort((left, right) {
      final relevance = left.score.compareTo(right.score);
      if (relevance != 0) return relevance;
      return left.catalogueIndex.compareTo(right.catalogueIndex);
    });
    return ranked.map((entry) => entry.product).toList(growable: false);
  }

  static int? _scoreProduct(
    BuyV2Product product, {
    required String literalQuery,
    required String normalizedQuery,
    required bool offerIdOnly,
  }) {
    final id = product.id.toLowerCase();
    if (id == literalQuery) return 0;
    if (id.startsWith(literalQuery)) return 4;
    if (id.contains(literalQuery)) return 8;
    if (offerIdOnly) return null;

    final fields = <String>[
      product.title,
      product.brand,
      product.variant,
      product.seller,
    ].map(_normalize).toList(growable: false);

    int? bestPhraseScore;
    for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
      final field = fields[fieldIndex];
      final tokens = _tokens(field);
      final score = switch (field) {
        _ when field == normalizedQuery => 10 + fieldIndex,
        _ when field.startsWith(normalizedQuery) => 20 + fieldIndex,
        _ when tokens.contains(normalizedQuery) => 30 + fieldIndex,
        _ when tokens.any((token) => token.startsWith(normalizedQuery)) =>
          40 + fieldIndex,
        _ when field.contains(normalizedQuery) => 50 + fieldIndex,
        _ => null,
      };
      if (score != null &&
          (bestPhraseScore == null || score < bestPhraseScore)) {
        bestPhraseScore = score;
      }
    }
    if (bestPhraseScore != null) return bestPhraseScore;

    final queryTokens = _tokens(normalizedQuery);
    if (queryTokens.isEmpty) return null;
    final candidateTokens = <_SearchToken>[
      for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++)
        for (final token in _tokens(fields[fieldIndex]))
          _SearchToken(value: token, fieldIndex: fieldIndex),
    ];

    var usesFuzzyMatch = false;
    var maximumQuality = 0;
    var totalQuality = 0;
    var totalEdits = 0;
    var totalFieldPriority = 0;
    for (final queryToken in queryTokens) {
      _TokenMatch? best;
      for (final candidate in candidateTokens) {
        final match = _matchToken(queryToken, candidate);
        if (match != null && (best == null || match.compareTo(best) < 0)) {
          best = match;
        }
      }
      if (best == null) return null;
      usesFuzzyMatch = usesFuzzyMatch || best.fuzzy;
      maximumQuality = maximumQuality > best.quality
          ? maximumQuality
          : best.quality;
      totalQuality += best.quality;
      totalEdits += best.edits;
      totalFieldPriority += best.fieldIndex;
    }

    final tier = usesFuzzyMatch ? 1000 : 100;
    return tier +
        maximumQuality * 100 +
        totalQuality * 10 +
        totalEdits * 3 +
        totalFieldPriority;
  }

  static _TokenMatch? _matchToken(String queryToken, _SearchToken candidate) {
    if (candidate.value == queryToken) {
      return _TokenMatch(
        quality: 0,
        edits: 0,
        fieldIndex: candidate.fieldIndex,
      );
    }
    if (candidate.value.startsWith(queryToken)) {
      return _TokenMatch(
        quality: 1,
        edits: 0,
        fieldIndex: candidate.fieldIndex,
      );
    }
    if (queryToken.length >= 3 && candidate.value.contains(queryToken)) {
      return _TokenMatch(
        quality: 2,
        edits: 0,
        fieldIndex: candidate.fieldIndex,
      );
    }

    final editCeiling = switch (queryToken.length) {
      < 4 => 0,
      <= 5 => 1,
      _ => 2,
    };
    if (editCeiling == 0 ||
        (candidate.value.length - queryToken.length).abs() > editCeiling) {
      return null;
    }
    final edits = _boundedDamerauLevenshtein(
      queryToken,
      candidate.value,
      editCeiling,
    );
    if (edits > editCeiling) return null;
    return _TokenMatch(
      quality: 3,
      edits: edits,
      fieldIndex: candidate.fieldIndex,
      fuzzy: true,
    );
  }

  static int _boundedDamerauLevenshtein(
    String source,
    String target,
    int ceiling,
  ) {
    if (source == target) return 0;
    if ((source.length - target.length).abs() > ceiling) return ceiling + 1;

    var previousPrevious = List<int>.filled(target.length + 1, 0);
    var previous = List<int>.generate(target.length + 1, (index) => index);
    for (var sourceIndex = 1; sourceIndex <= source.length; sourceIndex++) {
      final current = List<int>.filled(target.length + 1, 0);
      current[0] = sourceIndex;
      var rowMinimum = current[0];
      for (var targetIndex = 1; targetIndex <= target.length; targetIndex++) {
        final substitutionCost =
            source.codeUnitAt(sourceIndex - 1) ==
                target.codeUnitAt(targetIndex - 1)
            ? 0
            : 1;
        var distance = _minimum(
          current[targetIndex - 1] + 1,
          previous[targetIndex] + 1,
          previous[targetIndex - 1] + substitutionCost,
        );
        if (sourceIndex > 1 &&
            targetIndex > 1 &&
            source.codeUnitAt(sourceIndex - 1) ==
                target.codeUnitAt(targetIndex - 2) &&
            source.codeUnitAt(sourceIndex - 2) ==
                target.codeUnitAt(targetIndex - 1)) {
          final transposition = previousPrevious[targetIndex - 2] + 1;
          if (transposition < distance) distance = transposition;
        }
        current[targetIndex] = distance;
        if (distance < rowMinimum) rowMinimum = distance;
      }
      if (rowMinimum > ceiling) return ceiling + 1;
      previousPrevious = previous;
      previous = current;
    }
    return previous[target.length];
  }

  static int _minimum(int first, int second, int third) {
    final pairMinimum = first < second ? first : second;
    return pairMinimum < third ? pairMinimum : third;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(_separator, ' ').trim();

  static List<String> _tokens(String value) => value
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

class _RankedBuyV2Product {
  const _RankedBuyV2Product({
    required this.product,
    required this.catalogueIndex,
    required this.score,
  });

  final BuyV2Product product;
  final int catalogueIndex;
  final int score;
}

class _SearchToken {
  const _SearchToken({required this.value, required this.fieldIndex});

  final String value;
  final int fieldIndex;
}

class _TokenMatch implements Comparable<_TokenMatch> {
  const _TokenMatch({
    required this.quality,
    required this.edits,
    required this.fieldIndex,
    this.fuzzy = false,
  });

  final int quality;
  final int edits;
  final int fieldIndex;
  final bool fuzzy;

  @override
  int compareTo(_TokenMatch other) {
    final qualityOrder = quality.compareTo(other.quality);
    if (qualityOrder != 0) return qualityOrder;
    final editOrder = edits.compareTo(other.edits);
    if (editOrder != 0) return editOrder;
    return fieldIndex.compareTo(other.fieldIndex);
  }
}
