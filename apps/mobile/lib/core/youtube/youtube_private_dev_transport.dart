import 'dart:async';
import 'dart:convert';
import 'dart:io';

class YouTubeHttpResponse {
  const YouTubeHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

abstract interface class YouTubeHttpTransport {
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  });

  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  });
}

class YouTubeTransportException implements Exception {
  const YouTubeTransportException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.statusCode,
  });

  final String code;
  final String message;
  final bool retryable;
  final int? statusCode;

  @override
  String toString() => 'YouTubeTransportException($code, $message)';
}

class IoYouTubeHttpTransport implements YouTubeHttpTransport {
  IoYouTubeHttpTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(minutes: 10),
    this.maximumResponseBytes = 2 * 1024 * 1024,
  }) : _client = client ?? HttpClient();

  final HttpClient _client;
  final Duration timeout;
  final Duration uploadTimeout;
  final int maximumResponseBytes;

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    final encoded = utf8.encode(jsonEncode(body));
    return _send(
      'POST',
      uri,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
        ...headers,
      },
      body: Stream<List<int>>.value(encoded),
      contentLength: encoded.length,
      operationTimeout: timeout,
    );
  }

  @override
  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  }) {
    return _send(
      'PUT',
      uri,
      headers: headers,
      body: body,
      contentLength: contentLength,
      operationTimeout: uploadTimeout,
    );
  }

  Future<YouTubeHttpResponse> _send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
    required Duration operationTimeout,
  }) async {
    if (uri.scheme != 'https') {
      throw const YouTubeTransportException(
        code: 'insecure_endpoint',
        message: 'A secure private-Dev service address is required.',
      );
    }
    try {
      final request = await _client
          .openUrl(method, uri)
          .timeout(operationTimeout);
      headers.forEach(request.headers.set);
      request.contentLength = contentLength;
      await request.addStream(body).timeout(operationTimeout);
      final response = await request.close().timeout(operationTimeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(operationTimeout)) {
        if (bytes.length + chunk.length > maximumResponseBytes) {
          throw const YouTubeTransportException(
            code: 'response_too_large',
            message: 'The provider response is too large.',
          );
        }
        bytes.addAll(chunk);
      }
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name.toLowerCase()] = values.join(',');
      });
      return YouTubeHttpResponse(
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: utf8.decode(bytes),
      );
    } on YouTubeTransportException {
      rethrow;
    } on TimeoutException {
      throw const YouTubeTransportException(
        code: 'provider_timeout',
        message: 'The provider did not respond in time.',
        retryable: true,
      );
    } on SocketException {
      throw const YouTubeTransportException(
        code: 'provider_unavailable',
        message: 'The provider is unavailable.',
        retryable: true,
      );
    } on HttpException {
      throw const YouTubeTransportException(
        code: 'provider_unavailable',
        message: 'The provider request could not be completed.',
        retryable: true,
      );
    } on FileSystemException {
      throw const YouTubeTransportException(
        code: 'media_unavailable',
        message: 'The selected video could not be read.',
      );
    }
  }

  void close({bool force = false}) {
    _client.close(force: force);
  }
}
