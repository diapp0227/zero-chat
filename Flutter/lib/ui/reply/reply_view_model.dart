import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post/post_repository_provider.dart';
import '../home/home_view_model.dart';
import '../profile/current_profile.dart';

/// 返信画面の送信の状態
///
/// 送信前・送信成功は AsyncData、送信中は AsyncLoading、失敗は AsyncError。
/// 返信画面を閉じると破棄され、次に開いたときは送信前の状態に戻る
final replyViewModelProvider =
    NotifierProvider.autoDispose<ReplyViewModel, AsyncValue<void>>(
      ReplyViewModel.new,
    );

/// 返信画面の ViewModel
///
/// 入力された返信を PostRepository で作成し、成功したらタイムラインを読み込み直す
class ReplyViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 番号 [postId] の投稿に本文 [text] で返信する。成功したら true を返す
  ///
  /// 返信した人は、ログイン中の人のプロフィール (サーバー版はサーバーがトークンから決める)
  Future<bool> submit({required int postId, required String text}) async {
    final profile = ref.read(currentProfileProvider);
    // 送信中に返信画面が閉じられても、送信が終わるまでは破棄しない
    // (破棄されると、タイムラインの読み込み直しができなくなるため)
    final keepAliveLink = ref.keepAlive();
    state = const AsyncLoading();

    try {
      state = await AsyncValue.guard<void>(() async {
        await ref
            .read(postRepositoryProvider)
            .createReply(postId: postId, text: text, author: profile);
      });

      if (state.hasError) return false;
      // 作成した返信が投稿の下に出るよう、投稿の一覧を取得し直す
      ref.invalidate(homeViewModelProvider);
      return true;
    } finally {
      keepAliveLink.close();
    }
  }
}
