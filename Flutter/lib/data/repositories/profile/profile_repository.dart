import '../../../domain/models/profile.dart';

/// サインインしている人の、自分のプロフィールを取得・保存する窓口
///
/// 誰のプロフィールかは、サインインの情報 (アクセストークン) で決まる
abstract class ProfileRepository {
  /// 自分のプロフィールを取得する。まだ保存していなければ null を返す
  Future<Profile?> fetchProfile();

  /// 自分のプロフィールを [profile] で保存し (なければ作成)、保存した内容を返す
  Future<Profile> updateProfile(Profile profile);
}
