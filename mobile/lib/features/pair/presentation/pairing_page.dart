import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../../../shared/widgets/bitesync_snackbar.dart';
import '../domain/pair.dart';
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
  Timer? _pendingPollTimer;
  bool _pendingPollInFlight = false;
  bool _actionInFlight = false;
  Pair? _actionPair;

  @override
  void initState() {
    super.initState();
    ref.listenManual<PairState>(pairControllerProvider, (_, next) {
      _syncPendingPolling(next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(pairControllerProvider.notifier);
      unawaited(controller.refresh(showLoading: false));
      _syncPendingPolling(ref.read(pairControllerProvider));
    });
  }

  @override
  void dispose() {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _syncPendingPolling(PairState state) {
    final isPending = state is PairConnected && state.pair.isPending;
    if (!isPending) {
      _pendingPollTimer?.cancel();
      _pendingPollTimer = null;
      return;
    }
    if (_pendingPollTimer != null) return;
    _pendingPollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollPendingPair(),
    );
  }

  Future<void> _pollPendingPair() async {
    if (_pendingPollInFlight || _actionInFlight || !mounted) return;
    final state = ref.read(pairControllerProvider);
    if (state is! PairConnected || !state.pair.isPending) {
      _syncPendingPolling(state);
      return;
    }
    _pendingPollInFlight = true;
    try {
      await ref
          .read(pairControllerProvider.notifier)
          .refresh(showLoading: false);
    } finally {
      _pendingPollInFlight = false;
    }
  }

  Future<void> _shareInvite(Pair pair) => SharePlus.instance.share(
    ShareParams(text: appL10n.pairShareInviteText(pair.inviteCode)),
  );

  Future<bool> _confirm({
    required String title,
    required String description,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(appL10n.commonCancel),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required Pair pair,
    String? successMessage,
  }) async {
    if (_actionInFlight) return;
    setState(() {
      _actionInFlight = true;
      _actionPair = pair;
    });
    await action();
    if (!mounted) return;
    setState(() {
      _actionInFlight = false;
      _actionPair = null;
    });
    if (successMessage != null) {
      BiteSyncSnackBar.show(context, message: successMessage);
    }
  }

  Future<void> _regenerate(Pair pair) async {
    if (!await _confirm(
      title: appL10n.pairRegenerateTitle,
      description: appL10n.pairRegenerateDescription,
      confirmLabel: appL10n.pairRegenerateInvite,
    )) {
      return;
    }
    await _runAction(
      () => ref.read(pairControllerProvider.notifier).regenerateInviteCode(),
      pair: pair,
      successMessage: appL10n.pairRegenerateSuccess,
    );
  }

  Future<void> _cancelInvite(Pair pair) async {
    if (!await _confirm(
      title: appL10n.pairCancelTitle,
      description: appL10n.pairCancelDescription,
      confirmLabel: appL10n.pairCancelConfirm,
    )) {
      return;
    }
    await _runAction(
      () => ref.read(pairControllerProvider.notifier).cancelPair(),
      pair: pair,
      successMessage: appL10n.pairCancelSuccess,
    );
  }

  Future<void> _endPair(Pair pair) async {
    if (!await _confirm(
      title: appL10n.pairEndTitle,
      description: appL10n.pairEndDescription,
      confirmLabel: appL10n.pairEndConfirm,
      destructive: true,
    )) {
      return;
    }
    await _runAction(
      () => ref.read(pairControllerProvider.notifier).endPair(),
      pair: pair,
      successMessage: appL10n.pairEndSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairState = ref.watch(pairControllerProvider);
    final isLoading = pairState is PairLoading || _actionInFlight;
    final pair = pairState is PairConnected
        ? pairState.pair
        : _actionInFlight
        ? _actionPair
        : null;
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
                    if (isPending) ...[
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
                            onPressed: isLoading
                                ? null
                                : () async {
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
                          IconButton(
                            tooltip: appL10n.pairShareInvite,
                            icon: const Icon(Icons.ios_share_outlined),
                            onPressed: isLoading
                                ? null
                                : () => _shareInvite(pair),
                          ),
                        ],
                      ),
                    ],
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
                    else ...[
                      Text(appL10n.pairPendingDescription),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _regenerate(pair),
                            icon: const Icon(Icons.refresh),
                            label: Text(appL10n.pairRegenerateInvite),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _cancelInvite(pair),
                            child: Text(appL10n.pairCancelInvite),
                          ),
                        ],
                      ),
                    ],
                    if (isConnected) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : () => _endPair(pair),
                        icon: const Icon(Icons.link_off),
                        label: Text(appL10n.pairEnd),
                      ),
                    ],
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
