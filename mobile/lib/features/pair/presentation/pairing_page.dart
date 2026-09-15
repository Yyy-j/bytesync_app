import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytesync/l10n/l10n.dart';

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
    final connected = pairState is PairConnected ? pairState : null;

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
            appL10n.pairTitle,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            connected == null
                ? appL10n.pairIntro
                : appL10n.pairCurrentDetailsHint,
          ),
          if (pairState is PairFailure) ...[
            SizedBox(height: 20),
            Text(
              pairState.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (connected != null) ...[
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
                            connected.pair.inviteCode,
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
                              ClipboardData(text: connected.pair.inviteCode),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(appL10n.pairInviteCodeCopied),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      connected.pair.members.length == 1
                          ? appL10n.pairWaitingForPartner
                          : appL10n.pairConnected,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(appL10n.commonMember),
                    SizedBox(height: 8),
                    ...connected.pair.members.map(
                      (member) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          member.isSelf ? Icons.person : Icons.people_outline,
                        ),
                        title: Text(member.displayName),
                        subtitle: Text(
                          member.isSelf
                              ? appL10n.pairMyInfo
                              : appL10n.pairPartnerInfo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(pairControllerProvider.notifier)
                            .continueToHome();
                        context.go('/');
                      },
                      child: Text(appL10n.pairEnterHome),
                    ),
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
              icon: Icon(Icons.add_link),
              label: Text(appL10n.pairCreate),
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
              label: Text(appL10n.pairJoin),
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
