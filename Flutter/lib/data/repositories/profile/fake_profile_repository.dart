import '../../../domain/models/profile.dart';
import 'profile_repository.dart';

/// メモリ上だけでプロフィールを保存する ProfileRepository
///
/// サーバーの URL が渡されていないとき (開発中・テスト) に使う。アプリを閉じると消える
class FakeProfileRepository implements ProfileRepository {
  /// [profile] を渡すと、保存済みのプロフィールとして最初から持っておく
  FakeProfileRepository({Profile? profile}) : _profile = profile;

  Profile? _profile;

  @override
  Future<Profile?> fetchProfile() async => _profile;

  @override
  Future<Profile> updateProfile(Profile profile) async => _profile = profile;
}
