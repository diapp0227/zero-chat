import '../../../domain/models/profile.dart';
import '../../services/api/api_service.dart';
import '../../services/api/hex_color.dart';
import 'profile_repository.dart';

/// サーバーの API で自分のプロフィールを取得 (GET /profile)・保存 (PUT /profile) する ProfileRepository
///
/// リクエスト・レスポンスの形は docs/public/lambda/profile.md を参照
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._apiService);

  final ApiService _apiService;

  @override
  Future<Profile?> fetchProfile() async {
    try {
      final json = await _apiService.getJson('/profile');
      return _toProfile(json);
    } on ApiException catch (e) {
      // 404 はまだ保存していないだけなので、エラーにしない
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final json = await _apiService.putJson(
      '/profile',
      body: {
        'name': profile.name,
        'role': profile.role,
        'color1': hexFromColor(profile.color1),
        'color2': hexFromColor(profile.color2),
      },
    );
    // サーバーが前後の空白を除いた内容が返ってくる
    return _toProfile(json);
  }

  Profile _toProfile(Object? json) {
    final profile =
        (json as Map<String, dynamic>)['profile'] as Map<String, dynamic>;
    return Profile(
      name: profile['name'] as String,
      role: profile['role'] as String,
      color1: colorFromHex(profile['color1'] as String),
      color2: colorFromHex(profile['color2'] as String),
    );
  }
}
