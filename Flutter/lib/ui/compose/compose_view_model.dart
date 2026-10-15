import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post/post_repository_provider.dart';
import '../../domain/models/post_category.dart';
import '../home/home_view_model.dart';
import '../profile/current_profile.dart';

/// 投稿画面の送信の状態
///
/// 送信前・送信成功は AsyncData、送信中は AsyncLoading、失敗は AsyncError。
/// 投稿画面を閉じると破棄され、次に開いたときは送信前の状態に戻る
final composeViewModelProvider =
    NotifierProvider.autoDispose<ComposeViewModel, AsyncValue<void>>(
      ComposeViewModel.new,
    );

/// 投稿画面の ViewModel
///
/// 入力された投稿を PostRepository で作成し、成功したらタイムラインを読み込み直す
class ComposeViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// [category] の投稿を本文 [text] で作成する。成功したら true を返す
  ///
  /// 投稿した人の名前と役職は、ログイン中の人のプロフィールを使う
  Future<bool> submit({
    required PostCategory category,
    required String text,
  }) async {
    final profile = ref.read(currentProfileProvider);
    // 送信中に投稿画面が閉じられても、送信が終わるまでは破棄しない
    // (破棄されると、タイムラインの読み込み直しができなくなるため)
    final keepAliveLink = ref.keepAlive();
    state = const AsyncLoading();

    try {
      state = await AsyncValue.guard<void>(() async {
        await ref
            .read(postRepositoryProvider)
            .createPost(
              category: category,
              text: text,
              authorName: profile.name,
              authorRole: profile.role,
            );
      });

      if (state.hasError) return false;
      // 作成した投稿がタイムラインに出るよう、投稿の一覧を取得し直す
      ref.invalidate(homeViewModelProvider);
      return true;
    } finally {
      keepAliveLink.close();
    }
  }
}
