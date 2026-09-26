import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

final themeModeControllerProvider = ChangeNotifierProvider<ThemeModeController>(
  (ref) {
    final controller = ThemeModeController();
    controller.load();
    return controller;
  },
);

class ThemeModeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_themeModeKey);
    if (saved == null) return;
    final next = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.system || mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
