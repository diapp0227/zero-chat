import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_service.dart';
import 'fake_profile_repository.dart';
import 'http_profile_repository.dart';
import 'profile_repository.dart';

/// 自分のプロフィールの取得・保存に使う ProfileRepository
///
/// サーバーの URL ([apiBaseUrl]) が渡されていればサーバーを使う HttpProfileRepository、
/// 渡されていなければメモリ上だけで動く FakeProfileRepository。
/// テストでは overrides で別の実装に差し替える
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => apiBaseUrl.isEmpty
      ? FakeProfileRepository()
      : HttpProfileRepository(ref.watch(apiServiceProvider)),
);
