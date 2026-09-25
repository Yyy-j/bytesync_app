import 'dart:async';

import 'package:flutter/material.dart';

class BiteSyncSnackBar {
  const BiteSyncSnackBar._();

  static const duration = Duration(seconds: 4);

  static void show(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
  }) {
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        action: action,
      ),
    );

    var closed = false;
    controller.closed.then((_) => closed = true);
    Timer(duration, () {
      if (!closed) controller.close();
    });
  }
}
