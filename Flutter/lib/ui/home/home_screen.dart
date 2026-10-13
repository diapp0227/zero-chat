import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/breakpoints.dart';
import 'widgets/feed_header.dart';

/// ホーム画面 (タイムライン)
///
/// PC (expanded 幅) では上部バーがヘッダーを兼ねるので FeedHeader は出さない
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ScreenSize.fromWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (size != ScreenSize.expanded) const FeedHeader(),
          const Expanded(child: Center(child: Text('タイムライン (未実装)'))),
        ],
      ),
    );
  }
}
