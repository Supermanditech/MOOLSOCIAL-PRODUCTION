import 'dart:async';

import 'package:flutter/services.dart';

class WorkPdfPreviewException implements Exception {
  const WorkPdfPreviewException(this.message);
  final String message;
}

class WorkPdfPage {
  const WorkPdfPage({
    required this.bytes,
    required this.index,
    required this.pageCount,
    required this.width,
    required this.height,
  });
  final Uint8List bytes;
  final int index, pageCount, width, height;
}

/// One bounded local renderer; does not accept file paths or remote URLs.
class WorkPdfPreview {
  static const _channel = MethodChannel(
    'com.moolsocial.app/work_document_preview',
  );
  static int _nextId = 0;
  String? _activeId;
  bool _closed = false;

  Future<WorkPdfPage> render(Uint8List bytes, {required int page}) async {
    if (_closed) {
      throw const WorkPdfPreviewException('This document preview is closed.');
    }
    if (_activeId != null) {
      throw const WorkPdfPreviewException('Wait for this page to open.');
    }
    if (bytes.length < 5 ||
        bytes.length > 10 * 1024 * 1024 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-' ||
        page < 0 ||
        page >= 500) {
      throw const WorkPdfPreviewException(
        'This PDF could not be opened. Choose another copy.',
      );
    }
    final id = 'work_pdf_${_nextId++}';
    _activeId = id;
    try {
      final result = await _channel
          .invokeMapMethod<String, Object?>('renderPage', {
            'bytes': bytes,
            'page': page,
            'width': 1280,
            'requestId': id,
          })
          .timeout(const Duration(seconds: 22));
      if (_closed || _activeId != id) {
        throw const WorkPdfPreviewException('This document preview is closed.');
      }
      final image = result?['bytes'];
      final count = result?['pages'];
      final width = result?['width'];
      final height = result?['height'];
      if (image is! Uint8List ||
          image.length < 24 ||
          image.length > 10 * 1024 * 1024 ||
          !_isPng(image) ||
          result?['page'] != page ||
          count is! int ||
          count < 1 ||
          count > 500 ||
          page >= count ||
          width is! int ||
          height is! int ||
          width < 1 ||
          width > 1280 ||
          height < 1 ||
          height > 2048 ||
          width * height > 2000000 ||
          ByteData.sublistView(image).getUint32(16) != width ||
          ByteData.sublistView(image).getUint32(20) != height) {
        throw const WorkPdfPreviewException(
          'This PDF page could not be displayed. Try again.',
        );
      }
      return WorkPdfPage(
        bytes: image,
        index: page,
        pageCount: count,
        width: width,
        height: height,
      );
    } on MissingPluginException {
      throw const WorkPdfPreviewException(
        'PDF preview is unavailable on this device. You can replace the document.',
      );
    } on PlatformException catch (error) {
      throw WorkPdfPreviewException(
        error.code == 'protected_pdf'
            ? 'This PDF is password-protected. Choose an unlocked copy.'
            : error.code == 'preview_timeout'
            ? 'This page is taking too long. Try again or choose another copy.'
            : 'This PDF page could not be opened. Try again or choose another copy.',
      );
    } on TimeoutException {
      await _cancel(id);
      throw const WorkPdfPreviewException(
        'This page is taking too long. Try again or choose another copy.',
      );
    } on WorkPdfPreviewException {
      rethrow;
    } on Object {
      throw const WorkPdfPreviewException(
        'This PDF page could not be displayed. Try again or choose another copy.',
      );
    } finally {
      if (_activeId == id) _activeId = null;
    }
  }

  static bool _isPng(Uint8List bytes) {
    const header = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var index = 0; index < header.length; index++) {
      if (bytes[index] != header[index]) return false;
    }
    return true;
  }

  Future<void> _cancel(String id) async {
    try {
      await _channel
          .invokeMethod<void>('cancel', {'requestId': id})
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Disposal never substitutes success or blocks the user's Back action.
    }
  }

  void dispose() {
    _closed = true;
    final id = _activeId;
    _activeId = null;
    if (id != null) unawaited(_cancel(id));
  }
}
