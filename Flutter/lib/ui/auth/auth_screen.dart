import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../core/app_logo.dart';
import '../core/breakpoints.dart';
import '../../data/repositories/auth/auth_repository.dart';
import 'auth_failure_message.dart';
import 'auth_mode.dart';
import 'auth_view_model.dart';
import 'widgets/auth_brand_panel.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_mode_tabs.dart';
import 'widgets/auth_text_field.dart';

/// サインアップ・サインイン画面
///
/// PC (expanded 幅) では左に水色の面、右にフォームを並べたカード、
/// スマホ・タブレットでは画面いっぱいにフォームだけを表示する。
/// サインアップは「メールアドレス・パスワード → 認証コード」の2段階
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  /// パスワードの最小文字数 (入力欄のヒントに出す。Cognito のパスワードポリシーと合わせる)
  ///
  /// アプリでは文字数を確かめず、条件を満たすかの判定は Cognito に任せる
  static const minPasswordLength = 8;

  /// 認証コードの桁数
  static const verificationCodeLength = 6;

  /// サインインのときに「パスワードを忘れた方」を表示するか。
  /// パスワード再設定の画面ができるまでは非表示
  static const showForgotPassword = false;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  AuthMode _mode = AuthMode.signUp;

  /// サインアップ後、認証コードの入力待ちか
  bool _verificationPending = false;

  @override
  void initState() {
    super.initState();
    // 入力に合わせてボタンの押せる・押せないを切り替える
    for (final controller in [
      _emailController,
      _passwordController,
      _codeController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_verificationPending) {
      return _codeController.text.length == AuthScreen.verificationCodeLength;
    }
    final email = _emailController.text.trim();
    // パスワードが条件を満たすかの判定は Cognito に任せ、空でなければ送る
    return RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(email) &&
        _passwordController.text.isNotEmpty;
  }

  /// 一番下のボタンが押されたとき。サインインできたら router がホームへ移す
  Future<void> _submit() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    if (!_canSubmit || ref.read(authViewModelProvider).isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_verificationPending) {
      await viewModel.confirmAndSignIn(
        email: email,
        password: password,
        code: _codeController.text,
      );
      return;
    }

    final needsCode = switch (_mode) {
      AuthMode.signUp => await viewModel.signUp(
        email: email,
        password: password,
      ),
      // 確認がまだのアカウントでサインインしたときも、確認コードの入力へ進む
      AuthMode.signIn =>
        await viewModel.signIn(email: email, password: password) ==
            SignInOutcome.confirmationRequired,
    };
    if (needsCode && mounted) _showCodeStep();
  }

  void _showCodeStep() {
    setState(() {
      _verificationPending = true;
      _codeController.clear();
    });
  }

  Future<void> _resendCode() async {
    final sent = await ref
        .read(authViewModelProvider.notifier)
        .resendCode(email: _emailController.text.trim());
    if (sent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('認証コードを再送しました')));
    }
  }

  void _changeMode(AuthMode mode) {
    ref.read(authViewModelProvider.notifier).clearError();
    setState(() {
      _mode = mode;
      _verificationPending = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final submission = ref.watch(authViewModelProvider);
    final failure = submission.error;
    final form = _AuthForm(
      mode: _mode,
      verificationPending: _verificationPending,
      email: _emailController.text.trim(),
      emailController: _emailController,
      passwordController: _passwordController,
      codeController: _codeController,
      canSubmit: _canSubmit && !submission.isLoading,
      sending: submission.isLoading,
      errorMessage: failure is AuthFailure ? failure.reason.message : null,
      onModeChanged: _changeMode,
      onSubmit: _submit,
      onResendCode: _resendCode,
      onChangeEmail: () {
        ref.read(authViewModelProvider.notifier).clearError();
        setState(() => _verificationPending = false);
      },
      headingSize: width <= 520 ? 23 : 25,
    );

    if (ScreenSize.fromWidth(width) == ScreenSize.expanded) {
      return _DesktopLayout(form: form);
    }
    return _MobileLayout(form: form);
  }
}

/// PC の配置。薄い水色の背景の中央に、左右2列のカードを置く
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.form});

  /// 右の列に置くフォーム
  final Widget form;

  @override
  Widget build(BuildContext context) {
    // デザインではフォームの左右の余白が画面幅の 6% (42〜72px)
    final formPadding = (MediaQuery.sizeOf(context).width * 0.06).clamp(
      42.0,
      72.0,
    );

    return Scaffold(
      backgroundColor: AppColors.authPageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 960,
                    minHeight: 640,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.authCardBorder),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.authCardShadow,
                          offset: Offset(0, 24),
                          blurRadius: 70,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      // 枠線の内側で切り抜く
                      borderRadius: BorderRadius.circular(27),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(flex: 9, child: AuthBrandPanel()),
                            Expanded(
                              flex: 11,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: formPadding,
                                  vertical: 50,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [form],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// スマホ・タブレットの配置。白い画面の上端にロゴ、下寄せでフォーム
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.form});

  /// 画面下寄せで置くフォーム
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final horizontal = MediaQuery.sizeOf(context).width <= 520 ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28 + padding.top,
            horizontal,
            28 + padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight - 56 - padding.top - padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo(),
                  ),
                  // ロゴとフォームの間を空けて、フォームを画面の下に寄せる
                  const Spacer(),
                  const SizedBox(height: 46),
                  form,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 見出し・切り替えボタン・入力欄・ボタンをまとめたフォーム
