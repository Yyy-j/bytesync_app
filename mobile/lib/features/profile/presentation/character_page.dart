import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bitesync_snackbar.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/user_character.dart';
import 'profile_controller.dart';

class CharacterPage extends ConsumerStatefulWidget {
  const CharacterPage({super.key});

  @override
  ConsumerState<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends ConsumerState<CharacterPage> {
  String? _profileId;
  UserCharacter? _savedCharacter;
  UserCharacter? _selectedCharacter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.characterPageTitle)),
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
    _initializeSelection(state.profile.id, state.profile.character);
    final selected = _selectedCharacter ?? UserCharacter.boy;
    final canSave = !state.saving;

    Widget selectionCard(UserCharacter character) {
      return Expanded(
        child: _CharacterSelectionCard(
          character: character,
          selected: selected == character,
          enabled: canSave,
          onTap: () {
            if (!canSave) return;
            setState(() => _selectedCharacter = character);
          },
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Row(
          children: [
            selectionCard(UserCharacter.boy),
            const SizedBox(width: AppSpacing.sm),
            selectionCard(UserCharacter.girl),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canSave ? _save : null,
            child: Text(
              state.saving ? appL10n.commonSaving : appL10n.characterSave,
            ),
          ),
        ),
      ],
    );
  }

  void _initializeSelection(String profileId, UserCharacter character) {
    if (_profileId == profileId) return;
    _profileId = profileId;
    _savedCharacter = character;
    _selectedCharacter = character;
  }

  Future<void> _save() async {
    final selected = _selectedCharacter;
    final saved = _savedCharacter;
    if (selected == null || saved == null) return;
    if (selected == saved) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final result = await ref
        .read(profileControllerProvider.notifier)
        .saveCharacter(selected);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      BiteSyncSnackBar.show(context, message: result.errorMessage!);
    }
  }
}

class _CharacterSelectionCard extends StatelessWidget {
  const _CharacterSelectionCard({
    required this.character,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final UserCharacter character;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.border;
    return Semantics(
      button: true,
      selected: selected,
      label: appL10n.profileCharacter,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          scale: selected ? 1 : 0.98,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 220,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SvgPicture.asset(
                      character.bodyAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: const Icon(Icons.check, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
