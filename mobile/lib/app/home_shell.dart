import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytesync/l10n/l10n.dart';

import '../features/meals/presentation/add_meal_page.dart';
import '../features/summary/presentation/summary_page.dart';
import '../features/training/presentation/training_page.dart';
import '../features/profile/presentation/profile_page.dart';

/// Currently selected bottom-nav tab (今日 / 记录 / 训练).
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell hosting the primary app tabs. Kept as a plain
/// [IndexedStack] (rather than nested go_router routes) since there is no
/// deep-linking requirement for individual tabs at this stage.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [SummaryPage(), AddMealPage(), TrainingPage(), ProfilePage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: isDark ? Color(0xFF00AEFF) : null,
        unselectedItemColor: isDark ? Color(0xFF6F7075) : null,
        onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: appL10n.navToday,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: appL10n.navRecord,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: appL10n.navTraining,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: appL10n.navProfile,
          ),
        ],
      ),
    );
  }
}
