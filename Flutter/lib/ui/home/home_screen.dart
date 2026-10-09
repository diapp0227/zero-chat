import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/breakpoints.dart';

/// ホーム画面 (チャット機能は未実装)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('zero_chat')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = ScreenSize.fromWidth(constraints.maxWidth);
          return Center(child: Text('zero_chat (${size.name})'));
        },
      ),
    );
  }
}
