import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// サーバー (API Gateway) の URL。末尾の / は付けない
///
/// ビルド時に `--dart-define-from-file=config/api.json` で渡す。
/// 渡さなければ空文字で、そのときはサーバーにつながず仮のデータを使う
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// サーバーとの通信を受け持つ窓口
///
/// 通信して JSON を受け取るところまでを担当し、モデルへの変換はしない。
/// 変換は Repository が行う
abstract class ApiService {
  /// [path] に GET でリクエストし、レスポンスの JSON を返す
  ///
  /// [query] はクエリパラメータ (なければ null)。
  /// ステータスコードが 200 以外なら [ApiException] を投げる
  Future<Object?> getJson(String path, {Map<String, String>? query});
}

/// サーバーが 200 以外のステータスコードを返したときのエラー
class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  /// ステータスコード (例: 400)
  final int statusCode;

  /// レスポンスの本文 (エラーの調査用)
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// http パッケージで通信する ApiService
class HttpApiService implements ApiService {
  HttpApiService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// サーバーの URL
  final String baseUrl;

  final http.Client _client;

  /// 応答を待つ最大の時間
  static const _timeout = Duration(seconds: 10);

  @override
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri).timeout(_timeout);

    // 日本語を正しく読むため、bodyBytes を UTF-8 として読む
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, body);
    }
    return jsonDecode(body);
  }
}

/// サーバーとの通信に使う ApiService
final apiServiceProvider = Provider<ApiService>(
  (ref) => HttpApiService(baseUrl: apiBaseUrl),
);
