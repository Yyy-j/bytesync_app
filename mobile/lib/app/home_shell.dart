import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          SummaryPage(),
          AddMealPage(),
          TrainingPage(),
          ProfilePage(),
        ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: '训练',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
