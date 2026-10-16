import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../repositories/auth/auth_repository_provider.dart';

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
  /// ステータスコードが 2xx 以外なら [ApiException] を投げる
  Future<Object?> getJson(String path, {Map<String, String>? query});

  /// [path] に [body] を JSON にして POST でリクエストし、レスポンスの JSON を返す
  ///
  /// ステータスコードが 2xx (作成成功の 201 など) 以外なら [ApiException] を投げる
  Future<Object?> postJson(String path, {required Object? body});

  /// [path] に [body] を JSON にして PUT でリクエストし、レスポンスの JSON を返す
  ///
  /// ステータスコードが 2xx 以外なら [ApiException] を投げる
  Future<Object?> putJson(String path, {required Object? body});
}

/// サーバーが 2xx 以外のステータスコードを返したときのエラー
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
  HttpApiService({required this.baseUrl, this.accessToken, http.Client? client})
    : _client = client ?? http.Client();

  /// サーバーの URL
  final String baseUrl;

  /// リクエストに付けるアクセストークン (JWT) を返す。null を返したら付けない
  ///
  /// API Gateway の JWT オーソライザーが、このトークンでサインイン済みかを確かめる
  final Future<String?> Function()? accessToken;

  final http.Client _client;

  /// 応答を待つ最大の時間
  static const _timeout = Duration(seconds: 10);

  @override
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    return _decode(response);
  }

  @override
  Future<Object?> postJson(String path, {required Object? body}) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _jsonHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  @override
  Future<Object?> putJson(String path, {required Object? body}) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl$path'),
          headers: await _jsonHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  /// JSON を送るときのヘッダー (アクセストークンがあれば認証のヘッダーも付ける)
  Future<Map<String, String>> _jsonHeaders() async => {
    'Content-Type': 'application/json; charset=utf-8',
    ...await _authHeaders(),
  };

  /// アクセストークンがあれば `Authorization: Bearer <トークン>` のヘッダーを返す
  Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken?.call();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  /// レスポンスの本文を JSON として読む。2xx 以外なら [ApiException] を投げる
  Object? _decode(http.Response response) {
    // 日本語を正しく読むため、bodyBytes を UTF-8 として読む
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, body);
    }
    return jsonDecode(body);
  }
}

/// サーバーとの通信に使う ApiService
///
/// リクエストには、サインイン中の人のアクセストークンを付ける
final apiServiceProvider = Provider<ApiService>(
  (ref) => HttpApiService(
    baseUrl: apiBaseUrl,
    accessToken: () => ref.read(authRepositoryProvider).accessToken(),
  ),
);
