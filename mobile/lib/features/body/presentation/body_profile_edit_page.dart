import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/data/user_providers.dart';
import '../../profile/domain/user_profile.dart';
import 'body_data_page.dart';

class BodyProfileEditPage extends ConsumerStatefulWidget {
  const BodyProfileEditPage({super.key});
  @override
  ConsumerState<BodyProfileEditPage> createState() =>
      _BodyProfileEditPageState();
}

class _BodyProfileEditPageState extends ConsumerState<BodyProfileEditPage> {
  final _birthYear = TextEditingController();
  final _height = TextEditingController();
  final _targetWeight = TextEditingController();
  String? _sex;
  String? _activity;
  DateTime? _targetDate;
  UserProfile? _profile;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _birthYear.dispose();
    _height.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑身体目标')),
        body: FutureBuilder<UserProfile>(
          future: ref.read(userRepositoryProvider).getProfile(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return ErrorView(
                  message: '加载失败，请重试',
                  onRetry: () => setState(() {}),
                );
              }
              return const LoadingView();
            }
            _populate(snapshot.data!);
            return _form(snapshot.data!);
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('编辑身体目标')),
      body: _form(profile),
    );
  }

  void _populate(UserProfile profile) {
    if (_profile != null) return;
    _profile = profile;
    _birthYear.text = profile.birthYear?.toString() ?? '';
    _height.text = profile.heightCm?.toString() ?? '';
    _targetWeight.text = profile.targetWeightKg?.toString() ?? '';
    _sex = profile.sexForEnergyEstimate;
    _activity = profile.activityLevel;
    _targetDate = profile.targetDate;
  }

  Widget _form(UserProfile profile) => ListView(
    padding: EdgeInsets.all(AppSpacing.pagePadding),
    children: [
      _number('出生年份', _birthYear),
      _choice('用于热量估算的生理参数', _sex, {
        '男性': 'male',
        '女性': 'female',
      }, (value) => setState(() => _sex = value)),
      _number('身高', _height, suffix: 'cm'),
      _number('目标体重', _targetWeight, suffix: 'kg'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _targetDate == null
              ? '选择目标日期'
              : '目标日期：${_targetDate!.month}月${_targetDate!.day}日',
        ),
        trailing: const Icon(Icons.calendar_today_outlined),
        onTap: _pickDate,
      ),
      _choice('活动量', _activity, const {
        '久坐为主': 'sedentary',
        '轻度活动': 'light',
        '中等活动': 'moderate',
        '高活动量': 'high',
        '非常高的活动量': 'very_high',
      }, (value) => setState(() => _activity = value)),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: _saving ? null : () => _save(profile),
        child: Text(_saving ? '保存中…' : '保存修改'),
      ),
    ],
  );

  Widget _number(
    String label,
    TextEditingController controller, {
    String? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
  );
  Widget _choice(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (entry) =>
              DropdownMenuItem(value: entry.value, child: Text(entry.key)),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _targetDate ?? DateTime.now(),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  Future<void> _save(UserProfile profile) async {
    final birth = int.tryParse(_birthYear.text);
    final height = double.tryParse(_height.text);
    final target = double.tryParse(_targetWeight.text);
    final today = DateUtils.dateOnly(DateTime.now());
    final current = ref
        .read(bodyDataControllerProvider)
        .valueOrNull
        ?.body
        .currentWeight
        ?.weightKg;
    final changing =
        current != null && target != null && (target - current).abs() > 0.1;
    if (birth == null ||
        birth < 1900 ||
        birth > DateTime.now().year ||
        _sex == null ||
        height == null ||
        height < 100 ||
        height > 250 ||
        target == null ||
        target < 20 ||
        target > 400 ||
        _activity == null ||
        _targetDate == null ||
        (changing &&
            !_targetDate!.isAfter(today) &&
            !DateUtils.isSameDay(_targetDate!, today))) {
      setState(() => _error = '请填写合理的身体资料和目标日期');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            displayName: profile.displayName,
            birthYear: birth,
            sexForEnergyEstimate: _sex,
            heightCm: height,
            targetWeightKg: target,
            targetDate: _targetDate,
            activityLevel: _activity,
          );
      await ref.read(authControllerProvider.notifier).refreshCurrentUser();
      ref.invalidate(bodyDataControllerProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException ? error.message : '保存失败，请重试',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
