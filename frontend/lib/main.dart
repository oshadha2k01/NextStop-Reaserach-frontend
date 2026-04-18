import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/welcome/splash_screen.dart';
import 'screens/welcome/onboarding_screen.dart';
import 'screens/welcome/onboarding2_screen.dart';
import 'screens/permission/permission_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'features/home/presentation/screens/home_page.dart';
import 'screens/shared/success_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextStop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/onboarding2': (context) => const Onboarding2Screen(),
        '/permission': (context) => const PermissionScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/home': (context) => const HomePage(),
        '/s': (context) => const SuccessPage(),
      },
    );
  }
}
