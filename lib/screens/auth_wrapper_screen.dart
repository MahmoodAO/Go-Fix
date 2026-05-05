import 'package:flutter/material.dart';
import 'package:homemate/services/local_storage_service.dart';
import 'package:homemate/theme/app_theme.dart';

/// Splash/auth decision screen shown at app startup.
/// Checks local storage to decide whether to show the main app or welcome/login.
class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await LocalStorageService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Route based on locally stored role
      final role = await LocalStorageService.getUserRole();
      if (!mounted) return;
      String destination;
      if (role == 'admin') {
        destination = '/admin';
      } else if (role == 'provider') {
        destination = 'provider_tabscreen';
      } else {
        destination = 'tabscreen';
      }
      Navigator.of(context).pushReplacementNamed(destination);
    } else {
      final onboardingCompleted = await LocalStorageService.isOnboardingCompleted();
      if (!mounted) return;
      if (onboardingCompleted) {
        Navigator.of(context).pushReplacementNamed('login');
      } else {
        Navigator.of(context).pushReplacementNamed('welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.getPrimary(isDark).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'images/Logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppTheme.getPrimary(isDark),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
