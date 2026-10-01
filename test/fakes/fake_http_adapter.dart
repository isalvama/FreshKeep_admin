import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every request with [statusCode] and a JSON [body], and records the
/// requests it saw.
class JsonResponseAdapter implements HttpClientAdapter {
  JsonResponseAdapter({required this.statusCode, this.body});

  final int statusCode;
  final Object? body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = utf8.encode(jsonEncode(body ?? {}));
    return ResponseBody.fromBytes(
      bytes,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Fails every request the way an unreachable host (or a CORS rejection) does.
class ConnectionErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'XMLHttpRequest error',
    );
  }

  @override
  void close({bool force = false}) {}
}
