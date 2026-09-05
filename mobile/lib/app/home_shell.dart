import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/presentation/add_meal_page.dart';
import '../features/summary/presentation/summary_page.dart';

/// Currently selected bottom-nav tab. MVP has exactly two tabs (今日 /
/// 记录) — training is intentionally not shown yet (see project brief).
/// A third tab can be added later by extending this without touching the
/// pages themselves.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell hosting the two MVP tabs. Kept as a plain
/// [IndexedStack] (rather than nested go_router routes) since there is no
/// deep-linking requirement for individual tabs at this stage.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [SummaryPage(), AddMealPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: '今日',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: '记录',
          ),
        ],
      ),
    );
  }
}
