import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'language_config.dart';

extension OfertixLocalizationX on BuildContext {
  String tx(String key, {List<String>? args, Map<String, String>? namedArgs}) {
    return tr(key, args: args, namedArgs: namedArgs);
  }

  String get languageCode => locale.languageCode;

  bool get isRtlLanguage => LanguageConfig.isRtl(locale.languageCode);
}
