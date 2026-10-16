import '../../../domain/models/author.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/post_category.dart';
import '../../../domain/models/post_page.dart';
import '../../../domain/models/profile.dart';
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
/// createPost で作った投稿と createReply で作った返信はメモリ上にだけ持ち、アプリを閉じると消える
class FakePostRepository implements PostRepository {
  /// [pageSize] は 1 回で返す投稿の最大件数 (サーバーと同じ 10 件)
  FakePostRepository({this.pageSize = 10});

  /// 1 回で返す投稿の最大件数
  final int pageSize;

  /// 投稿・返信日時の基準にする時刻
  final DateTime _createdAt = DateTime.now();

  // createPost で作った投稿
  final List<Post> _createdPosts = [];

  // createReply で作った返信 (投稿の番号ごと)
  final Map<int, List<Reply>> _createdReplies = {};

  @override
  Future<PostPage> fetchPosts({PostCategory? category, String? cursor}) async {
    final posts = [..._posts(), ..._createdPosts]
        .where((post) => category == null || post.category == category)
        .map(_withCreatedReplies)
        .toList();
    posts.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    // 目印は「何件目から読むか」の数字にする (サーバーの目印とは中身が違うが、アプリからは同じに見える)
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, posts.length);
    return PostPage(
      posts: posts.sublist(start.clamp(0, posts.length), end),
      nextCursor: end < posts.length ? '$end' : null,
    );
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

  @override
  Future<Reply> createReply({
    required int postId,
    required String text,
    required Profile author,
  }) async {
    final post = [
      ..._posts(),
      ..._createdPosts,
    ].where((post) => post.id == postId).firstOrNull;
    if (post == null) throw ArgumentError.value(postId, 'postId', '投稿がありません');

    final reply = Reply(
      id: _nextId(),
      // サーバーと同じく、返信した人の番号は 0 にしてプロフィールの名前・役職・色を使う
      author: Author(
        id: 0,
        name: author.name,
        role: author.role,
        avatarColors: author.avatarColors,
      ),
      text: text,
      repliedAt: DateTime.now(),
    );
    _createdReplies.putIfAbsent(postId, () => []).add(reply);
    return reply;
  }

  /// [post] の返信の最後に、createReply で作った返信を足した投稿
  Post _withCreatedReplies(Post post) {
    final created = _createdReplies[post.id];
    if (created == null) return post;
    return Post(
      id: post.id,
      author: post.author,
      category: post.category,
      text: post.text,
      postedAt: post.postedAt,
      replies: [...post.replies, ...created],
    );
  }

  /// まだ使われていない番号 (投稿・返信の番号の最大値 + 1)
  int _nextId() {
    final ids = [
      for (final post in [..._posts(), ..._createdPosts]) ...[
        post.id,
        for (final reply in post.replies) reply.id,
      ],
      for (final replies in _createdReplies.values)
        for (final reply in replies) reply.id,
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
