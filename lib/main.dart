import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';

import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';

import 'core/theme/app_theme.dart';

import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/country_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/rewards_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', mergeWith: {}, isOptional: true);

  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
        Locale('de'),
        Locale('it'),
        Locale('pt'),
      ],

      path: 'assets/lang',

      fallbackLocale: const Locale('es'),

      child: const OfertixApp(),
    ),
  );
}

class OfertixApp extends StatelessWidget {
  const OfertixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProvider(create: (_) => LocaleProvider()),

        ChangeNotifierProvider(create: (_) => CountryProvider()),

        ChangeNotifierProvider(create: (_) => CurrencyProvider()),

        ChangeNotifierProvider(create: (_) => FavoritesProvider()),

        ChangeNotifierProvider(create: (_) => WatchlistProvider()),

        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],

      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Ofertix',

            debugShowCheckedModeBanner: false,

            locale: context.locale,

            supportedLocales: context.supportedLocales,

            localizationsDelegates: context.localizationDelegates,

            theme: themeProvider.isDark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,

            initialRoute: AppRoutes.splash,

            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