class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.mode,
    required this.verificationPending,
    required this.email,
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.canSubmit,
    required this.sending,
    required this.errorMessage,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onResendCode,
    required this.onChangeEmail,
    required this.headingSize,
  });

  /// サインアップかサインインか
  final AuthMode mode;

  /// 認証コードの入力待ちか
  final bool verificationPending;

  /// 入力されたメールアドレス (認証コードの説明文に出す)
  final String email;

  /// メールアドレスの入力欄の文字
  final TextEditingController emailController;

  /// パスワードの入力欄の文字
  final TextEditingController passwordController;

  /// 認証コードの入力欄の文字
  final TextEditingController codeController;

  /// 一番下のボタンを押せるか
  final bool canSubmit;

  /// 送信中か (ボタンの文字を「送信中…」にする)
  final bool sending;

  /// 送信に失敗したときにボタンの上に出すメッセージ (なければ null)
  final String? errorMessage;

  /// 「サインアップ」「サインイン」が切り替えられたときの処理
  final ValueChanged<AuthMode> onModeChanged;

  /// 一番下のボタンが押されたときの処理
  final VoidCallback onSubmit;

  /// 「コードを再送」が押されたときの処理
  final VoidCallback onResendCode;

  /// 「メールアドレスを変更」が押されたときの処理
  final VoidCallback onChangeEmail;

  /// 見出しの文字の大きさ
  final double headingSize;

  @override
  Widget build(BuildContext context) {
    final (title, description, submitLabel) = verificationPending
        ? (
            '認証コードを入力',
            '$email に送信した${AuthScreen.verificationCodeLength}桁の認証コードを入力してください。',
            '認証してはじめる',
          )
        : switch (mode) {
            AuthMode.signUp => (
              'アカウントを作成',
              '必要な情報を入力して、Zeroをはじめましょう。',
              'アカウントを作成',
            ),
            AuthMode.signIn => ('おかえりなさい', '登録済みのアカウントでサインインしてください。', 'サインイン'),
          };

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'WELCOME TO ZERO',
            style: TextStyle(
              color: AppColors.authEyebrow,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontFamily: authSerifFontFamily,
              fontFamilyFallback: authSerifFontFallback,
              fontSize: headingSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.authSubtitle,
              fontSize: 10,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 25),
          if (!verificationPending) ...[
            AuthModeTabs(selected: mode, onSelected: onModeChanged),
            const SizedBox(height: 25),
          ],
          if (verificationPending) ...[
            AuthTextField(
              key: const ValueKey('code'),
              label: '認証コード',
              controller: codeController,
              prefix: AuthFieldPrefix.code,
              hintText: '000000',
              helperText: 'コードの有効期限は24時間です',
              autofocus: true,
              onSubmitted: onSubmit,
            ),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AuthLinkButton(label: 'メールアドレスを変更', onPressed: onChangeEmail),
                AuthLinkButton(label: 'コードを再送', onPressed: onResendCode),
              ],
            ),
          ] else ...[
            AuthTextField(
              key: const ValueKey('email'),
              label: 'メールアドレス',
              controller: emailController,
              prefix: AuthFieldPrefix.mail,
              hintText: 'name@example.com',
              autofocus: true,
              onSubmitted: onSubmit,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              key: const ValueKey('password'),
              label: 'パスワード',
              controller: passwordController,
              prefix: AuthFieldPrefix.password,
              hintText: '${AuthScreen.minPasswordLength}文字以上で入力',
              obscureText: true,
              onSubmitted: onSubmit,
            ),
            if (mode == AuthMode.signIn && AuthScreen.showForgotPassword) ...[
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerRight,
                // TODO: パスワード再設定の画面ができたら、そこへ移る
                child: AuthLinkButton(label: 'パスワードを忘れた方', onPressed: () {}),
              ),
            ],
          ],
          if (errorMessage case final message?) ...[
            const SizedBox(height: 16),
            _ErrorNotice(message: message),
          ],
          const SizedBox(height: 20),
          AuthSubmitButton(
            label: sending ? '送信中…' : submitLabel,
            onPressed: canSubmit ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

/// 送信に失敗したときのメッセージ (投稿画面のエラーと同じ色)
class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  /// 表示するメッセージ
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.composeErrorBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.composeErrorText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
