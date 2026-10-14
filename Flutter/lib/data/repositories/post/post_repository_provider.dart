import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_post_repository.dart';
import 'post_repository.dart';

/// 投稿の取得に使う PostRepository
///
/// 今は仮のデータを返す FakePostRepository。
/// サーバーにつなぐときは、ここで返す実装を差し替える。
/// テストでは overrides で別の実装に差し替える
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => FakePostRepository(),
);
