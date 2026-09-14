import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../pair/domain/pair_state.dart';
import '../../pair/presentation/pair_controller.dart';
import 'profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  String? _loadedProfileId;

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: switch (state) {
          ProfileLoading() => const LoadingView(message: '正在加载用户资料'),
          ProfileFailure(:final message) => ErrorView(
            message: message,
            onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
          ),
          ProfileReady() => _body(state),
        },
      ),
    );
  }

  Widget _body(ProfileReady state) {
    final profile = state.profile;
    if (_loadedProfileId != profile.id) {
      _displayNameController.text = profile.displayName ?? '';
      _avatarUrlController.text = profile.avatarUrl ?? '';
      _loadedProfileId = profile.id;
    }
    final pairState = ref.watch(pairControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: profile.avatarUrl == null
                        ? null
                        : NetworkImage(profile.avatarUrl!),
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? '未设置显示名',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (profile.email != null) Text(profile.email!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _displayNameController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: '用户显示名'),
              ),
              TextField(
                controller: _avatarUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: '头像 URL',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.saving ? null : _saveProfile,
                  child: Text(state.saving ? '保存中…' : '保存资料'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('营养目标'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/nutrition-goals'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center_outlined),
                title: const Text('训练计划'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/training/template'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: const Text('训练历史'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/training/history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline),
            title: const Text('搭档与配对'),
            subtitle: Text(_pairSummary(pairState)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pairing'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }

  String _pairSummary(PairState state) {
    if (state is PairConnected) {
      final partner = state.pair.partner;
      return partner == null ? '已创建配对，等待搭档加入' : '已配对：${partner.displayName}';
    }
    if (state is PairLoading || state is PairInitial) return '正在读取配对状态';
    if (state is PairFailure) return state.message;
    return '尚未配对';
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final avatarUrl = _avatarUrlController.text.trim();
    if (avatarUrl.isNotEmpty) {
      final uri = Uri.tryParse(avatarUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        _snack('请输入有效的 http / https 头像链接');
        return;
      }
    }
    final result = await ref.read(profileControllerProvider.notifier).save(
      displayName: displayName.isEmpty ? null : displayName,
      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
    );
    if (result.isSuccess) {
      await ref.read(pairControllerProvider.notifier).refresh();
    }
    if (mounted) _snack(result.isSuccess ? '用户资料已保存' : result.errorMessage!);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
