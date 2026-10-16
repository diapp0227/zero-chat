import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zero_chat/data/repositories/profile/http_profile_repository.dart';
import 'package:zero_chat/data/services/api/api_service.dart';
import 'package:zero_chat/domain/models/profile.dart';

/// テスト用の ApiService。リクエストを記録し、決まった JSON を返す (または [error] を投げる)
class _TestApiService implements ApiService {
  _TestApiService({this.response, this.error});

  /// getJson・putJson で返す JSON
  final Object? response;

  /// getJson・putJson で投げるエラー (null なら投げない)
  final Exception? error;

  /// getJson に渡されたパス
  String? requestedPath;

  /// putJson に渡されたパス
  String? putPath;

  /// putJson に渡された本文
  Object? putBody;

  @override
  Future<Object?> getJson(String path, {Map<String, String>? query}) async {
    requestedPath = path;
    if (error case final error?) throw error;
    return response;
  }

  @override
  Future<Object?> postJson(String path, {required Object? body}) =>
      throw UnimplementedError();

  @override
  Future<Object?> putJson(String path, {required Object? body}) async {
    putPath = path;
    putBody = body;
    if (error case final error?) throw error;
    return response;
  }
}

void main() {
  group('HttpProfileRepository', () {
    const profileJson = {
      'profile': {
        'name': 'ああああ',
        'role': 'デザイナー',
        'color1': '#80C9B2',
        'color2': '#458B78',
        'updatedAt': '2026-10-16T09:00:00Z',
      },
    };

    test('/profile を取得して Profile に変換する', () async {
      final api = _TestApiService(response: profileJson);

      final profile = await HttpProfileRepository(api).fetchProfile();

      expect(api.requestedPath, '/profile');
      expect(profile?.name, 'ああああ');
      expect(profile?.role, 'デザイナー');
      // #RRGGBB を不透明の色として読む
      expect(profile?.color1, const Color(0xFF80C9B2));
      expect(profile?.color2, const Color(0xFF458B78));
    });

    test('404 ならまだ保存していないので null を返す', () async {
      final api = _TestApiService(
        error: const ApiException(404, '{"message": "profile not found"}'),
      );

      expect(await HttpProfileRepository(api).fetchProfile(), isNull);
    });

    test('404 以外のエラーはそのまま投げる', () async {
      final api = _TestApiService(error: const ApiException(500, ''));

      expect(
        HttpProfileRepository(api).fetchProfile(),
        throwsA(isA<ApiException>()),
      );
    });

    test('名前・役職・カラーを /profile に PUT し、返ってきた内容を返す', () async {
      final api = _TestApiService(response: profileJson);

      final saved = await HttpProfileRepository(api).updateProfile(
        const Profile(
          name: 'ああああ',
          role: 'デザイナー',
          // 透明度は送らず、#RRGGBB の大文字にする
          color1: Color(0x8080c9b2),
          color2: Color(0xFF05080A),
        ),
      );

      expect(api.putPath, '/profile');
      expect(api.putBody, {
        'name': 'ああああ',
        'role': 'デザイナー',
        'color1': '#80C9B2',
        'color2': '#05080A',
      });
      expect(saved.name, 'ああああ');
      expect(saved.color1, const Color(0xFF80C9B2));
    });
  });
}
