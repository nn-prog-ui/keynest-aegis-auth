import 'package:flutter/material.dart';

import 'keynest/keynest_app.dart';
import 'screens/login_screen.dart';
import 'screens/mail_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VenemoApp());
}

class VenemoApp extends StatelessWidget {
  const VenemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF007AFF),
        surface: Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F7),
        foregroundColor: Color(0xFF1D1D1F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: const Color(0x14000000),
      fontFamily: 'SF Pro Text',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );

    return MaterialApp(
      title: 'Venemo',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x14000000)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x14000000)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/mail_list': (_) => const MailListScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/aegis_auth': (_) => const AegisAuthApp(),
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}
