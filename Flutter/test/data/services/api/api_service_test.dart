import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:zero_chat/data/services/api/api_service.dart';

void main() {
  const baseUrl = 'https://example.com';

  /// UTF-8 の JSON を返すレスポンス
  http.Response jsonResponse(Object body, int statusCode) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        statusCode,
        headers: {'content-type': 'application/json'},
      );

  group('HttpApiService', () {
    test('URL とクエリパラメータをつないで GET する', () async {
      Uri? requested;
      final client = MockClient((request) async {
        requested = request.url;
        expect(request.method, 'GET');
        return jsonResponse({'posts': <Object>[]}, 200);
      });

      await HttpApiService(
        baseUrl: baseUrl,
        client: client,
      ).getJson('/posts', query: {'category': 'dailyReport'});

      expect(
        requested,
        Uri.parse('https://example.com/posts?category=dailyReport'),
      );
    });

    test('クエリパラメータがなければ、URL に ? を付けない', () async {
      Uri? requested;
      final client = MockClient((request) async {
        requested = request.url;
        return jsonResponse({'posts': <Object>[]}, 200);
      });

      await HttpApiService(baseUrl: baseUrl, client: client).getJson('/posts');

      expect(requested.toString(), 'https://example.com/posts');
    });

    test('日本語を含む JSON を読める', () async {
      final client = MockClient(
        (_) async => jsonResponse({'text': '日報の本文'}, 200),
      );

      final json = await HttpApiService(
        baseUrl: baseUrl,
        client: client,
      ).getJson('/posts');

      expect(json, {'text': '日報の本文'});
    });

    test('2xx 以外なら ApiException を投げる', () async {
      final client = MockClient(
        (_) async => jsonResponse({'message': 'unknown category: foo'}, 400),
      );

      expect(
        HttpApiService(baseUrl: baseUrl, client: client).getJson('/posts'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.body, 'body', contains('unknown category')),
        ),
      );
    });

    test('本文を JSON にして POST し、201 のレスポンスの JSON を返す', () async {
      http.Request? requested;
      final client = MockClient((request) async {
        requested = request;
        return jsonResponse({
          'post': {'id': 11},
        }, 201);
      });

      final json = await HttpApiService(
        baseUrl: baseUrl,
        client: client,
      ).postJson('/posts', body: {'text': '日報の本文'});

      expect(requested!.method, 'POST');
      expect(requested!.url, Uri.parse('https://example.com/posts'));
      expect(
        requested!.headers['Content-Type'],
        startsWith('application/json'),
      );
      expect(jsonDecode(requested!.body), {'text': '日報の本文'});
      expect(json, {
        'post': {'id': 11},
      });
    });

    test('POST で 2xx 以外なら ApiException を投げる', () async {
      final client = MockClient(
        (_) async => jsonResponse({'message': 'text is required'}, 400),
      );

      expect(
        HttpApiService(
          baseUrl: baseUrl,
          client: client,
        ).postJson('/posts', body: {'text': ''}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('アクセストークンがあれば、GET と POST に Bearer で付ける', () async {
      final headers = <Map<String, String>>[];
      final client = MockClient((request) async {
        headers.add(request.headers);
        return jsonResponse({}, 200);
      });
      final service = HttpApiService(
        baseUrl: baseUrl,
        accessToken: () async => 'token123',
        client: client,
      );

      await service.getJson('/posts');
      await service.postJson('/posts', body: {'text': 'a'});

      expect(headers, hasLength(2));
      for (final h in headers) {
        expect(h['Authorization'], 'Bearer token123');
      }
    });

    test('アクセストークンが null なら Authorization を付けない', () async {
      Map<String, String>? headers;
      final client = MockClient((request) async {
        headers = request.headers;
        return jsonResponse({}, 200);
      });

      await HttpApiService(
        baseUrl: baseUrl,
        accessToken: () async => null,
        client: client,
      ).getJson('/posts');

      expect(headers!.containsKey('Authorization'), isFalse);
    });
  });
}
