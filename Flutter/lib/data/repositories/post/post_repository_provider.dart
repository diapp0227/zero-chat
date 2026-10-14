import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_service.dart';
import 'fake_post_repository.dart';
import 'http_post_repository.dart';
import 'post_repository.dart';

/// 投稿の取得に使う PostRepository
///
/// サーバーの URL ([apiBaseUrl]) が渡されていればサーバーから取得する HttpPostRepository、
/// 渡されていなければ仮のデータを返す FakePostRepository。
/// テストでは overrides で別の実装に差し替える
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => apiBaseUrl.isEmpty
      ? FakePostRepository()
      : HttpPostRepository(ref.watch(apiServiceProvider)),
);
