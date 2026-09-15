import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localizations accessor for presentation controllers that do not own a
/// [BuildContext]. Widgets should prefer [BuildContext.l10n].
AppLocalizations get appL10n {
  final platformLocale = PlatformDispatcher.instance.locale;
  final locale = AppLocalizations.supportedLocales.firstWhere(
    (supported) => supported.languageCode == platformLocale.languageCode,
    orElse: () => AppLocalizations.supportedLocales.first,
  );
  return lookupAppLocalizations(locale);
}
