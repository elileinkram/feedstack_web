const int kUsernameMaxLength = 32;
const int kPostMaxLength = 512;
const int kCommentMaxLength = 180;
const int kChannelDescriptionMaxLength = 180;
const int kChannelTitleMaxLength = 64;
const double kTitleFontSize = 17.5;
const int kPasswordMinLength = 6;
const String kDefaultErrorMsg =
    'Something unexpected happened please try again later.';
const List<String> kEmailErrors = [
  'Please enter a valid email address',
  'There is already an account linked to this email address.',
  'There is no account linked to this email address.'
];
const String kPasswordError = 'Password must be at least 6 characters long';
const Map<String, String> kUsernameErrors = {
  'length': 'Username must be at least 3 characters long',
  'content': 'Username can only contain letters, numbers & underscores',
  'duplicate': 'This username is being used by somebody else'
};
const String kNotFoundError = 'user-not-found';
const List<String> kEmojis = ['😍', '😭', '🤬', '', '🙄', '🙄'];
const List<String> kDefaultProfileTabs = ['posts', 'emojis'];
const double kPanelMinHeight = 46.0 * 0.875;
const int kDefaultPostLimit = 12;
const int kDefaultTrendingLimit = 18;
const int kDefaultNotificationLimit = 12;
const int kFeedFinderBootCount = 2;
const int kDefaultFeedLimit = 12;
const double kDefaultLoadingHeight = 100.0;
const String kPrivacyPolicyURL =
    'https://firebasestorage.googleapis.com/v0/b/jasper-2ffc6.appspot.com/o/default%2Fdocuments%2Fprivacy_policy2.txt?alt=media&token=bb71f309-6c5f-4b90-b032-0c3ee341e319';
const double kPostFaceRadius = 22.5;
const int kNullActionValue = -1;
const double kPanelPadding = 100 / 9;
const int kProfileBootCount = 3;
const int kNotificationBootCount = 2;
const int kHomeBootCount = 10;
const int kDefaultUserSearchLimit = 12;
const int kDefaultChannelSearchLimit = 12;
const int kDefaultBackgroundColor = 0xFFF3F4F6;
const int kDefaultDarkBackgroundColor = 0xFF448AFF;
const int kDefaultDarkColor = 0xFF172F55;
const int kDecrementNotificationNumber = -1;
const String kPartyEmoji = '🎉';
const int kYearOfCreation = 2020;
const int kDefaultCommentLimit = 6;
const List<String> kDefaultChannelNames = [
  'Most liked',
  'Home',
];
const String kAppName = 'feedstack';
