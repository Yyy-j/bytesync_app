import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bitesync_snackbar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../pair/domain/pair_state.dart';
import '../../pair/presentation/pair_controller.dart';

class AccountPrivacyPage extends ConsumerStatefulWidget {
  const AccountPrivacyPage({super.key});

  @override
  ConsumerState<AccountPrivacyPage> createState() => _AccountPrivacyPageState();
}

class _AccountPrivacyPageState extends ConsumerState<AccountPrivacyPage> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appL10n.accountPrivacyTitle)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.login_outlined),
                title: Text(appL10n.accountPrivacyLoginMethod),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.privacy_tip_outlined,
                  title: appL10n.accountPrivacyPrivacyPolicy,
                ),
                _InfoTile(
                  icon: Icons.description_outlined,
                  title: appL10n.accountPrivacyTerms,
                ),
                _InfoTile(
                  icon: Icons.auto_awesome_outlined,
                  title: appL10n.accountPrivacyAiData,
                  subtitle: appL10n.accountPrivacyAiDataDescription,
                ),
                _InfoTile(
                  icon: Icons.folder_shared_outlined,
                  title: appL10n.accountPrivacyAccountData,
                  subtitle: appL10n.accountPrivacyAccountDataDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(appL10n.authDeleteAccount),
                subtitle: Text(appL10n.accountPrivacyDeleteDescription),
                trailing: _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _deleting ? null : _deleteAccount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final pairState = ref.read(pairControllerProvider);
    final connected = pairState is PairConnected && pairState.pair.isConnected;
    final firstConfirmed = await _confirm(
      description: connected
          ? appL10n.authDeleteAccountConnectedDescription
          : appL10n.authDeleteAccountDescription,
      confirmLabel: appL10n.commonContinue,
    );
    if (!firstConfirmed || !mounted) return;
    final finalConfirmed = await _confirm(
      description: appL10n.authDeleteAccountDescription,
      confirmLabel: appL10n.authDeleteAccountConfirm,
      destructive: true,
    );
    if (!finalConfirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } catch (error) {
      if (!mounted) return;
      BiteSyncSnackBar.show(
        context,
        message: error is ApiException
            ? error.message
            : appL10n.authDeleteAccountFailed,
      );
      setState(() => _deleting = false);
    }
  }

  Future<bool> _confirm({
    required String description,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(appL10n.authDeleteAccountTitle),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(appL10n.commonCancel),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    ),
  );
}
