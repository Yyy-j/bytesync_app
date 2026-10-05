import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[BiteSync] API base URL: ${AppConfig.apiBaseUrl}');
  }
  await initializeDateFormatting('zh_CN');
  runApp(const ProviderScope(child: BiteSyncApp()));
}
