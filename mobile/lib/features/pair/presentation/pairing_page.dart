import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../shared/widgets/bitesync_snackbar.dart';
import '../domain/pair_state.dart';
import '../../auth/presentation/auth_controller.dart';
import 'pair_controller.dart';

class PairingPage extends ConsumerStatefulWidget {
  const PairingPage({super.key});

  @override
  ConsumerState<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends ConsumerState<PairingPage> {
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairState = ref.watch(pairControllerProvider);
    final isLoading = pairState is PairLoading;
    final pair = pairState is PairConnected ? pairState.pair : null;
    final isConnected = pair?.isConnected == true;
    final isPending = pair?.isPending == true;
    final partner = isConnected ? pair?.partner : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(appL10n.pairTitle),
        actions: [
          IconButton(
            tooltip: appL10n.authSignOut,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            isConnected
                ? appL10n.pairConnectedTitle
                : isPending
                ? appL10n.pairPendingTitle
                : appL10n.pairSingleTitle,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            isConnected
                ? appL10n.pairCurrentDetailsHint
                : isPending
                ? appL10n.pairPendingDescription
                : appL10n.pairSingleDescription,
          ),
          if (pairState is PairFailure) ...[
            SizedBox(height: 20),
            Text(
              pairState.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (pair != null) ...[
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appL10n.pairDetails),
                    SizedBox(height: 12),
                    Text(appL10n.pairInviteCode),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            pair.inviteCode,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: appL10n.pairCopyInviteCode,
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: pair.inviteCode),
                            );
                            if (context.mounted) {
                              BiteSyncSnackBar.show(
                                context,
                                message: appL10n.pairInviteCodeCopied,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      isConnected
                          ? appL10n.pairConnected
                          : appL10n.pairWaitingForPartner,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      isConnected
                          ? appL10n.pairPartnerInfo
                          : appL10n.pairInviteCode,
                    ),
                    SizedBox(height: 8),
                    if (isConnected)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.people_outline),
                        title: Text(partner!.displayName),
                        subtitle: Text(appL10n.pairPartnerInfo),
                      )
                    else
                      Text(appL10n.pairPendingDescription),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () =>
                        ref.read(pairControllerProvider.notifier).createPair(),
              icon: Icon(Icons.person_add_alt_1),
              label: Text(appL10n.pairInvitePartner),
            ),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 24),
            TextField(
              controller: _inviteCodeController,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: appL10n.pairInviteCode,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref
                        .read(pairControllerProvider.notifier)
                        .joinPair(_inviteCodeController.text),
              icon: Icon(Icons.group_add_outlined),
              label: Text(appL10n.pairEnterInviteCode),
            ),
          ],
          if (isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
