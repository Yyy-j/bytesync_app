import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pair_state.dart';
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
      appBar: AppBar(title: const Text('与搭档配对')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '与搭档配对',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('先创建一个配对，或输入搭档发来的邀请码。'),
          if (pairState is PairFailure) ...[
            const SizedBox(height: 20),
            Text(pairState.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (connected?.showInviteCode ?? false) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('你的邀请码'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            connected!.pair.inviteCode,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: '复制邀请码',
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: connected.pair.inviteCode));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('邀请码已复制')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('让搭档输入此邀请码'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.read(pairControllerProvider.notifier).continueToHome(),
                      child: const Text('进入主页'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(pairControllerProvider.notifier).createPair(),
              icon: const Icon(Icons.add_link),
              label: const Text('创建配对'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            TextField(
              controller: _inviteCodeController,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '邀请码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(pairControllerProvider.notifier).joinPair(_inviteCodeController.text),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('加入配对'),
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
