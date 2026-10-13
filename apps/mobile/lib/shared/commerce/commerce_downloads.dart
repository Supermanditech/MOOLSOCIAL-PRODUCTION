import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'commerce_invoice_document.dart';

enum CommerceDownloadKind { invoice, platformFee, summary }

class CommerceDownloadScope {
  const CommerceDownloadScope(this.account, {this.store});
  final String account;
  final String? store;
  bool get valid =>
      account.trim().isNotEmpty && (store == null || store!.trim().isNotEmpty);
  String get key => jsonEncode([account, store]);
}

class CommerceDownloadQuery {
  const CommerceDownloadQuery({
    required this.scope,
    this.search = '',
    this.kind,
    this.from,
    this.until,
  });
  final CommerceDownloadScope scope;
  final String search;
  final CommerceDownloadKind? kind;
  final DateTime? from, until;
  String get key => jsonEncode([
    scope.key,
    search,
    kind?.name,
    from?.toIso8601String(),
    until?.toIso8601String(),
  ]);
  bool matches(CommerceDownloadItem item) =>
      item.scope.key == scope.key &&
      (kind == null || item.kind == kind) &&
      (from == null || !item.date.isBefore(from!)) &&
      (until == null || item.date.isBefore(until!)) &&
      '${item.title} ${item.reference} ${item.party}'.toLowerCase().contains(
        search.trim().toLowerCase(),
      );
}

class CommerceDownloadFile {
  CommerceDownloadFile({
    required this.scope,
    required this.id,
    required Uint8List bytes,
    required this.fileName,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final CommerceDownloadScope scope;
  final String id, fileName;
  final Uint8List bytes;
  bool get valid =>
      scope.valid &&
      id.isNotEmpty &&
      bytes.length >= 8 &&
      bytes.length <= 10 * 1024 * 1024 &&
      String.fromCharCodes(bytes.take(5)) == '%PDF-' &&
      RegExp(
        r'^commerce-document-[A-Za-z0-9-]{1,128}\.pdf$',
      ).hasMatch(fileName);
}

class CommerceDownloadItem {
  const CommerceDownloadItem({
    required this.scope,
    required this.id,
    required this.kind,
    required this.title,
    required this.reference,
    required this.party,
    required this.date,
    required this.load,
    this.notice,
    this.unavailableReason,
  });
  final CommerceDownloadScope scope;
  final String id, title, reference, party;
  final CommerceDownloadKind kind;
  final DateTime date;
  final String? notice, unavailableReason;
  final Future<CommerceDownloadFile> Function() load;
}

class CommerceDownloadPage {
  CommerceDownloadPage({
    required this.queryKey,
    required List<CommerceDownloadItem> items,
    this.nextCursor,
  }) : items = List.unmodifiable(items);
  final String queryKey;
  final List<CommerceDownloadItem> items;
  final String? nextCursor;
}

abstract interface class CommerceDownloadSource {
  Future<CommerceDownloadPage> load(
    CommerceDownloadQuery query, {
    String? cursor,
  });
}

class UnavailableCommerceDownloadSource implements CommerceDownloadSource {
  const UnavailableCommerceDownloadSource();
  @override
  Future<CommerceDownloadPage> load(
    CommerceDownloadQuery query, {
    String? cursor,
  }) async => throw const FormatException(
    'Your documents are not available yet. Please try again later.',
  );
}

/// Reuses the existing Android MediaStore writer. No picker, new permission,
/// PDF re-render or share action. Unsupported platforms fail explicitly.
Future<bool> saveCommerceDownloadFile(CommerceDownloadFile file) async {
  if (!file.valid) {
    throw const FormatException('The document could not be downloaded.');
  }
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    throw const FormatException(
      'Direct downloads are currently available on Android.',
    );
  }
  try {
    final saved =
        await const MethodChannel('com.moolsocial.app/store_stock_download')
            .invokeMethod<bool>('save', {
              'bytes': file.bytes,
              'fileName': file.fileName,
              'mimeType': 'application/pdf',
            })
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw const FormatException(
                'Download could not be confirmed. Check Downloads before retrying.',
              ),
            );
    if (saved != true) {
      throw const FormatException(
        'Download could not be confirmed. Check Downloads before retrying.',
      );
    }
    return true;
  } on PlatformException {
    throw const FormatException(
      'Could not save to Downloads. Please try again.',
    );
  } on MissingPluginException {
    throw const FormatException(
      'Downloads are unavailable in this app version.',
    );
  }
}

String commerceDownloadName(String identity) {
  final safe = commerceInvoiceFileComponent(
    identity,
  ).replaceAll(RegExp('[^A-Za-z0-9-]'), '-');
  return 'commerce-document-$safe.pdf';
}
