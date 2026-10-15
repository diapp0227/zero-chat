import '../../../domain/models/author.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';
import '../../../domain/models/reply.dart';
import 'post_repository.dart';

// 投稿する人・返信する人。同じ人は同じ番号になるよう、ここで1回だけ定義する
const _panda = Author(id: 1, name: 'ぱんだ', role: 'エンジニア');
const _dog = Author(id: 2, name: 'いぬ', role: 'エンジニア');
const _sheep = Author(id: 3, name: 'ひつじ', role: 'エンジニア');
const _lion = Author(id: 4, name: 'らいおん', role: 'エンジニア');
const _bear = Author(id: 5, name: 'くま', role: 'エンジニア');
const _rabbit = Author(id: 6, name: 'うさぎ', role: 'エンジニア');
const _giraffe = Author(id: 7, name: 'きりん', role: 'エンジニア');
const _elephant = Author(id: 8, name: 'ぞう', role: 'エンジニア');
const _cat = Author(id: 9, name: 'ねこ', role: 'エンジニア');

/// 仮の投稿データを返す PostRepository (デザインのモック投稿と同じ内容)
///
/// サーバーとの通信を作るまでの代わり。
/// 投稿・返信日時は、このクラスを作った時刻からさかのぼった日時にしている。
/// createPost で作った投稿はメモリ上にだけ持ち、アプリを閉じると消える
class FakePostRepository implements PostRepository {
  /// 投稿・返信日時の基準にする時刻
  final DateTime _createdAt = DateTime.now();

  // createPost で作った投稿
  final List<Post> _createdPosts = [];

  @override
  Future<List<Post>> fetchPosts({PostCategory? category}) async {
    final posts = [
      ..._posts(),
      ..._createdPosts,
    ].where((post) => category == null || post.category == category).toList();
    posts.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return posts;
  }

  @override
  Future<Post> createPost({
    required PostCategory category,
    required String text,
    required String authorName,
    required String authorRole,
  }) async {
    final post = Post(
      id: _nextId(),
      // サーバーと同じく、ログインの仕組みができるまでは投稿した人の番号を 0 にする
      author: Author(id: 0, name: authorName, role: authorRole),
      category: category,
      text: text,
      postedAt: DateTime.now(),
    );
    _createdPosts.add(post);
    return post;
  }

  /// まだ使われていない番号 (投稿・返信の番号の最大値 + 1)
  int _nextId() {
    final ids = [
      for (final post in [..._posts(), ..._createdPosts]) ...[
        post.id,
        for (final reply in post.replies) reply.id,
      ],
    ];
    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// 基準の時刻から [duration] だけ前の日時
  DateTime _ago(Duration duration) => _createdAt.subtract(duration);

  List<Post> _posts() => [
    Post(
      id: 1,
      author: _panda,
      category: PostCategory.dailyReport,
      text: '仕事帰り、少し遠回り。夕暮れの東京は、いつもの景色を少しだけ特別にしてくれる。',
      postedAt: _ago(const Duration(minutes: 12)),
    ),
    Post(
      id: 2,
      author: _dog,
      category: PostCategory.dailyReport,
      text: '今日はチームでコードレビュー。\n小さな改善を積み重ねる時間が、プロダクトの強さにつながる。\n丁寧に意図を共有していきたい。',
      postedAt: _ago(const Duration(hours: 1)),
      replies: [
        Reply(
          id: 3,
          author: _bear,
          text: '意図まで共有するの、大切ですね！',
          repliedAt: _ago(const Duration(minutes: 45)),
        ),
      ],
    ),
    Post(
      id: 4,
      author: _sheep,
      category: PostCategory.announcement,
      text:
          '新しい機能のリリースに向けて、最後の調整中。\n設計を見直して、テストケースを追加。\nエラー時の表示も、もう一度確認。\n使う人が迷わない導線になっているか。\n読み込み時間は十分に短いか。\nキーボードだけでも操作できるか。\n小さな画面でも崩れないか。\nチームのみんなと一つずつチェック。\n地道な作業だけれど、この時間が好き。\n自信を持って届けられるところまで、あと少し。',
      postedAt: _ago(const Duration(hours: 3)),
      replies: [
        Reply(
          id: 5,
          author: _rabbit,
          text: 'リリース楽しみにしています。\nラストスパート、応援しています！',
          repliedAt: _ago(const Duration(hours: 2)),
        ),
        Reply(
          id: 6,
          author: _giraffe,
          text: 'チェック項目がとても参考になります。\nアクセシビリティの確認も大切ですね。\n自分たちのチームにも共有してみます。',
          repliedAt: _ago(const Duration(hours: 1)),
        ),
      ],
    ),
    Post(
      id: 7,
      author: _lion,
      category: PostCategory.selfStudy,
      text:
          '社内の勉強会で、最近取り組んだパフォーマンス改善について共有しました。\n質問から新しい視点をもらえて、発表した側にもたくさんの学びがありました。\n次は実際の計測方法も含めてまとめてみます。',
      postedAt: _ago(const Duration(hours: 30)),
      replies: [
        Reply(
          id: 8,
          author: _bear,
          text: '勉強会の資料もぜひ読んでみたいです！',
          repliedAt: _ago(const Duration(hours: 2)),
        ),
        Reply(
          id: 9,
          author: _rabbit,
          text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
          repliedAt: _ago(const Duration(hours: 3)),
        ),
        Reply(
          id: 10,
          author: _giraffe,
          text:
              '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
          repliedAt: _ago(const Duration(hours: 4)),
        ),
        Reply(
          id: 11,
          author: _elephant,
          text: '勉強会の資料もぜひ読んでみたいです！',
          repliedAt: _ago(const Duration(hours: 5)),
        ),
        Reply(
          id: 12,
          author: _cat,
          text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
          repliedAt: _ago(const Duration(hours: 6)),
        ),
        Reply(
          id: 13,
          author: _bear,
          text:
              '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
          repliedAt: _ago(const Duration(hours: 7)),
        ),
        Reply(
          id: 14,
          author: _rabbit,
          text: '勉強会の資料もぜひ読んでみたいです！',
          repliedAt: _ago(const Duration(hours: 8)),
        ),
        Reply(
          id: 15,
          author: _giraffe,
          text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
          repliedAt: _ago(const Duration(hours: 9)),
        ),
        Reply(
          id: 16,
          author: _elephant,
          text:
              '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
          repliedAt: _ago(const Duration(hours: 10)),
        ),
        Reply(
          id: 17,
          author: _cat,
          text: '勉強会の資料もぜひ読んでみたいです！',
          repliedAt: _ago(const Duration(hours: 11)),
        ),
      ],
    ),
  ];
}
