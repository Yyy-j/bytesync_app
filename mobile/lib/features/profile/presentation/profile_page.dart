import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
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
  String? _loadedProfileId;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.navProfile)),
      body: SafeArea(
        child: switch (state) {
          ProfileLoading() => LoadingView(message: appL10n.profileLoading),
          ProfileFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                ref.read(profileControllerProvider.notifier).refresh(),
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
      _loadedProfileId = profile.id;
    }
    final pairState = ref.watch(pairControllerProvider);
    final themeController = ref.watch(themeModeControllerProvider);

    return ListView(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        profile.character.bodyAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? appL10n.profileUnnamed,
                          style: TextStyle(
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
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _displayNameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: appL10n.profileDisplayName,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.saving ? null : _saveProfile,
                  child: Text(
                    state.saving ? appL10n.commonSaving : appL10n.profileSave,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    appL10n.profileThemeMode,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SegmentedButton<ThemeMode>(
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(appL10n.profileThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(appL10n.profileThemeDark),
                  ),
                ],
                selected: {themeController.mode},
                onSelectionChanged: (selection) {
                  ref
                      .read(themeModeControllerProvider)
                      .setMode(selection.first);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.face_retouching_natural_outlined),
                title: Text(appL10n.profileCharacter),
                trailing: Icon(Icons.chevron_right),
                onTap: _openCharacterPage,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.flag_outlined),
                title: Text(appL10n.profileNutritionGoals),
                trailing: Icon(Icons.chevron_right),
                onTap: () => context.push('/nutrition-goals'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fitness_center_outlined),
                title: Text(appL10n.profileTrainingPlan),
                trailing: Icon(Icons.chevron_right),
                onTap: () => context.push('/training/template'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history),
                title: Text(appL10n.trainingHistory),
                trailing: Icon(Icons.chevron_right),
                onTap: () => context.push('/training/history'),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.people_outline),
            title: Text(appL10n.profilePairing),
            subtitle: Text(_pairSummary(pairState)),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.push('/pairing'),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: Icon(Icons.logout),
          label: Text(appL10n.authSignOut),
        ),
      ],
    );
  }

  String _pairSummary(PairState state) {
    if (state is PairConnected) {
      final partner = state.pair.partner;
      return partner == null
          ? appL10n.profilePairWaiting
          : appL10n.profilePairedWith(partner.displayName);
    }
    if (state is PairLoading || state is PairInitial) {
      return appL10n.profilePairLoading;
    }
    if (state is PairFailure) return state.message;
    return appL10n.profileNotPaired;
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final result = await ref
        .read(profileControllerProvider.notifier)
        .save(displayName: displayName.isEmpty ? null : displayName);
    if (result.isSuccess) {
      await ref.read(pairControllerProvider.notifier).refresh();
    }
    if (mounted) {
      _snack(result.isSuccess ? appL10n.profileSaved : result.errorMessage!);
    }
  }

  Future<void> _openCharacterPage() async {
    final saved = await context.push<bool>('/profile/character');
    if (saved == true && mounted) _snack(appL10n.characterSaved);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
