import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'BiteSync'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinue;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonSaveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get commonSaveChanges;

  /// No description provided for @commonSaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get commonSaving;

  /// No description provided for @commonView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get commonView;

  /// No description provided for @commonMember.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get commonMember;

  /// No description provided for @commonUnnamedMember.
  ///
  /// In zh, this message translates to:
  /// **'未命名成员'**
  String get commonUnnamedMember;

  /// No description provided for @commonDefaultUser.
  ///
  /// In zh, this message translates to:
  /// **'BiteSync 用户'**
  String get commonDefaultUser;

  /// No description provided for @commonUncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get commonUncategorized;

  /// No description provided for @commonSeconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get commonSeconds;

  /// No description provided for @commonAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get commonAll;

  /// No description provided for @commonKilocaloriesUnit.
  ///
  /// In zh, this message translates to:
  /// **'kcal'**
  String get commonKilocaloriesUnit;

  /// No description provided for @commonGramsUnit.
  ///
  /// In zh, this message translates to:
  /// **'g'**
  String get commonGramsUnit;

  /// No description provided for @commonProtein.
  ///
  /// In zh, this message translates to:
  /// **'蛋白质'**
  String get commonProtein;

  /// No description provided for @commonFat.
  ///
  /// In zh, this message translates to:
  /// **'脂肪'**
  String get commonFat;

  /// No description provided for @commonListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get commonListSeparator;

  /// No description provided for @commonErrorSeparator.
  ///
  /// In zh, this message translates to:
  /// **'；'**
  String get commonErrorSeparator;

  /// No description provided for @commonGramsValue.
  ///
  /// In zh, this message translates to:
  /// **'{grams}g'**
  String commonGramsValue(int grams);

  /// No description provided for @commonCaloriesValue.
  ///
  /// In zh, this message translates to:
  /// **'{calories} kcal'**
  String commonCaloriesValue(String calories);

  /// No description provided for @navToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get navToday;

  /// No description provided for @navRecord.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get navRecord;

  /// No description provided for @navTraining.
  ///
  /// In zh, this message translates to:
  /// **'训练'**
  String get navTraining;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navProfile;

  /// No description provided for @authTagline.
  ///
  /// In zh, this message translates to:
  /// **'轻松记录每一餐，掌握每日营养'**
  String get authTagline;

  /// No description provided for @authSigningIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中…'**
  String get authSigningIn;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In zh, this message translates to:
  /// **'使用 Google 登录'**
  String get authSignInWithGoogle;

  /// No description provided for @authSignOut.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get authSignOut;

  /// No description provided for @authDeleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除账号'**
  String get authDeleteAccount;

  /// No description provided for @authDeleteAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除账号？'**
  String get authDeleteAccountTitle;

  /// No description provided for @authDeleteAccountDescription.
  ///
  /// In zh, this message translates to:
  /// **'账号将永久删除，BiteSync 中属于你的数据会被删除，此操作无法撤销。'**
  String get authDeleteAccountDescription;

  /// No description provided for @authDeleteAccountConnectedDescription.
  ///
  /// In zh, this message translates to:
  /// **'账号将永久删除，BiteSync 中属于你的数据会被删除。你们的配对会同时结束，但不会删除 Ta 的账号和属于 Ta 的数据。此操作无法撤销。'**
  String get authDeleteAccountConnectedDescription;

  /// No description provided for @authDeleteAccountConfirm.
  ///
  /// In zh, this message translates to:
  /// **'永久删除账号'**
  String get authDeleteAccountConfirm;

  /// No description provided for @authDeleteAccountFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除账号失败，请稍后重试'**
  String get authDeleteAccountFailed;

  /// No description provided for @authRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法验证登录状态，请重试'**
  String get authRestoreFailed;

  /// No description provided for @authSessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get authSessionExpired;

  /// No description provided for @authSignInFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请重试'**
  String get authSignInFailed;

  /// No description provided for @authGoogleNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'Google 登录尚未配置（缺少 GOOGLE_CLIENT_ID），请联系开发者'**
  String get authGoogleNotConfigured;

  /// No description provided for @authGoogleCredentialMissing.
  ///
  /// In zh, this message translates to:
  /// **'未获取到 Google 登录凭证，请重试'**
  String get authGoogleCredentialMissing;

  /// No description provided for @authSignInCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消登录'**
  String get authSignInCancelled;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In zh, this message translates to:
  /// **'Google 登录失败：{description}'**
  String authGoogleSignInFailed(String description);

  /// No description provided for @accountPrivacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号与隐私'**
  String get accountPrivacyTitle;

  /// No description provided for @accountPrivacyLoginMethod.
  ///
  /// In zh, this message translates to:
  /// **'当前登录方式：Google'**
  String get accountPrivacyLoginMethod;

  /// No description provided for @accountPrivacyPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get accountPrivacyPrivacyPolicy;

  /// No description provided for @accountPrivacyTerms.
  ///
  /// In zh, this message translates to:
  /// **'使用条款'**
  String get accountPrivacyTerms;

  /// No description provided for @accountPrivacyAiData.
  ///
  /// In zh, this message translates to:
  /// **'AI 数据处理'**
  String get accountPrivacyAiData;

  /// No description provided for @accountPrivacyAiDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'你提交的文字和图片可能会发送给 AI 服务，用于生成营养估算；不会用于训练你的个人画像。'**
  String get accountPrivacyAiDataDescription;

  /// No description provided for @accountPrivacyAccountData.
  ///
  /// In zh, this message translates to:
  /// **'账号数据'**
  String get accountPrivacyAccountData;

  /// No description provided for @accountPrivacyAccountDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'你的资料、饮食和训练记录会与账号关联，并可在删除账号时一并删除。'**
  String get accountPrivacyAccountDataDescription;

  /// No description provided for @accountPrivacyDeleteDescription.
  ///
  /// In zh, this message translates to:
  /// **'永久删除账号及属于你的数据'**
  String get accountPrivacyDeleteDescription;

  /// No description provided for @mealHistoricalReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'历史配对记录仅供查看'**
  String get mealHistoricalReadOnly;

  /// No description provided for @todayExpandCalendar.
  ///
  /// In zh, this message translates to:
  /// **'展开日历'**
  String get todayExpandCalendar;

  /// No description provided for @todayCollapseCalendar.
  ///
  /// In zh, this message translates to:
  /// **'收起日历'**
  String get todayCollapseCalendar;

  /// No description provided for @errorInvalidRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求参数有误，请检查后重试'**
  String get errorInvalidRequest;

  /// No description provided for @errorForbidden.
  ///
  /// In zh, this message translates to:
  /// **'暂无权限'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'请求的内容不存在'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In zh, this message translates to:
  /// **'这条记录已在其他设备被修改，请刷新后重试'**
  String get errorConflict;

  /// No description provided for @errorServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器开小差了，请稍后重试'**
  String get errorServer;

  /// No description provided for @errorNetworkRetry.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络后重试'**
  String get errorNetworkRetry;

  /// No description provided for @errorMalformedData.
  ///
  /// In zh, this message translates to:
  /// **'数据格式异常，请稍后重试'**
  String get errorMalformedData;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'出错了，请稍后重试'**
  String get errorUnknown;

  /// No description provided for @errorOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请稍后重试'**
  String get errorOperationFailed;

  /// No description provided for @errorCannotSaveNow.
  ///
  /// In zh, this message translates to:
  /// **'当前无法保存，请稍后重试'**
  String get errorCannotSaveNow;

  /// No description provided for @pairTitle.
  ///
  /// In zh, this message translates to:
  /// **'我和 Ta'**
  String get pairTitle;

  /// No description provided for @pairIntro.
  ///
  /// In zh, this message translates to:
  /// **'先创建一个配对，或输入Ta发来的邀请码。'**
  String get pairIntro;

  /// No description provided for @pairSingleTitle.
  ///
  /// In zh, this message translates to:
  /// **'一起记录，会更有意思'**
  String get pairSingleTitle;

  /// No description provided for @pairSingleDescription.
  ///
  /// In zh, this message translates to:
  /// **'邀请 Ta 后，可以一起查看饮食和营养记录。'**
  String get pairSingleDescription;

  /// No description provided for @pairInvitePartner.
  ///
  /// In zh, this message translates to:
  /// **'邀请 Ta'**
  String get pairInvitePartner;

  /// No description provided for @pairEnterInviteCode.
  ///
  /// In zh, this message translates to:
  /// **'输入邀请码'**
  String get pairEnterInviteCode;

  /// No description provided for @pairPendingTitle.
  ///
  /// In zh, this message translates to:
  /// **'等待 Ta 加入'**
  String get pairPendingTitle;

  /// No description provided for @pairPendingDescription.
  ///
  /// In zh, this message translates to:
  /// **'把邀请码分享给 Ta，Ta 加入后就会自动连接。'**
  String get pairPendingDescription;

  /// No description provided for @pairConnectedTitle.
  ///
  /// In zh, this message translates to:
  /// **'你们已连接'**
  String get pairConnectedTitle;

  /// No description provided for @pairCurrentDetailsHint.
  ///
  /// In zh, this message translates to:
  /// **'查看当前配对详情。'**
  String get pairCurrentDetailsHint;

  /// No description provided for @pairDetails.
  ///
  /// In zh, this message translates to:
  /// **'配对详情'**
  String get pairDetails;

  /// No description provided for @pairInviteCode.
  ///
  /// In zh, this message translates to:
  /// **'邀请码'**
  String get pairInviteCode;

  /// No description provided for @pairCopyInviteCode.
  ///
  /// In zh, this message translates to:
  /// **'复制邀请码'**
  String get pairCopyInviteCode;

  /// No description provided for @pairInviteCodeCopied.
  ///
  /// In zh, this message translates to:
  /// **'邀请码已复制'**
  String get pairInviteCodeCopied;

  /// No description provided for @pairShareInvite.
  ///
  /// In zh, this message translates to:
  /// **'分享邀请码'**
  String get pairShareInvite;

  /// No description provided for @pairShareInviteText.
  ///
  /// In zh, this message translates to:
  /// **'来和我一起用 BiteSync 记录饮食吧。邀请码：{inviteCode}'**
  String pairShareInviteText(String inviteCode);

  /// No description provided for @pairRegenerateInvite.
  ///
  /// In zh, this message translates to:
  /// **'重新生成邀请码'**
  String get pairRegenerateInvite;

  /// No description provided for @pairRegenerateTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新生成邀请码？'**
  String get pairRegenerateTitle;

  /// No description provided for @pairRegenerateDescription.
  ///
  /// In zh, this message translates to:
  /// **'旧邀请码会立即失效，之前分享出去的邀请码将无法再使用。'**
  String get pairRegenerateDescription;

  /// No description provided for @pairRegenerateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'邀请码已更新'**
  String get pairRegenerateSuccess;

  /// No description provided for @pairCancelInvite.
  ///
  /// In zh, this message translates to:
  /// **'取消邀请'**
  String get pairCancelInvite;

  /// No description provided for @pairCancelTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消邀请？'**
  String get pairCancelTitle;

  /// No description provided for @pairCancelDescription.
  ///
  /// In zh, this message translates to:
  /// **'当前邀请码会失效。你仍然可以继续一个人使用 BiteSync。'**
  String get pairCancelDescription;

  /// No description provided for @pairCancelConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认取消'**
  String get pairCancelConfirm;

  /// No description provided for @pairCancelSuccess.
  ///
  /// In zh, this message translates to:
  /// **'邀请已取消'**
  String get pairCancelSuccess;

  /// No description provided for @pairEnd.
  ///
  /// In zh, this message translates to:
  /// **'解除配对'**
  String get pairEnd;

  /// No description provided for @pairEndTitle.
  ///
  /// In zh, this message translates to:
  /// **'解除配对？'**
  String get pairEndTitle;

  /// No description provided for @pairEndDescription.
  ///
  /// In zh, this message translates to:
  /// **'解除后，你和 Ta 都会回到单人模式。之前的饮食记录会保留，以后仍可以重新配对。'**
  String get pairEndDescription;

  /// No description provided for @pairEndConfirm.
  ///
  /// In zh, this message translates to:
  /// **'解除配对'**
  String get pairEndConfirm;

  /// No description provided for @pairEndSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已解除配对'**
  String get pairEndSuccess;

  /// No description provided for @pairLifecycleConflict.
  ///
  /// In zh, this message translates to:
  /// **'当前配对状态已经变化，请刷新后重试'**
  String get pairLifecycleConflict;

  /// No description provided for @pairWaitingForPartner.
  ///
  /// In zh, this message translates to:
  /// **'等待Ta加入'**
  String get pairWaitingForPartner;

  /// No description provided for @pairConnected.
  ///
  /// In zh, this message translates to:
  /// **'已完成配对'**
  String get pairConnected;

  /// No description provided for @pairMyInfo.
  ///
  /// In zh, this message translates to:
  /// **'我的信息'**
  String get pairMyInfo;

  /// No description provided for @pairPartnerInfo.
  ///
  /// In zh, this message translates to:
  /// **'Ta信息'**
  String get pairPartnerInfo;

  /// No description provided for @pairEnterHome.
  ///
  /// In zh, this message translates to:
  /// **'进入主页'**
  String get pairEnterHome;

  /// No description provided for @pairCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建配对'**
  String get pairCreate;

  /// No description provided for @pairJoin.
  ///
  /// In zh, this message translates to:
  /// **'加入配对'**
  String get pairJoin;

  /// No description provided for @pairFull.
  ///
  /// In zh, this message translates to:
  /// **'这个配对已经有两位成员了'**
  String get pairFull;

  /// No description provided for @pairAlreadyJoined.
  ///
  /// In zh, this message translates to:
  /// **'你已经加入配对，不能重复操作'**
  String get pairAlreadyJoined;

  /// No description provided for @pairConflict.
  ///
  /// In zh, this message translates to:
  /// **'当前配对状态发生冲突，请刷新后重试'**
  String get pairConflict;

  /// No description provided for @pairInvalidInviteCode.
  ///
  /// In zh, this message translates to:
  /// **'邀请码无效或已失效，请检查后重试'**
  String get pairInvalidInviteCode;

  /// No description provided for @pairOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'配对操作失败，请稍后重试'**
  String get pairOperationFailed;

  /// No description provided for @profileLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载用户资料'**
  String get profileLoading;

  /// No description provided for @profileUnnamed.
  ///
  /// In zh, this message translates to:
  /// **'未设置显示名'**
  String get profileUnnamed;

  /// No description provided for @profileDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'用户显示名'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameTooLong.
  ///
  /// In zh, this message translates to:
  /// **'用户名最多 8 个字符'**
  String get profileDisplayNameTooLong;

  /// No description provided for @profileCharacter.
  ///
  /// In zh, this message translates to:
  /// **'我的形象'**
  String get profileCharacter;

  /// No description provided for @characterPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的形象'**
  String get characterPageTitle;

  /// No description provided for @characterSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get characterSave;

  /// No description provided for @characterSaved.
  ///
  /// In zh, this message translates to:
  /// **'形象已更新'**
  String get characterSaved;

  /// No description provided for @characterSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'形象保存失败，请重试'**
  String get characterSaveFailed;

  /// No description provided for @profileSave.
  ///
  /// In zh, this message translates to:
  /// **'保存资料'**
  String get profileSave;

  /// No description provided for @profileThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get profileThemeMode;

  /// No description provided for @profileThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get profileThemeDark;

  /// No description provided for @profileNutritionGoals.
  ///
  /// In zh, this message translates to:
  /// **'营养目标'**
  String get profileNutritionGoals;

  /// No description provided for @profileTrainingPlan.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get profileTrainingPlan;

  /// No description provided for @profilePairing.
  ///
  /// In zh, this message translates to:
  /// **'Ta与配对'**
  String get profilePairing;

  /// No description provided for @profilePairSection.
  ///
  /// In zh, this message translates to:
  /// **'我和 Ta'**
  String get profilePairSection;

  /// No description provided for @profilePairWaiting.
  ///
  /// In zh, this message translates to:
  /// **'已创建配对，等待Ta加入'**
  String get profilePairWaiting;

  /// No description provided for @profilePairSingle.
  ///
  /// In zh, this message translates to:
  /// **'未配对'**
  String get profilePairSingle;

  /// No description provided for @profilePairPending.
  ///
  /// In zh, this message translates to:
  /// **'等待 Ta 加入'**
  String get profilePairPending;

  /// No description provided for @profilePairedWith.
  ///
  /// In zh, this message translates to:
  /// **'已和 {partnerName} 连接'**
  String profilePairedWith(String partnerName);

  /// No description provided for @profilePairLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取配对状态'**
  String get profilePairLoading;

  /// No description provided for @profileNotPaired.
  ///
  /// In zh, this message translates to:
  /// **'尚未配对'**
  String get profileNotPaired;

  /// No description provided for @profileSaved.
  ///
  /// In zh, this message translates to:
  /// **'用户资料已保存'**
  String get profileSaved;

  /// No description provided for @profileLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'用户资料加载失败，请重试'**
  String get profileLoadFailed;

  /// No description provided for @profileSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'用户资料保存失败，请重试'**
  String get profileSaveFailed;

  /// No description provided for @goalsDescription.
  ///
  /// In zh, this message translates to:
  /// **'设置你的每日热量和营养素目标。'**
  String get goalsDescription;

  /// No description provided for @goalsDailyCalories.
  ///
  /// In zh, this message translates to:
  /// **'每日热量'**
  String get goalsDailyCalories;

  /// No description provided for @goalsProtein.
  ///
  /// In zh, this message translates to:
  /// **'Protein'**
  String get goalsProtein;

  /// No description provided for @goalsCarbs.
  ///
  /// In zh, this message translates to:
  /// **'Carbs'**
  String get goalsCarbs;

  /// No description provided for @goalsFat.
  ///
  /// In zh, this message translates to:
  /// **'Fat'**
  String get goalsFat;

  /// No description provided for @goalsSave.
  ///
  /// In zh, this message translates to:
  /// **'保存营养目标'**
  String get goalsSave;

  /// No description provided for @goalsInvalidValue.
  ///
  /// In zh, this message translates to:
  /// **'请输入大于等于 0 的有效数值'**
  String get goalsInvalidValue;

  /// No description provided for @goalsSaved.
  ///
  /// In zh, this message translates to:
  /// **'营养目标已保存'**
  String get goalsSaved;

  /// No description provided for @goalsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'营养目标加载失败，请重试'**
  String get goalsLoadFailed;

  /// No description provided for @goalsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'营养目标保存失败，请重试'**
  String get goalsSaveFailed;

  /// No description provided for @todayDateFormat.
  ///
  /// In zh, this message translates to:
  /// **'yyyy年M月d日 EEEE'**
  String get todayDateFormat;

  /// No description provided for @todayMonthFormat.
  ///
  /// In zh, this message translates to:
  /// **'yyyy年M月'**
  String get todayMonthFormat;

  /// No description provided for @todayWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'一|二|三|四|五|六|日'**
  String get todayWeekdays;

  /// No description provided for @todayBackToToday.
  ///
  /// In zh, this message translates to:
  /// **'回到今天'**
  String get todayBackToToday;

  /// No description provided for @todayPreviousMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get todayPreviousMonth;

  /// No description provided for @todayNextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下个月'**
  String get todayNextMonth;

  /// No description provided for @todayMyIntake.
  ///
  /// In zh, this message translates to:
  /// **'我的今日摄入'**
  String get todayMyIntake;

  /// No description provided for @todayMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get todayMe;

  /// No description provided for @todayPartnerIntake.
  ///
  /// In zh, this message translates to:
  /// **'Ta今日摄入'**
  String get todayPartnerIntake;

  /// No description provided for @todayRecords.
  ///
  /// In zh, this message translates to:
  /// **'今日记录'**
  String get todayRecords;

  /// No description provided for @todayEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有记录，去记一笔吧'**
  String get todayEmpty;

  /// No description provided for @todayLogFirstMeal.
  ///
  /// In zh, this message translates to:
  /// **'记录第一餐'**
  String get todayLogFirstMeal;

  /// No description provided for @todayInvitePartner.
  ///
  /// In zh, this message translates to:
  /// **'邀请 Ta 一起记录'**
  String get todayInvitePartner;

  /// No description provided for @todayAdjustPortion.
  ///
  /// In zh, this message translates to:
  /// **'调整份量'**
  String get todayAdjustPortion;

  /// No description provided for @todayEditDirectly.
  ///
  /// In zh, this message translates to:
  /// **'直接编辑'**
  String get todayEditDirectly;

  /// No description provided for @todayReestimateWithNote.
  ///
  /// In zh, this message translates to:
  /// **'补充说明再估算'**
  String get todayReestimateWithNote;

  /// No description provided for @todayRecordUpdated.
  ///
  /// In zh, this message translates to:
  /// **'记录已更新'**
  String get todayRecordUpdated;

  /// No description provided for @todayPortionUpdated.
  ///
  /// In zh, this message translates to:
  /// **'份量已更新'**
  String get todayPortionUpdated;

  /// No description provided for @todayReestimated.
  ///
  /// In zh, this message translates to:
  /// **'已重新估算并更新'**
  String get todayReestimated;

  /// No description provided for @todayRecordDeleted.
  ///
  /// In zh, this message translates to:
  /// **'记录已删除'**
  String get todayRecordDeleted;

  /// No description provided for @todayName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get todayName;

  /// No description provided for @todayBaseCalories.
  ///
  /// In zh, this message translates to:
  /// **'基础卡路里'**
  String get todayBaseCalories;

  /// No description provided for @todayBaseProtein.
  ///
  /// In zh, this message translates to:
  /// **'基础蛋白质'**
  String get todayBaseProtein;

  /// No description provided for @todayBaseCarbs.
  ///
  /// In zh, this message translates to:
  /// **'基础碳水'**
  String get todayBaseCarbs;

  /// No description provided for @todayBaseFat.
  ///
  /// In zh, this message translates to:
  /// **'基础脂肪'**
  String get todayBaseFat;

  /// No description provided for @todayInvalidMealValues.
  ///
  /// In zh, this message translates to:
  /// **'请填写名称和大于等于 0 的有效营养数值'**
  String get todayInvalidMealValues;

  /// No description provided for @todayReestimateHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：米饭其实只有半碗'**
  String get todayReestimateHint;

  /// No description provided for @todayNoteRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入补充说明'**
  String get todayNoteRequired;

  /// No description provided for @todayReestimate.
  ///
  /// In zh, this message translates to:
  /// **'重新估算'**
  String get todayReestimate;

  /// No description provided for @todayDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这条记录？'**
  String get todayDeleteTitle;

  /// No description provided for @todayDeleteDescription.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复。'**
  String get todayDeleteDescription;

  /// No description provided for @todayConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get todayConfirmDelete;

  /// No description provided for @todayManageMeal.
  ///
  /// In zh, this message translates to:
  /// **'管理{mealName}'**
  String todayManageMeal(String mealName);

  /// No description provided for @todayProteinGrams.
  ///
  /// In zh, this message translates to:
  /// **'蛋白 {grams}g'**
  String todayProteinGrams(int grams);

  /// No description provided for @todayCarbsGrams.
  ///
  /// In zh, this message translates to:
  /// **'碳水 {grams}g'**
  String todayCarbsGrams(int grams);

  /// No description provided for @todayFatGrams.
  ///
  /// In zh, this message translates to:
  /// **'脂肪 {grams}g'**
  String todayFatGrams(int grams);

  /// No description provided for @todayLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，请重试'**
  String get todayLoadFailed;

  /// No description provided for @todayPortionRatio.
  ///
  /// In zh, this message translates to:
  /// **'{ratio}x'**
  String todayPortionRatio(String ratio);

  /// No description provided for @todayIntakeCalories.
  ///
  /// In zh, this message translates to:
  /// **'{name} {calories}'**
  String todayIntakeCalories(String name, int calories);

  /// No description provided for @todayCalorieGoal.
  ///
  /// In zh, this message translates to:
  /// **'/ {calories} kcal'**
  String todayCalorieGoal(int calories);

  /// No description provided for @recordQuerying.
  ///
  /// In zh, this message translates to:
  /// **'查询中…'**
  String get recordQuerying;

  /// No description provided for @recordRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'识别中…'**
  String get recordRecognizing;

  /// No description provided for @recordEstimating.
  ///
  /// In zh, this message translates to:
  /// **'正在估算这份料理'**
  String get recordEstimating;

  /// No description provided for @recordFoodName.
  ///
  /// In zh, this message translates to:
  /// **'食物名称'**
  String get recordFoodName;

  /// No description provided for @recordManual.
  ///
  /// In zh, this message translates to:
  /// **'手动记录'**
  String get recordManual;

  /// No description provided for @recordCaloriesRequired.
  ///
  /// In zh, this message translates to:
  /// **'卡路里 *'**
  String get recordCaloriesRequired;

  /// No description provided for @recordKilocaloriesHint.
  ///
  /// In zh, this message translates to:
  /// **'千卡'**
  String get recordKilocaloriesHint;

  /// No description provided for @recordCarbohydrates.
  ///
  /// In zh, this message translates to:
  /// **'碳水化合物'**
  String get recordCarbohydrates;

  /// No description provided for @recordZeroGrams.
  ///
  /// In zh, this message translates to:
  /// **'0 克'**
  String get recordZeroGrams;

  /// No description provided for @recordGenerate.
  ///
  /// In zh, this message translates to:
  /// **'生成记录'**
  String get recordGenerate;

  /// No description provided for @recordYesterdayPrompt.
  ///
  /// In zh, this message translates to:
  /// **'今天也吃了？'**
  String get recordYesterdayPrompt;

  /// No description provided for @recordAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get recordAdd;

  /// No description provided for @recordFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get recordFavorite;

  /// No description provided for @recordUnfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get recordUnfavorite;

  /// No description provided for @recordFavoriteLimit.
  ///
  /// In zh, this message translates to:
  /// **'收藏最多 5 个'**
  String get recordFavoriteLimit;

  /// No description provided for @recordFavoriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'收藏失败'**
  String get recordFavoriteFailed;

  /// No description provided for @recordUnfavoriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏失败'**
  String get recordUnfavoriteFailed;

  /// No description provided for @recordRecognitionComplete.
  ///
  /// In zh, this message translates to:
  /// **'识别完成'**
  String get recordRecognitionComplete;

  /// No description provided for @recordMacroSummary.
  ///
  /// In zh, this message translates to:
  /// **'蛋白质 {protein}g  ·  碳水 {carbs}g  ·  脂肪 {fat}g'**
  String recordMacroSummary(String protein, String carbs, String fat);

  /// No description provided for @recordDishes.
  ///
  /// In zh, this message translates to:
  /// **'菜品：{dishNames}'**
  String recordDishes(String dishNames);

  /// No description provided for @recordAiDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'AI 估算，仅供参考'**
  String get recordAiDisclaimer;

  /// No description provided for @recordPartnerRequired.
  ///
  /// In zh, this message translates to:
  /// **'Ta 还没有加入，暂时只能记录自己的饮食。'**
  String get recordPartnerRequired;

  /// No description provided for @recordRecognizeWithNote.
  ///
  /// In zh, this message translates to:
  /// **'补充说明再识别'**
  String get recordRecognizeWithNote;

  /// No description provided for @recordEditData.
  ///
  /// In zh, this message translates to:
  /// **'手动改数据'**
  String get recordEditData;

  /// No description provided for @recordAmountQuestion.
  ///
  /// In zh, this message translates to:
  /// **'吃了多少？'**
  String get recordAmountQuestion;

  /// No description provided for @recordPortionHalf.
  ///
  /// In zh, this message translates to:
  /// **'1/2'**
  String get recordPortionHalf;

  /// No description provided for @recordPortionTwoThirds.
  ///
  /// In zh, this message translates to:
  /// **'2/3'**
  String get recordPortionTwoThirds;

  /// No description provided for @recordPortionOneThird.
  ///
  /// In zh, this message translates to:
  /// **'1/3'**
  String get recordPortionOneThird;

  /// No description provided for @recordShareQuestion.
  ///
  /// In zh, this message translates to:
  /// **'这顿要同步给 Ta 吗？'**
  String get recordShareQuestion;

  /// No description provided for @recordWhoAteQuestion.
  ///
  /// In zh, this message translates to:
  /// **'这是谁吃的？'**
  String get recordWhoAteQuestion;

  /// No description provided for @recordShareMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get recordShareMe;

  /// No description provided for @recordShareSolo.
  ///
  /// In zh, this message translates to:
  /// **'只记录给我'**
  String get recordShareSolo;

  /// No description provided for @recordSharePartnerOnly.
  ///
  /// In zh, this message translates to:
  /// **'只给 Ta 记'**
  String get recordSharePartnerOnly;

  /// No description provided for @recordShareTogether.
  ///
  /// In zh, this message translates to:
  /// **'一起吃'**
  String get recordShareTogether;

  /// No description provided for @recordShareHalf.
  ///
  /// In zh, this message translates to:
  /// **'一人一半'**
  String get recordShareHalf;

  /// No description provided for @recordShareMeOneThird.
  ///
  /// In zh, this message translates to:
  /// **'我 1/3 · Ta 2/3'**
  String get recordShareMeOneThird;

  /// No description provided for @recordShareMeTwoThirds.
  ///
  /// In zh, this message translates to:
  /// **'我 2/3 · Ta 1/3'**
  String get recordShareMeTwoThirds;

  /// No description provided for @recordSharePreview.
  ///
  /// In zh, this message translates to:
  /// **'分配预览：我 {myCalories} kcal  {partnerName} {partnerCalories} kcal'**
  String recordSharePreview(
    String myCalories,
    String partnerName,
    String partnerCalories,
  );

  /// No description provided for @recordSaving.
  ///
  /// In zh, this message translates to:
  /// **'记录中…'**
  String get recordSaving;

  /// No description provided for @recordThisMeal.
  ///
  /// In zh, this message translates to:
  /// **'记录这一餐'**
  String get recordThisMeal;

  /// No description provided for @recordRetake.
  ///
  /// In zh, this message translates to:
  /// **'重新拍摄'**
  String get recordRetake;

  /// No description provided for @recordReselect.
  ///
  /// In zh, this message translates to:
  /// **'重新选择'**
  String get recordReselect;

  /// No description provided for @recordTakeMeal.
  ///
  /// In zh, this message translates to:
  /// **'拍一餐'**
  String get recordTakeMeal;

  /// No description provided for @recordTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get recordTakePhoto;

  /// No description provided for @recordChooseGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get recordChooseGallery;

  /// No description provided for @recordImageTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片太大，请重新选择'**
  String get recordImageTooLarge;

  /// No description provided for @recordCaloriesMustBePositive.
  ///
  /// In zh, this message translates to:
  /// **'请填写大于 0 的卡路里'**
  String get recordCaloriesMustBePositive;

  /// No description provided for @recordYesterdayFilled.
  ///
  /// In zh, this message translates to:
  /// **'已填入昨天的记录，可修改后生成'**
  String get recordYesterdayFilled;

  /// No description provided for @recordSaved.
  ///
  /// In zh, this message translates to:
  /// **'已记录'**
  String get recordSaved;

  /// No description provided for @recordHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'饭前拍一下，轻轻记录这一餐'**
  String get recordHeroSubtitle;

  /// No description provided for @recordDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'描述食物，或拍照前补充说明'**
  String get recordDescriptionHint;

  /// No description provided for @recordSendDescription.
  ///
  /// In zh, this message translates to:
  /// **'发送文字描述'**
  String get recordSendDescription;

  /// No description provided for @recordCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get recordCollapse;

  /// No description provided for @recordManualMeal.
  ///
  /// In zh, this message translates to:
  /// **'手动记录一餐'**
  String get recordManualMeal;

  /// No description provided for @recordCorrectionHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：米饭实际只有半碗'**
  String get recordCorrectionHint;

  /// No description provided for @recordRecognizeAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新识别'**
  String get recordRecognizeAgain;

  /// No description provided for @recordImageRecognitionUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'图片识别暂不可用'**
  String get recordImageRecognitionUnavailable;

  /// No description provided for @recordNetworkFailed.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络'**
  String get recordNetworkFailed;

  /// No description provided for @recordUnsupportedImage.
  ///
  /// In zh, this message translates to:
  /// **'暂不支持这张图片格式'**
  String get recordUnsupportedImage;

  /// No description provided for @recordAiUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'AI 服务暂时不可用，请稍后重试'**
  String get recordAiUnavailable;

  /// No description provided for @recordRecognitionFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别失败，请重新尝试'**
  String get recordRecognitionFailed;

  /// No description provided for @recordAiEstimateFailed.
  ///
  /// In zh, this message translates to:
  /// **'AI 估算失败，请稍后重试'**
  String get recordAiEstimateFailed;

  /// No description provided for @mealReestimateUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这条记录暂不支持重新估算'**
  String get mealReestimateUnsupported;

  /// No description provided for @mealProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在处理，请稍候'**
  String get mealProcessing;

  /// No description provided for @mealConflict.
  ///
  /// In zh, this message translates to:
  /// **'这条记录已经在其他地方被修改，请刷新后重试'**
  String get mealConflict;

  /// No description provided for @mealInvalidChange.
  ///
  /// In zh, this message translates to:
  /// **'修改内容有误，请检查后重试'**
  String get mealInvalidChange;

  /// No description provided for @macroCarbs.
  ///
  /// In zh, this message translates to:
  /// **'碳水'**
  String get macroCarbs;

  /// No description provided for @trainingLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载本周训练'**
  String get trainingLoading;

  /// No description provided for @trainingWeekRange.
  ///
  /// In zh, this message translates to:
  /// **'本周 {start} - {end}'**
  String trainingWeekRange(String start, String end);

  /// No description provided for @trainingEditPlan.
  ///
  /// In zh, this message translates to:
  /// **'编辑训练计划'**
  String get trainingEditPlan;

  /// No description provided for @trainingHistory.
  ///
  /// In zh, this message translates to:
  /// **'训练历史'**
  String get trainingHistory;

  /// No description provided for @trainingDayEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这天没有训练计划'**
  String get trainingDayEmpty;

  /// No description provided for @trainingViewVideo.
  ///
  /// In zh, this message translates to:
  /// **'查看教学视频'**
  String get trainingViewVideo;

  /// No description provided for @trainingProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度：{completed} / {target} 组'**
  String trainingProgress(int completed, int target);

  /// No description provided for @trainingRemovedFromTemplate.
  ///
  /// In zh, this message translates to:
  /// **'已从当前模板移除'**
  String get trainingRemovedFromTemplate;

  /// No description provided for @trainingCompleteSet.
  ///
  /// In zh, this message translates to:
  /// **'完成一组'**
  String get trainingCompleteSet;

  /// No description provided for @trainingSetCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成一组'**
  String get trainingSetCompleted;

  /// No description provided for @trainingSetUpdated.
  ///
  /// In zh, this message translates to:
  /// **'该组记录已更新'**
  String get trainingSetUpdated;

  /// No description provided for @trainingCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get trainingCompleted;

  /// No description provided for @trainingSetPerformance.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 组  {performance}'**
  String trainingSetPerformance(int index, String performance);

  /// No description provided for @trainingHistorySetTime.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 组 · {time}'**
  String trainingHistorySetTime(int index, String time);

  /// No description provided for @trainingEditSetTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑第 {index} 组 · {exerciseName}'**
  String trainingEditSetTitle(int index, String exerciseName);

  /// No description provided for @trainingClearFieldHint.
  ///
  /// In zh, this message translates to:
  /// **'清空字段后保存，会删除该项记录值。'**
  String get trainingClearFieldHint;

  /// No description provided for @trainingWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'重量 kg'**
  String get trainingWeightKg;

  /// No description provided for @trainingReps.
  ///
  /// In zh, this message translates to:
  /// **'次数 reps'**
  String get trainingReps;

  /// No description provided for @trainingDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'时长（分钟）'**
  String get trainingDurationMinutes;

  /// No description provided for @trainingNote.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get trainingNote;

  /// No description provided for @trainingRpe.
  ///
  /// In zh, this message translates to:
  /// **'RPE'**
  String get trainingRpe;

  /// No description provided for @trainingRpeHint.
  ///
  /// In zh, this message translates to:
  /// **'1 - 10'**
  String get trainingRpeHint;

  /// No description provided for @trainingWeightRepsValue.
  ///
  /// In zh, this message translates to:
  /// **'{weight} kg × {reps}'**
  String trainingWeightRepsValue(String weight, int reps);

  /// No description provided for @trainingWeightValue.
  ///
  /// In zh, this message translates to:
  /// **'{weight} kg'**
  String trainingWeightValue(String weight);

  /// No description provided for @trainingRepsValue.
  ///
  /// In zh, this message translates to:
  /// **'{reps} reps'**
  String trainingRepsValue(int reps);

  /// No description provided for @trainingRpeValue.
  ///
  /// In zh, this message translates to:
  /// **'RPE {rpe}'**
  String trainingRpeValue(String rpe);

  /// No description provided for @trainingCompleteSetTitle.
  ///
  /// In zh, this message translates to:
  /// **'完成一组 · {exerciseName}'**
  String trainingCompleteSetTitle(String exerciseName);

  /// No description provided for @trainingRpeOptional.
  ///
  /// In zh, this message translates to:
  /// **'RPE（可选）'**
  String get trainingRpeOptional;

  /// No description provided for @trainingNoteOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get trainingNoteOptional;

  /// No description provided for @trainingConfirmComplete.
  ///
  /// In zh, this message translates to:
  /// **'确认完成'**
  String get trainingConfirmComplete;

  /// No description provided for @trainingInvalidEditWeight.
  ///
  /// In zh, this message translates to:
  /// **'重量请输入 0 到 10000，或留空'**
  String get trainingInvalidEditWeight;

  /// No description provided for @trainingInvalidEditReps.
  ///
  /// In zh, this message translates to:
  /// **'次数请输入 0 到 9999，或留空'**
  String get trainingInvalidEditReps;

  /// No description provided for @trainingInvalidEditRpe.
  ///
  /// In zh, this message translates to:
  /// **'RPE 请输入 1 到 10，或留空'**
  String get trainingInvalidEditRpe;

  /// No description provided for @trainingInvalidDurationParts.
  ///
  /// In zh, this message translates to:
  /// **'时长请输入有效的分钟和 0 到 59 秒'**
  String get trainingInvalidDurationParts;

  /// No description provided for @trainingInvalidOptionalDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长需为 1 秒到 1440 分钟，或全部清空'**
  String get trainingInvalidOptionalDuration;

  /// No description provided for @trainingInvalidWeight.
  ///
  /// In zh, this message translates to:
  /// **'请输入 0 到 10000 之间的重量'**
  String get trainingInvalidWeight;

  /// No description provided for @trainingInvalidReps.
  ///
  /// In zh, this message translates to:
  /// **'请输入 0 到 9999 之间的次数'**
  String get trainingInvalidReps;

  /// No description provided for @trainingInvalidRpe.
  ///
  /// In zh, this message translates to:
  /// **'RPE 请输入 1 到 10 之间的数值'**
  String get trainingInvalidRpe;

  /// No description provided for @trainingInvalidBlankDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长需为 1 秒到 1440 分钟，或全部留空'**
  String get trainingInvalidBlankDuration;

  /// No description provided for @trainingLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练计划加载失败，请重试'**
  String get trainingLoadFailed;

  /// No description provided for @trainingDataNotLoaded.
  ///
  /// In zh, this message translates to:
  /// **'训练数据尚未加载，请稍后重试'**
  String get trainingDataNotLoaded;

  /// No description provided for @trainingCheckInRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'该组已记录，但刷新失败。请保持当前内容并重试'**
  String get trainingCheckInRefreshFailed;

  /// No description provided for @trainingTargetComplete.
  ///
  /// In zh, this message translates to:
  /// **'目标组数已完成，请刷新后查看最新进度'**
  String get trainingTargetComplete;

  /// No description provided for @trainingCheckInFailed.
  ///
  /// In zh, this message translates to:
  /// **'打卡失败，请检查网络后重试'**
  String get trainingCheckInFailed;

  /// No description provided for @trainingEditRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'该组已更新，但刷新失败。请保持当前内容并重试'**
  String get trainingEditRefreshFailed;

  /// No description provided for @trainingEditFailed.
  ///
  /// In zh, this message translates to:
  /// **'修改失败，请检查网络后重试'**
  String get trainingEditFailed;

  /// No description provided for @trainingDeleteSet.
  ///
  /// In zh, this message translates to:
  /// **'删除这组记录'**
  String get trainingDeleteSet;

  /// No description provided for @trainingDeleteSetTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这组训练记录？'**
  String get trainingDeleteSetTitle;

  /// No description provided for @trainingDeleteSetDescription.
  ///
  /// In zh, this message translates to:
  /// **'删除后，本组打卡数据将被移除。'**
  String get trainingDeleteSetDescription;

  /// No description provided for @trainingDeleteSetSuccess.
  ///
  /// In zh, this message translates to:
  /// **'训练记录已删除'**
  String get trainingDeleteSetSuccess;

  /// No description provided for @trainingDeleteSetFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败，请检查网络后重试'**
  String get trainingDeleteSetFailed;

  /// No description provided for @trainingTemplateDescription.
  ///
  /// In zh, this message translates to:
  /// **'设置每周固定训练。保存模板后，可由你决定是否同步到本周。'**
  String get trainingTemplateDescription;

  /// No description provided for @trainingRestDay.
  ///
  /// In zh, this message translates to:
  /// **'休息日'**
  String get trainingRestDay;

  /// No description provided for @trainingExerciseCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个动作'**
  String trainingExerciseCount(int count);

  /// No description provided for @trainingAddExercise.
  ///
  /// In zh, this message translates to:
  /// **'新增动作'**
  String get trainingAddExercise;

  /// No description provided for @trainingSavePlan.
  ///
  /// In zh, this message translates to:
  /// **'保存训练计划'**
  String get trainingSavePlan;

  /// No description provided for @trainingSyncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中…'**
  String get trainingSyncing;

  /// No description provided for @trainingSaveBeforeSync.
  ///
  /// In zh, this message translates to:
  /// **'请先保存再同步'**
  String get trainingSaveBeforeSync;

  /// No description provided for @trainingSyncWeek.
  ///
  /// In zh, this message translates to:
  /// **'同步到本周'**
  String get trainingSyncWeek;

  /// No description provided for @trainingPlanSaved.
  ///
  /// In zh, this message translates to:
  /// **'训练计划已保存'**
  String get trainingPlanSaved;

  /// No description provided for @trainingSyncedWeek.
  ///
  /// In zh, this message translates to:
  /// **'已同步到本周'**
  String get trainingSyncedWeek;

  /// No description provided for @trainingExerciseNameInvalid.
  ///
  /// In zh, this message translates to:
  /// **'动作名称需为 1 到 100 个字符'**
  String get trainingExerciseNameInvalid;

  /// No description provided for @trainingCategoryTooLong.
  ///
  /// In zh, this message translates to:
  /// **'分类不能超过 50 个字符'**
  String get trainingCategoryTooLong;

  /// No description provided for @trainingTargetSetsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'目标组数请输入 1 到 50'**
  String get trainingTargetSetsInvalid;

  /// No description provided for @trainingTargetRepsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'目标次数请输入 0 到 999'**
  String get trainingTargetRepsInvalid;

  /// No description provided for @trainingTargetWeightInvalid.
  ///
  /// In zh, this message translates to:
  /// **'目标重量请输入 0 到 10000'**
  String get trainingTargetWeightInvalid;

  /// No description provided for @trainingTargetDurationInvalid.
  ///
  /// In zh, this message translates to:
  /// **'目标时长需为 1 秒到 1440 分钟'**
  String get trainingTargetDurationInvalid;

  /// No description provided for @trainingExerciseName.
  ///
  /// In zh, this message translates to:
  /// **'动作名称'**
  String get trainingExerciseName;

  /// No description provided for @trainingExerciseCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get trainingExerciseCategory;

  /// No description provided for @trainingExerciseType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get trainingExerciseType;

  /// No description provided for @trainingExerciseTypeValue.
  ///
  /// In zh, this message translates to:
  /// **'类型：{type}'**
  String trainingExerciseTypeValue(String type);

  /// No description provided for @trainingTargetSets.
  ///
  /// In zh, this message translates to:
  /// **'目标组数'**
  String get trainingTargetSets;

  /// No description provided for @trainingTargetReps.
  ///
  /// In zh, this message translates to:
  /// **'目标次数'**
  String get trainingTargetReps;

  /// No description provided for @trainingTargetWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'目标重量 kg'**
  String get trainingTargetWeightKg;

  /// No description provided for @trainingTargetDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'目标时长（分钟）'**
  String get trainingTargetDurationMinutes;

  /// No description provided for @trainingSaveExercise.
  ///
  /// In zh, this message translates to:
  /// **'保存动作'**
  String get trainingSaveExercise;

  /// No description provided for @trainingTypeStrength.
  ///
  /// In zh, this message translates to:
  /// **'力量'**
  String get trainingTypeStrength;

  /// No description provided for @trainingTypeDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get trainingTypeDuration;

  /// No description provided for @trainingTypeCardio.
  ///
  /// In zh, this message translates to:
  /// **'有氧'**
  String get trainingTypeCardio;

  /// No description provided for @trainingTemplateSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练计划保存失败，请重试'**
  String get trainingTemplateSaveFailed;

  /// No description provided for @trainingTemplateSyncUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前无法同步，请稍后重试'**
  String get trainingTemplateSyncUnavailable;

  /// No description provided for @trainingTemplateSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步到本周失败，请重试'**
  String get trainingTemplateSyncFailed;

  /// No description provided for @trainingHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有训练历史'**
  String get trainingHistoryEmpty;

  /// No description provided for @trainingDetails.
  ///
  /// In zh, this message translates to:
  /// **'训练详情'**
  String get trainingDetails;

  /// No description provided for @trainingDetailsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练详情加载失败，请重试'**
  String get trainingDetailsLoadFailed;

  /// No description provided for @trainingSetsProgress.
  ///
  /// In zh, this message translates to:
  /// **'{completed} / {target} 组'**
  String trainingSetsProgress(int completed, int target);

  /// No description provided for @trainingDateSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · {date}'**
  String trainingDateSuffix(String date);

  /// No description provided for @trainingShortDateFormat.
  ///
  /// In zh, this message translates to:
  /// **'M/d'**
  String get trainingShortDateFormat;

  /// No description provided for @trainingMonthDayFormat.
  ///
  /// In zh, this message translates to:
  /// **'M月d日'**
  String get trainingMonthDayFormat;

  /// No description provided for @trainingTimeFormat.
  ///
  /// In zh, this message translates to:
  /// **'HH:mm'**
  String get trainingTimeFormat;

  /// No description provided for @trainingDateRange.
  ///
  /// In zh, this message translates to:
  /// **'{start} - {end}'**
  String trainingDateRange(String start, String end);

  /// No description provided for @trainingIncompleteSets.
  ///
  /// In zh, this message translates to:
  /// **'未完成训练组'**
  String get trainingIncompleteSets;

  /// No description provided for @trainingHistoryLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练历史加载失败，请重试'**
  String get trainingHistoryLoadFailed;

  /// No description provided for @trainingWeekdayMonday.
  ///
  /// In zh, this message translates to:
  /// **'周一'**
  String get trainingWeekdayMonday;

  /// No description provided for @trainingWeekdayTuesday.
  ///
  /// In zh, this message translates to:
  /// **'周二'**
  String get trainingWeekdayTuesday;

  /// No description provided for @trainingWeekdayWednesday.
  ///
  /// In zh, this message translates to:
  /// **'周三'**
  String get trainingWeekdayWednesday;

  /// No description provided for @trainingWeekdayThursday.
  ///
  /// In zh, this message translates to:
  /// **'周四'**
  String get trainingWeekdayThursday;

  /// No description provided for @trainingWeekdayFriday.
  ///
  /// In zh, this message translates to:
  /// **'周五'**
  String get trainingWeekdayFriday;

  /// No description provided for @trainingWeekdaySaturday.
  ///
  /// In zh, this message translates to:
  /// **'周六'**
  String get trainingWeekdaySaturday;

  /// No description provided for @trainingWeekdaySunday.
  ///
  /// In zh, this message translates to:
  /// **'周日'**
  String get trainingWeekdaySunday;

  /// No description provided for @trainingPickerTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择训练动作'**
  String get trainingPickerTitle;

  /// No description provided for @trainingCustomFill.
  ///
  /// In zh, this message translates to:
  /// **'自定义填写'**
  String get trainingCustomFill;

  /// No description provided for @trainingSystemExercises.
  ///
  /// In zh, this message translates to:
  /// **'系统动作'**
  String get trainingSystemExercises;

  /// No description provided for @trainingMyExercises.
  ///
  /// In zh, this message translates to:
  /// **'我的动作'**
  String get trainingMyExercises;

  /// No description provided for @trainingSearchSystemHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索中文或英文名称'**
  String get trainingSearchSystemHint;

  /// No description provided for @trainingSearchMyHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索动作名称或分类'**
  String get trainingSearchMyHint;

  /// No description provided for @trainingSystemExerciseSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{englishName} · {category}\n{target}'**
  String trainingSystemExerciseSubtitle(
    String englishName,
    String category,
    String target,
  );

  /// No description provided for @trainingCustomExerciseSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{category} · {type}\n{target}'**
  String trainingCustomExerciseSubtitle(
    String category,
    String type,
    String target,
  );

  /// No description provided for @trainingExerciseTargetWithCategory.
  ///
  /// In zh, this message translates to:
  /// **'{target} · {category}'**
  String trainingExerciseTargetWithCategory(String target, String category);

  /// No description provided for @trainingManageVideo.
  ///
  /// In zh, this message translates to:
  /// **'管理教学视频'**
  String get trainingManageVideo;

  /// No description provided for @trainingMyExercisesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有我的动作'**
  String get trainingMyExercisesEmpty;

  /// No description provided for @trainingNoMatchingExercises.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的动作'**
  String get trainingNoMatchingExercises;

  /// No description provided for @trainingEditExercise.
  ///
  /// In zh, this message translates to:
  /// **'编辑动作'**
  String get trainingEditExercise;

  /// No description provided for @trainingDeleteExercise.
  ///
  /// In zh, this message translates to:
  /// **'删除动作'**
  String get trainingDeleteExercise;

  /// No description provided for @trainingExerciseAdded.
  ///
  /// In zh, this message translates to:
  /// **'动作已新增'**
  String get trainingExerciseAdded;

  /// No description provided for @trainingExerciseUpdated.
  ///
  /// In zh, this message translates to:
  /// **'动作已更新'**
  String get trainingExerciseUpdated;

  /// No description provided for @trainingDeleteExerciseTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除动作？'**
  String get trainingDeleteExerciseTitle;

  /// No description provided for @trainingDeleteExerciseDescription.
  ///
  /// In zh, this message translates to:
  /// **'删除后不会影响已经保存的训练计划和历史记录。'**
  String get trainingDeleteExerciseDescription;

  /// No description provided for @trainingExerciseDeleted.
  ///
  /// In zh, this message translates to:
  /// **'动作已删除'**
  String get trainingExerciseDeleted;

  /// No description provided for @trainingDefaultSetsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'默认组数请输入 1 到 50'**
  String get trainingDefaultSetsInvalid;

  /// No description provided for @trainingDefaultRepsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'默认次数请输入 0 到 999'**
  String get trainingDefaultRepsInvalid;

  /// No description provided for @trainingDefaultWeightInvalid.
  ///
  /// In zh, this message translates to:
  /// **'默认重量请输入 0 到 10000'**
  String get trainingDefaultWeightInvalid;

  /// No description provided for @trainingDefaultDurationInvalid.
  ///
  /// In zh, this message translates to:
  /// **'默认时长需为 1 秒到 1440 分钟'**
  String get trainingDefaultDurationInvalid;

  /// No description provided for @trainingAddMyExercise.
  ///
  /// In zh, this message translates to:
  /// **'新增我的动作'**
  String get trainingAddMyExercise;

  /// No description provided for @trainingEditMyExercise.
  ///
  /// In zh, this message translates to:
  /// **'编辑我的动作'**
  String get trainingEditMyExercise;

  /// No description provided for @trainingDefaultSets.
  ///
  /// In zh, this message translates to:
  /// **'默认组数'**
  String get trainingDefaultSets;

  /// No description provided for @trainingDefaultReps.
  ///
  /// In zh, this message translates to:
  /// **'默认次数'**
  String get trainingDefaultReps;

  /// No description provided for @trainingDefaultWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'默认重量 kg'**
  String get trainingDefaultWeightKg;

  /// No description provided for @trainingDefaultDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'默认时长（分钟）'**
  String get trainingDefaultDurationMinutes;

  /// No description provided for @trainingCustomLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'我的动作加载失败，请重试'**
  String get trainingCustomLoadFailed;

  /// No description provided for @trainingCustomAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'新增动作失败，请重试'**
  String get trainingCustomAddFailed;

  /// No description provided for @trainingCustomEditFailed.
  ///
  /// In zh, this message translates to:
  /// **'编辑动作失败，请重试'**
  String get trainingCustomEditFailed;

  /// No description provided for @trainingCustomDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除动作失败，请重试'**
  String get trainingCustomDeleteFailed;

  /// No description provided for @trainingExerciseLibraryNotReady.
  ///
  /// In zh, this message translates to:
  /// **'动作库尚未就绪，请稍后重试'**
  String get trainingExerciseLibraryNotReady;

  /// No description provided for @trainingExerciseMissing.
  ///
  /// In zh, this message translates to:
  /// **'动作已不存在，列表已刷新'**
  String get trainingExerciseMissing;

  /// No description provided for @trainingVideoTitle.
  ///
  /// In zh, this message translates to:
  /// **'{exerciseName} · 教学视频'**
  String trainingVideoTitle(String exerciseName);

  /// No description provided for @trainingVideoExternalLink.
  ///
  /// In zh, this message translates to:
  /// **'外部视频链接'**
  String get trainingVideoExternalLink;

  /// No description provided for @trainingVideoUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'https://...'**
  String get trainingVideoUrlHint;

  /// No description provided for @trainingVideoDeleteLink.
  ///
  /// In zh, this message translates to:
  /// **'删除链接'**
  String get trainingVideoDeleteLink;

  /// No description provided for @trainingVideoOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开教学视频链接'**
  String get trainingVideoOpenFailed;

  /// No description provided for @trainingVideoListLoading.
  ///
  /// In zh, this message translates to:
  /// **'教学视频列表尚未加载完成'**
  String get trainingVideoListLoading;

  /// No description provided for @trainingVideoInvalidUrl.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的 http / https 链接'**
  String get trainingVideoInvalidUrl;

  /// No description provided for @trainingVideoDeleted.
  ///
  /// In zh, this message translates to:
  /// **'教学视频链接已删除'**
  String get trainingVideoDeleted;

  /// No description provided for @trainingVideoSaved.
  ///
  /// In zh, this message translates to:
  /// **'教学视频链接已保存'**
  String get trainingVideoSaved;

  /// No description provided for @trainingVideoListNotReady.
  ///
  /// In zh, this message translates to:
  /// **'视频列表尚未就绪'**
  String get trainingVideoListNotReady;

  /// No description provided for @trainingVideoOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'教学视频操作失败，请重试'**
  String get trainingVideoOperationFailed;

  /// No description provided for @trainingDurationSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds}秒'**
  String trainingDurationSeconds(int seconds);

  /// No description provided for @trainingDurationMinutesValue.
  ///
  /// In zh, this message translates to:
  /// **'{minutes}分钟'**
  String trainingDurationMinutesValue(int minutes);

  /// No description provided for @trainingDurationMinutesSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{minutes}分{seconds}秒'**
  String trainingDurationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @trainingTargetStrength.
  ///
  /// In zh, this message translates to:
  /// **'目标：{sets} × {reps} · {weight} kg'**
  String trainingTargetStrength(int sets, int reps, String weight);

  /// No description provided for @trainingTargetSetsOnly.
  ///
  /// In zh, this message translates to:
  /// **'目标：{sets} 组'**
  String trainingTargetSetsOnly(int sets);

  /// No description provided for @trainingTargetCardio.
  ///
  /// In zh, this message translates to:
  /// **'目标：{sets} 组 · {duration}'**
  String trainingTargetCardio(int sets, String duration);

  /// No description provided for @trainingTargetPerSetDuration.
  ///
  /// In zh, this message translates to:
  /// **'目标：{sets} 组 · 每组 {duration}'**
  String trainingTargetPerSetDuration(int sets, String duration);

  /// No description provided for @trainingTargetPrefix.
  ///
  /// In zh, this message translates to:
  /// **'目标：'**
  String get trainingTargetPrefix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
