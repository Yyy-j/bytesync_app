// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'BiteSync';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveChanges => '保存修改';

  @override
  String get commonSaving => '保存中…';

  @override
  String get commonView => '查看';

  @override
  String get commonMember => '成员';

  @override
  String get commonUnnamedMember => '未命名成员';

  @override
  String get commonDefaultUser => 'BiteSync 用户';

  @override
  String get commonUncategorized => '未分类';

  @override
  String get commonSeconds => '秒';

  @override
  String get commonAll => '全部';

  @override
  String get commonKilocaloriesUnit => 'kcal';

  @override
  String get commonGramsUnit => 'g';

  @override
  String get commonProtein => '蛋白质';

  @override
  String get commonFat => '脂肪';

  @override
  String get commonListSeparator => '、';

  @override
  String get commonErrorSeparator => '；';

  @override
  String commonGramsValue(int grams) {
    return '${grams}g';
  }

  @override
  String commonCaloriesValue(String calories) {
    return '$calories kcal';
  }

  @override
  String get navToday => '今日';

  @override
  String get navRecord => '记录';

  @override
  String get navTraining => '训练';

  @override
  String get navProfile => '我的';

  @override
  String get authTagline => '轻松记录每一餐，掌握每日营养';

  @override
  String get authSigningIn => '登录中…';

  @override
  String get authSignInWithGoogle => '使用 Google 登录';

  @override
  String get authSignOut => '退出登录';

  @override
  String get authRestoreFailed => '暂时无法验证登录状态，请重试';

  @override
  String get authSessionExpired => '登录已过期，请重新登录';

  @override
  String get authSignInFailed => '登录失败，请重试';

  @override
  String get authGoogleNotConfigured =>
      'Google 登录尚未配置（缺少 GOOGLE_CLIENT_ID），请联系开发者';

  @override
  String get authGoogleCredentialMissing => '未获取到 Google 登录凭证，请重试';

  @override
  String get authSignInCancelled => '已取消登录';

  @override
  String authGoogleSignInFailed(String description) {
    return 'Google 登录失败：$description';
  }

  @override
  String get errorInvalidRequest => '请求参数有误，请检查后重试';

  @override
  String get errorForbidden => '暂无权限';

  @override
  String get errorNotFound => '请求的内容不存在';

  @override
  String get errorConflict => '这条记录已在其他设备被修改，请刷新后重试';

  @override
  String get errorServer => '服务器开小差了，请稍后重试';

  @override
  String get errorNetworkRetry => '网络连接失败，请检查网络后重试';

  @override
  String get errorMalformedData => '数据格式异常，请稍后重试';

  @override
  String get errorUnknown => '出错了，请稍后重试';

  @override
  String get errorOperationFailed => '操作失败，请稍后重试';

  @override
  String get errorCannotSaveNow => '当前无法保存，请稍后重试';

  @override
  String get pairTitle => '与搭档配对';

  @override
  String get pairIntro => '先创建一个配对，或输入搭档发来的邀请码。';

  @override
  String get pairCurrentDetailsHint => '查看当前配对详情。';

  @override
  String get pairDetails => '配对详情';

  @override
  String get pairInviteCode => '邀请码';

  @override
  String get pairCopyInviteCode => '复制邀请码';

  @override
  String get pairInviteCodeCopied => '邀请码已复制';

  @override
  String get pairWaitingForPartner => '等待搭档加入';

  @override
  String get pairConnected => '已完成配对';

  @override
  String get pairMyInfo => '我的信息';

  @override
  String get pairPartnerInfo => '搭档信息';

  @override
  String get pairEnterHome => '进入主页';

  @override
  String get pairCreate => '创建配对';

  @override
  String get pairJoin => '加入配对';

  @override
  String get pairFull => '这个配对已经有两位成员了';

  @override
  String get pairAlreadyJoined => '你已经加入配对，不能重复操作';

  @override
  String get pairConflict => '当前配对状态发生冲突，请刷新后重试';

  @override
  String get pairInvalidInviteCode => '邀请码无效或已失效，请检查后重试';

  @override
  String get pairOperationFailed => '配对操作失败，请稍后重试';

  @override
  String get profileLoading => '正在加载用户资料';

  @override
  String get profileUnnamed => '未设置显示名';

  @override
  String get profileDisplayName => '用户显示名';

  @override
  String get profileSave => '保存资料';

  @override
  String get profileThemeMode => '主题模式';

  @override
  String get profileThemeLight => '浅色';

  @override
  String get profileThemeDark => '深色';

  @override
  String get profileNutritionGoals => '营养目标';

  @override
  String get profileTrainingPlan => '训练计划';

  @override
  String get profilePairing => '搭档与配对';

  @override
  String get profilePairWaiting => '已创建配对，等待搭档加入';

  @override
  String profilePairedWith(String partnerName) {
    return '已配对：$partnerName';
  }

  @override
  String get profilePairLoading => '正在读取配对状态';

  @override
  String get profileNotPaired => '尚未配对';

  @override
  String get profileSaved => '用户资料已保存';

  @override
  String get profileLoadFailed => '用户资料加载失败，请重试';

  @override
  String get profileSaveFailed => '用户资料保存失败，请重试';

  @override
  String get goalsDescription => '设置你的每日热量和营养素目标。';

  @override
  String get goalsDailyCalories => '每日热量';

  @override
  String get goalsProtein => 'Protein';

  @override
  String get goalsCarbs => 'Carbs';

  @override
  String get goalsFat => 'Fat';

  @override
  String get goalsSave => '保存营养目标';

  @override
  String get goalsInvalidValue => '请输入大于等于 0 的有效数值';

  @override
  String get goalsSaved => '营养目标已保存';

  @override
  String get goalsLoadFailed => '营养目标加载失败，请重试';

  @override
  String get goalsSaveFailed => '营养目标保存失败，请重试';

  @override
  String get todayDateFormat => 'yyyy年M月d日 EEEE';

  @override
  String get todayMyIntake => '我的今日摄入';

  @override
  String get todayMe => '我';

  @override
  String get todayPartnerIntake => '搭档今日摄入';

  @override
  String get todayRecords => '今日记录';

  @override
  String get todayEmpty => '还没有记录，去记一笔吧';

  @override
  String get todayAdjustPortion => '调整份量';

  @override
  String get todayEditDirectly => '直接编辑';

  @override
  String get todayReestimateWithNote => '补充说明再估算';

  @override
  String get todayRecordUpdated => '记录已更新';

  @override
  String get todayPortionUpdated => '份量已更新';

  @override
  String get todayReestimated => '已重新估算并更新';

  @override
  String get todayRecordDeleted => '记录已删除';

  @override
  String get todayName => '名称';

  @override
  String get todayBaseCalories => '基础卡路里';

  @override
  String get todayBaseProtein => '基础蛋白质';

  @override
  String get todayBaseCarbs => '基础碳水';

  @override
  String get todayBaseFat => '基础脂肪';

  @override
  String get todayInvalidMealValues => '请填写名称和大于等于 0 的有效营养数值';

  @override
  String get todayReestimateHint => '例如：米饭其实只有半碗';

  @override
  String get todayNoteRequired => '请输入补充说明';

  @override
  String get todayReestimate => '重新估算';

  @override
  String get todayDeleteTitle => '删除这条记录？';

  @override
  String get todayDeleteDescription => '删除后无法恢复。';

  @override
  String get todayConfirmDelete => '确认删除';

  @override
  String todayManageMeal(String mealName) {
    return '管理$mealName';
  }

  @override
  String todayProteinGrams(int grams) {
    return '蛋白 ${grams}g';
  }

  @override
  String todayCarbsGrams(int grams) {
    return '碳水 ${grams}g';
  }

  @override
  String todayFatGrams(int grams) {
    return '脂肪 ${grams}g';
  }

  @override
  String get todayLoadFailed => '加载失败，请重试';

  @override
  String todayPortionRatio(String ratio) {
    return '${ratio}x';
  }

  @override
  String todayIntakeCalories(String name, int calories) {
    return '$name $calories';
  }

  @override
  String todayCalorieGoal(int calories) {
    return '/ $calories kcal';
  }

  @override
  String get recordQuerying => '查询中…';

  @override
  String get recordRecognizing => '识别中…';

  @override
  String get recordEstimating => '正在估算这份料理';

  @override
  String get recordFoodName => '食物名称';

  @override
  String get recordManual => '手动记录';

  @override
  String get recordCaloriesRequired => '卡路里 *';

  @override
  String get recordKilocaloriesHint => '千卡';

  @override
  String get recordCarbohydrates => '碳水化合物';

  @override
  String get recordZeroGrams => '0 克';

  @override
  String get recordGenerate => '生成记录';

  @override
  String get recordYesterdayPrompt => '昨天也吃了？';

  @override
  String get recordAdd => '添加';

  @override
  String get recordRecognitionComplete => '识别完成';

  @override
  String recordMacroSummary(String protein, String carbs, String fat) {
    return '蛋白质 ${protein}g  ·  碳水 ${carbs}g  ·  脂肪 ${fat}g';
  }

  @override
  String recordDishes(String dishNames) {
    return '菜品：$dishNames';
  }

  @override
  String get recordAiDisclaimer => 'AI 估算，仅供参考';

  @override
  String get recordRecognizeWithNote => '补充说明再识别';

  @override
  String get recordEditData => '手动改数据';

  @override
  String get recordAmountQuestion => '吃了多少？';

  @override
  String get recordPortionHalf => '1/2';

  @override
  String get recordPortionTwoThirds => '2/3';

  @override
  String get recordPortionOneThird => '1/3';

  @override
  String get recordShareQuestion => '这顿要同步给 Ta 吗？';

  @override
  String get recordShareSolo => '只记录给我';

  @override
  String get recordSharePartnerOnly => '只给 Ta 记';

  @override
  String get recordShareTogether => '一起吃';

  @override
  String get recordShareHalf => '一人一半';

  @override
  String get recordShareMeOneThird => '我 1/3 · Ta 2/3';

  @override
  String get recordShareMeTwoThirds => '我 2/3 · Ta 1/3';

  @override
  String recordSharePreview(
    String myCalories,
    String partnerName,
    String partnerCalories,
  ) {
    return '分配预览：我 $myCalories kcal  $partnerName $partnerCalories kcal';
  }

  @override
  String get recordSaving => '记录中…';

  @override
  String get recordThisMeal => '记录这一餐';

  @override
  String get recordRetake => '重新拍摄';

  @override
  String get recordReselect => '重新选择';

  @override
  String get recordTakeMeal => '拍一餐';

  @override
  String get recordTakePhoto => '拍照';

  @override
  String get recordChooseGallery => '从相册选择';

  @override
  String get recordImageTooLarge => '图片太大，请重新选择';

  @override
  String get recordCaloriesMustBePositive => '请填写大于 0 的卡路里';

  @override
  String get recordYesterdayFilled => '已填入昨天的记录，可修改后生成';

  @override
  String get recordSaved => '已记录';

  @override
  String get recordHeroSubtitle => '饭前拍一下，轻轻记录这一餐';

  @override
  String get recordDescriptionHint => '描述食物，或拍照前补充说明';

  @override
  String get recordSendDescription => '发送文字描述';

  @override
  String get recordCollapse => '收起';

  @override
  String get recordManualMeal => '手动记录一餐';

  @override
  String get recordCorrectionHint => '例如：米饭实际只有半碗';

  @override
  String get recordRecognizeAgain => '重新识别';

  @override
  String get recordImageRecognitionUnavailable => '图片识别暂不可用';

  @override
  String get recordNetworkFailed => '网络连接失败，请检查网络';

  @override
  String get recordUnsupportedImage => '暂不支持这张图片格式';

  @override
  String get recordAiUnavailable => 'AI 服务暂时不可用，请稍后重试';

  @override
  String get recordRecognitionFailed => '识别失败，请重新尝试';

  @override
  String get recordAiEstimateFailed => 'AI 估算失败，请稍后重试';

  @override
  String get mealReestimateUnsupported => '这条记录暂不支持重新估算';

  @override
  String get mealProcessing => '正在处理，请稍候';

  @override
  String get mealConflict => '这条记录已经在其他地方被修改，请刷新后重试';

  @override
  String get mealInvalidChange => '修改内容有误，请检查后重试';

  @override
  String get macroCarbs => '碳水';

  @override
  String get trainingLoading => '正在加载本周训练';

  @override
  String trainingWeekRange(String start, String end) {
    return '本周 $start - $end';
  }

  @override
  String get trainingEditPlan => '编辑训练计划';

  @override
  String get trainingHistory => '训练历史';

  @override
  String get trainingDayEmpty => '这天没有训练计划';

  @override
  String get trainingViewVideo => '查看教学视频';

  @override
  String trainingProgress(int completed, int target) {
    return '进度：$completed / $target 组';
  }

  @override
  String get trainingRemovedFromTemplate => '已从当前模板移除';

  @override
  String get trainingCompleteSet => '完成一组';

  @override
  String get trainingSetCompleted => '已完成一组';

  @override
  String get trainingSetUpdated => '该组记录已更新';

  @override
  String get trainingCompleted => '已完成';

  @override
  String trainingSetPerformance(int index, String performance) {
    return '第 $index 组  $performance';
  }

  @override
  String trainingHistorySetTime(int index, String time) {
    return '第 $index 组 · $time';
  }

  @override
  String trainingEditSetTitle(int index, String exerciseName) {
    return '编辑第 $index 组 · $exerciseName';
  }

  @override
  String get trainingClearFieldHint => '清空字段后保存，会删除该项记录值。';

  @override
  String get trainingWeightKg => '重量 kg';

  @override
  String get trainingReps => '次数 reps';

  @override
  String get trainingDurationMinutes => '时长（分钟）';

  @override
  String get trainingNote => '备注';

  @override
  String get trainingRpe => 'RPE';

  @override
  String get trainingRpeHint => '1 - 10';

  @override
  String trainingWeightRepsValue(String weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String trainingWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String trainingRepsValue(int reps) {
    return '$reps reps';
  }

  @override
  String trainingRpeValue(String rpe) {
    return 'RPE $rpe';
  }

  @override
  String trainingCompleteSetTitle(String exerciseName) {
    return '完成一组 · $exerciseName';
  }

  @override
  String get trainingRpeOptional => 'RPE（可选）';

  @override
  String get trainingNoteOptional => '备注（可选）';

  @override
  String get trainingConfirmComplete => '确认完成';

  @override
  String get trainingInvalidEditWeight => '重量请输入 0 到 10000，或留空';

  @override
  String get trainingInvalidEditReps => '次数请输入 0 到 9999，或留空';

  @override
  String get trainingInvalidEditRpe => 'RPE 请输入 1 到 10，或留空';

  @override
  String get trainingInvalidDurationParts => '时长请输入有效的分钟和 0 到 59 秒';

  @override
  String get trainingInvalidOptionalDuration => '时长需为 1 秒到 1440 分钟，或全部清空';

  @override
  String get trainingInvalidWeight => '请输入 0 到 10000 之间的重量';

  @override
  String get trainingInvalidReps => '请输入 0 到 9999 之间的次数';

  @override
  String get trainingInvalidRpe => 'RPE 请输入 1 到 10 之间的数值';

  @override
  String get trainingInvalidBlankDuration => '时长需为 1 秒到 1440 分钟，或全部留空';

  @override
  String get trainingLoadFailed => '训练计划加载失败，请重试';

  @override
  String get trainingDataNotLoaded => '训练数据尚未加载，请稍后重试';

  @override
  String get trainingCheckInRefreshFailed => '该组已记录，但刷新失败。请保持当前内容并重试';

  @override
  String get trainingTargetComplete => '目标组数已完成，请刷新后查看最新进度';

  @override
  String get trainingCheckInFailed => '打卡失败，请检查网络后重试';

  @override
  String get trainingEditRefreshFailed => '该组已更新，但刷新失败。请保持当前内容并重试';

  @override
  String get trainingEditFailed => '修改失败，请检查网络后重试';

  @override
  String get trainingTemplateDescription => '设置每周固定训练。保存模板后，可由你决定是否同步到本周。';

  @override
  String get trainingRestDay => '休息日';

  @override
  String trainingExerciseCount(int count) {
    return '$count 个动作';
  }

  @override
  String get trainingAddExercise => '新增动作';

  @override
  String get trainingSavePlan => '保存训练计划';

  @override
  String get trainingSyncing => '同步中…';

  @override
  String get trainingSaveBeforeSync => '请先保存再同步';

  @override
  String get trainingSyncWeek => '同步到本周';

  @override
  String get trainingPlanSaved => '训练计划已保存';

  @override
  String get trainingSyncedWeek => '已同步到本周';

  @override
  String get trainingExerciseNameInvalid => '动作名称需为 1 到 100 个字符';

  @override
  String get trainingCategoryTooLong => '分类不能超过 50 个字符';

  @override
  String get trainingTargetSetsInvalid => '目标组数请输入 1 到 50';

  @override
  String get trainingTargetRepsInvalid => '目标次数请输入 0 到 999';

  @override
  String get trainingTargetWeightInvalid => '目标重量请输入 0 到 10000';

  @override
  String get trainingTargetDurationInvalid => '目标时长需为 1 秒到 1440 分钟';

  @override
  String get trainingExerciseName => '动作名称';

  @override
  String get trainingExerciseCategory => '分类';

  @override
  String get trainingExerciseType => '类型';

  @override
  String trainingExerciseTypeValue(String type) {
    return '类型：$type';
  }

  @override
  String get trainingTargetSets => '目标组数';

  @override
  String get trainingTargetReps => '目标次数';

  @override
  String get trainingTargetWeightKg => '目标重量 kg';

  @override
  String get trainingTargetDurationMinutes => '目标时长（分钟）';

  @override
  String get trainingSaveExercise => '保存动作';

  @override
  String get trainingTypeStrength => '力量';

  @override
  String get trainingTypeDuration => '时长';

  @override
  String get trainingTypeCardio => '有氧';

  @override
  String get trainingTemplateSaveFailed => '训练计划保存失败，请重试';

  @override
  String get trainingTemplateSyncUnavailable => '当前无法同步，请稍后重试';

  @override
  String get trainingTemplateSyncFailed => '同步到本周失败，请重试';

  @override
  String get trainingHistoryEmpty => '还没有训练历史';

  @override
  String get trainingDetails => '训练详情';

  @override
  String get trainingDetailsLoadFailed => '训练详情加载失败，请重试';

  @override
  String trainingSetsProgress(int completed, int target) {
    return '$completed / $target 组';
  }

  @override
  String trainingDateSuffix(String date) {
    return ' · $date';
  }

  @override
  String get trainingShortDateFormat => 'M/d';

  @override
  String get trainingMonthDayFormat => 'M月d日';

  @override
  String get trainingTimeFormat => 'HH:mm';

  @override
  String trainingDateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get trainingIncompleteSets => '未完成训练组';

  @override
  String get trainingHistoryLoadFailed => '训练历史加载失败，请重试';

  @override
  String get trainingWeekdayMonday => '周一';

  @override
  String get trainingWeekdayTuesday => '周二';

  @override
  String get trainingWeekdayWednesday => '周三';

  @override
  String get trainingWeekdayThursday => '周四';

  @override
  String get trainingWeekdayFriday => '周五';

  @override
  String get trainingWeekdaySaturday => '周六';

  @override
  String get trainingWeekdaySunday => '周日';

  @override
  String get trainingPickerTitle => '选择训练动作';

  @override
  String get trainingCustomFill => '自定义填写';

  @override
  String get trainingSystemExercises => '系统动作';

  @override
  String get trainingMyExercises => '我的动作';

  @override
  String get trainingSearchSystemHint => '搜索中文或英文名称';

  @override
  String get trainingSearchMyHint => '搜索动作名称或分类';

  @override
  String trainingSystemExerciseSubtitle(
    String englishName,
    String category,
    String target,
  ) {
    return '$englishName · $category\n$target';
  }

  @override
  String trainingCustomExerciseSubtitle(
    String category,
    String type,
    String target,
  ) {
    return '$category · $type\n$target';
  }

  @override
  String trainingExerciseTargetWithCategory(String target, String category) {
    return '$target · $category';
  }

  @override
  String get trainingManageVideo => '管理教学视频';

  @override
  String get trainingMyExercisesEmpty => '还没有我的动作';

  @override
  String get trainingNoMatchingExercises => '没有匹配的动作';

  @override
  String get trainingEditExercise => '编辑动作';

  @override
  String get trainingDeleteExercise => '删除动作';

  @override
  String get trainingExerciseAdded => '动作已新增';

  @override
  String get trainingExerciseUpdated => '动作已更新';

  @override
  String get trainingDeleteExerciseTitle => '删除动作？';

  @override
  String get trainingDeleteExerciseDescription => '删除后不会影响已经保存的训练计划和历史记录。';

  @override
  String get trainingExerciseDeleted => '动作已删除';

  @override
  String get trainingDefaultSetsInvalid => '默认组数请输入 1 到 50';

  @override
  String get trainingDefaultRepsInvalid => '默认次数请输入 0 到 999';

  @override
  String get trainingDefaultWeightInvalid => '默认重量请输入 0 到 10000';

  @override
  String get trainingDefaultDurationInvalid => '默认时长需为 1 秒到 1440 分钟';

  @override
  String get trainingAddMyExercise => '新增我的动作';

  @override
  String get trainingEditMyExercise => '编辑我的动作';

  @override
  String get trainingDefaultSets => '默认组数';

  @override
  String get trainingDefaultReps => '默认次数';

  @override
  String get trainingDefaultWeightKg => '默认重量 kg';

  @override
  String get trainingDefaultDurationMinutes => '默认时长（分钟）';

  @override
  String get trainingCustomLoadFailed => '我的动作加载失败，请重试';

  @override
  String get trainingCustomAddFailed => '新增动作失败，请重试';

  @override
  String get trainingCustomEditFailed => '编辑动作失败，请重试';

  @override
  String get trainingCustomDeleteFailed => '删除动作失败，请重试';

  @override
  String get trainingExerciseLibraryNotReady => '动作库尚未就绪，请稍后重试';

  @override
  String get trainingExerciseMissing => '动作已不存在，列表已刷新';

  @override
  String trainingVideoTitle(String exerciseName) {
    return '$exerciseName · 教学视频';
  }

  @override
  String get trainingVideoExternalLink => '外部视频链接';

  @override
  String get trainingVideoUrlHint => 'https://...';

  @override
  String get trainingVideoDeleteLink => '删除链接';

  @override
  String get trainingVideoOpenFailed => '无法打开教学视频链接';

  @override
  String get trainingVideoListLoading => '教学视频列表尚未加载完成';

  @override
  String get trainingVideoInvalidUrl => '请输入有效的 http / https 链接';

  @override
  String get trainingVideoDeleted => '教学视频链接已删除';

  @override
  String get trainingVideoSaved => '教学视频链接已保存';

  @override
  String get trainingVideoListNotReady => '视频列表尚未就绪';

  @override
  String get trainingVideoOperationFailed => '教学视频操作失败，请重试';

  @override
  String trainingDurationSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String trainingDurationMinutesValue(int minutes) {
    return '$minutes分钟';
  }

  @override
  String trainingDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String trainingTargetStrength(int sets, int reps, String weight) {
    return '目标：$sets × $reps · $weight kg';
  }

  @override
  String trainingTargetSetsOnly(int sets) {
    return '目标：$sets 组';
  }

  @override
  String trainingTargetCardio(int sets, String duration) {
    return '目标：$sets 组 · $duration';
  }

  @override
  String trainingTargetPerSetDuration(int sets, String duration) {
    return '目标：$sets 组 · 每组 $duration';
  }

  @override
  String get trainingTargetPrefix => '目标：';
}
