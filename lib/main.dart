import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

import 'screens/country_selection_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/coin_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CoinService.loadCoins();
  await NotificationService.init();

  runApp(const OfertixApp());
}

class OfertixApp extends StatefulWidget {
  const OfertixApp({super.key});

  static _OfertixAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_OfertixAppState>();
  }

  @override
  State<OfertixApp> createState() => _OfertixAppState();
}

class _OfertixAppState extends State<OfertixApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late Future<bool> _startFuture;

  @override
  void initState() {
    super.initState();
    _startFuture = _loadUserSettings();
  }

  Future<bool> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString('theme_mode') ?? 'dark';
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    final country = prefs.getString('country');
    return country != null;
  }

  Future<void> changeTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: _startFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }

          if (snapshot.data == true) {
            return const HomeScreen();
          }

          return const CountrySelectionScreen();
        },
      ),
    );
  }
}
