// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get reload => 'Retry';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabOrganization => 'Organization';

  @override
  String get tabMessages => 'Messages';

  @override
  String placeholderNotImplemented(String title) {
    return '$title (coming soon)';
  }

  @override
  String get newPost => 'New post';

  @override
  String get composeButton => 'Post';

  @override
  String get profileMenu => 'Profile menu';

  @override
  String get menuProfileSettings => 'Profile settings';

  @override
  String get menuLogout => 'Log out';

  @override
  String get timelineLatest => 'Latest';

  @override
  String get categoryAnnouncement => 'Announcement';

  @override
  String get categoryDailyReport => 'Daily report';

  @override
  String get categorySelfStudy => 'Self-study';

  @override
  String get categoryAnnouncementDescription =>
      'Share updates with your team or organization';

  @override
  String get categoryDailyReportDescription =>
      'Record today\'s work and insights';

  @override
  String get categorySelfStudyDescription => 'Share what you have learned';

  @override
  String get timelineEmpty => 'No posts yet';

  @override
  String get timelineLoadFailed => 'Couldn\'t load posts';

  @override
  String get timelineLoadMoreFailed => 'Couldn\'t load more posts';

  @override
  String get filterPosts => 'Filter posts';

  @override
  String get postSave => 'Save';

  @override
  String get postUnsave => 'Remove from saved';

  @override
  String get postMoreMenu => 'More options';

  @override
  String get postShowMore => 'Show more';

  @override
  String get postReply => 'Reply';

  @override
  String postReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get elapsedJustNow => 'just now';

  @override
  String elapsedMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String elapsedHours(int hours) {
    return '${hours}h';
  }

  @override
  String get elapsedYesterday => 'Yesterday';

  @override
  String elapsedDays(int days) {
    return '${days}d';
  }

  @override
  String elapsedMonthDay(int month, int day, String monthName) {
    return '$monthName $day';
  }

  @override
  String elapsedYearMonthDay(int year, int month, int day, String monthName) {
    return '$monthName $day, $year';
  }

  @override
  String get composeBarrier => 'Close the post screen';

  @override
  String get composeCategoryTitle => 'Post type';

  @override
  String get composeCategoryHeading => 'What would you like to share?';

  @override
  String get composeCategoryDescription => 'Choose a title that fits your post';

  @override
  String composeHint(String category) {
    return 'Write your $category...';
  }

  @override
  String get composeSubmit => 'Post';

  @override
  String get composeSending => 'Posting…';

  @override
  String get composeFailed =>
      'Couldn\'t post. Please wait a moment and try again.';

  @override
  String get replyBarrier => 'Close the reply screen';

  @override
  String get replyTitle => 'Reply';

  @override
  String get replySubmit => 'Reply';

  @override
  String get replySending => 'Replying…';

  @override
  String get replyHint => 'Write your reply...';

  @override
  String get replyFailed =>
      'Couldn\'t reply. Please wait a moment and try again.';

  @override
  String replyingTo(String name) {
    return 'Replying to $name\'s post';
  }

  @override
  String get profileBarrier => 'Close profile settings';

  @override
  String get profileTitle => 'Profile settings';

  @override
  String get profileIntroTitle => 'Profile';

  @override
  String get profileIntroDescription => 'Shown with your posts on the timeline';

  @override
  String get userName => 'User name';

  @override
  String get userNameHint => 'Enter your user name';

  @override
  String get role => 'Role';

  @override
  String get color => 'Color';

  @override
  String colorOption(int number) {
    return 'Color $number';
  }

  @override
  String get language => 'Language';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save. Please wait a moment and try again.';

  @override
  String get roleEngineer => 'Engineer';

  @override
  String get roleDesigner => 'Designer';

  @override
  String get roleProductManager => 'Product manager';

  @override
  String get roleSales => 'Sales';

  @override
  String get roleCorporate => 'Corporate';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authLanguageSetting => 'Language';

  @override
  String get authSignUpTitle => 'Create an account';

  @override
  String get authSignUpDescription =>
      'Enter your details to get started with Zero.';

  @override
  String get authSignUpSubmit => 'Create account';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInDescription => 'Sign in with your registered account.';

  @override
  String get authSignInSubmit => 'Sign in';

  @override
  String get authVerifyTitle => 'Enter your verification code';

  @override
  String authVerifyDescription(String email, int digits) {
    return 'Enter the $digits-digit code we sent to $email.';
  }

  @override
  String get authVerifySubmit => 'Verify and get started';

  @override
  String get authCodeLabel => 'Verification code';

  @override
  String get authCodeHelper => 'The code is valid for 24 hours';

  @override
  String get authChangeEmail => 'Change email';

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authCodeResent => 'We\'ve resent the verification code';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String authPasswordHint(int count) {
    return 'At least $count characters';
  }

  @override
  String get authUserNameHint => 'e.g. aaaa';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authSending => 'Sending…';

  @override
  String get brandHeadline => 'Sharing\nconnects your work.';

  @override
  String get brandBody =>
      'Share everyday insights and learnings, and take your team\'s communication one step further.';

  @override
  String get brandNoteTitle => 'Small shares make a strong team.';

  @override
  String get brandNoteBody =>
      'With Zero, the information you need comes together naturally.';

  @override
  String get authErrorEmailAlreadyExists =>
      'This email is already registered. Please sign in.';

  @override
  String authErrorInvalidPassword(int count) {
    return 'Your password must be at least $count characters.';
  }

  @override
  String get authErrorWrongCredentials => 'Incorrect email or password.';

  @override
  String get authErrorCodeMismatch => 'Incorrect verification code.';

  @override
  String get authErrorCodeExpired =>
      'Your verification code has expired. Please resend the code.';

  @override
  String get authErrorCodeDeliveryFailed =>
      'We couldn\'t send the verification code. Please check your email address.';

  @override
  String get authErrorTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorNetwork =>
      'Couldn\'t connect. Check your connection and try again.';

  @override
  String get authErrorUnknown =>
      'Something went wrong. Please wait a moment and try again.';
}
