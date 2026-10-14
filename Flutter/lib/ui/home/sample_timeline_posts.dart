import 'package:flutter/painting.dart';

import 'timeline_post.dart';

// 投稿セルの見た目を確認するための仮のデータ (デザインのモック投稿と同じ内容)。
// 「投稿の情報注入」で Repository / ViewModel から取得する形に置き換える。
// デザインの画像は外部サイトの写真のため、画像は付けていない。
// 投稿・返信日時は、アプリを起動した時刻からさかのぼった日時にしている

final _now = DateTime.now();

/// 起動した時刻から [duration] だけ前の日時
DateTime _ago(Duration duration) => _now.subtract(duration);

/// タイムラインに表示する仮の投稿4件
final sampleTimelinePosts = <TimelinePost>[
  TimelinePost(
    id: 1,
    authorName: 'ぱんだ',
    authorRole: 'エンジニア',
    avatarColors: (const Color(0xFFF4A98C), const Color(0xFFD56C65)),
    postedAt: _ago(const Duration(minutes: 12)),
    title: '日報',
    text: '仕事帰り、少し遠回り。夕暮れの東京は、いつもの景色を少しだけ特別にしてくれる。',
  ),
  TimelinePost(
    id: 2,
    authorName: 'いぬ',
    authorRole: 'エンジニア',
    avatarColors: (const Color(0xFF92A9D8), const Color(0xFF536B9E)),
    postedAt: _ago(const Duration(hours: 1)),
    title: '日報',
    text: '今日はチームでコードレビュー。\n小さな改善を積み重ねる時間が、プロダクトの強さにつながる。\n丁寧に意図を共有していきたい。',
    replies: [
      TimelineReply(
        id: 3,
        authorName: 'くま',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF80C9B2), const Color(0xFF458B78)),
        repliedAt: _ago(const Duration(minutes: 45)),
        text: '意図まで共有するの、大切ですね！',
      ),
    ],
  ),
  TimelinePost(
    id: 4,
    authorName: 'ひつじ',
    authorRole: 'エンジニア',
    avatarColors: (const Color(0xFFE8BD79), const Color(0xFFB87947)),
    postedAt: _ago(const Duration(hours: 3)),
    title: 'お知らせ',
    text:
        '新しい機能のリリースに向けて、最後の調整中。\n設計を見直して、テストケースを追加。\nエラー時の表示も、もう一度確認。\n使う人が迷わない導線になっているか。\n読み込み時間は十分に短いか。\nキーボードだけでも操作できるか。\n小さな画面でも崩れないか。\nチームのみんなと一つずつチェック。\n地道な作業だけれど、この時間が好き。\n自信を持って届けられるところまで、あと少し。',
    replies: [
      TimelineReply(
        id: 5,
        authorName: 'うさぎ',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFFBF9AD8), const Color(0xFF795B9A)),
        repliedAt: _ago(const Duration(hours: 2)),
        text: 'リリース楽しみにしています。\nラストスパート、応援しています！',
      ),
      TimelineReply(
        id: 6,
        authorName: 'きりん',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF7BB5CF), const Color(0xFF47758D)),
        repliedAt: _ago(const Duration(hours: 1)),
        text: 'チェック項目がとても参考になります。\nアクセシビリティの確認も大切ですね。\n自分たちのチームにも共有してみます。',
      ),
    ],
  ),
  TimelinePost(
    id: 7,
    authorName: 'らいおん',
    authorRole: 'エンジニア',
    avatarColors: (const Color(0xFF8FBEA0), const Color(0xFF527A61)),
    postedAt: _ago(const Duration(hours: 30)),
    title: '自己学習',
    text:
        '社内の勉強会で、最近取り組んだパフォーマンス改善について共有しました。\n質問から新しい視点をもらえて、発表した側にもたくさんの学びがありました。\n次は実際の計測方法も含めてまとめてみます。',
    replies: [
      TimelineReply(
        id: 8,
        authorName: 'くま',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF80C9B2), const Color(0xFF458B78)),
        repliedAt: _ago(const Duration(hours: 2)),
        text: '勉強会の資料もぜひ読んでみたいです！',
      ),
      TimelineReply(
        id: 9,
        authorName: 'うさぎ',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFFBF9AD8), const Color(0xFF795B9A)),
        repliedAt: _ago(const Duration(hours: 3)),
        text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
      ),
      TimelineReply(
        id: 10,
        authorName: 'きりん',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF7BB5CF), const Color(0xFF47758D)),
        repliedAt: _ago(const Duration(hours: 4)),
        text:
            '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
      ),
      TimelineReply(
        id: 11,
        authorName: 'ぞう',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF80C9B2), const Color(0xFF458B78)),
        repliedAt: _ago(const Duration(hours: 5)),
        text: '勉強会の資料もぜひ読んでみたいです！',
      ),
      TimelineReply(
        id: 12,
        authorName: 'ねこ',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFFBF9AD8), const Color(0xFF795B9A)),
        repliedAt: _ago(const Duration(hours: 6)),
        text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
      ),
      TimelineReply(
        id: 13,
        authorName: 'くま',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF7BB5CF), const Color(0xFF47758D)),
        repliedAt: _ago(const Duration(hours: 7)),
        text:
            '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
      ),
      TimelineReply(
        id: 14,
        authorName: 'うさぎ',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF80C9B2), const Color(0xFF458B78)),
        repliedAt: _ago(const Duration(hours: 8)),
        text: '勉強会の資料もぜひ読んでみたいです！',
      ),
      TimelineReply(
        id: 15,
        authorName: 'きりん',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFFBF9AD8), const Color(0xFF795B9A)),
        repliedAt: _ago(const Duration(hours: 9)),
        text: '実例を交えた共有、参考になりました。\n改善前後の変化も分かりやすかったです。',
      ),
      TimelineReply(
        id: 16,
        authorName: 'ぞう',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF7BB5CF), const Color(0xFF47758D)),
        repliedAt: _ago(const Duration(hours: 10)),
        text:
            '計測方法のまとめも楽しみにしています。\nどの指標から確認するのか、\nツールをどう使い分けるのか、\n実際の判断基準も知りたいです。\n次回の共有も参加します！',
      ),
      TimelineReply(
        id: 17,
        authorName: 'ねこ',
        authorRole: 'エンジニア',
        avatarColors: (const Color(0xFF80C9B2), const Color(0xFF458B78)),
        repliedAt: _ago(const Duration(hours: 11)),
        text: '勉強会の資料もぜひ読んでみたいです！',
      ),
    ],
  ),
];
