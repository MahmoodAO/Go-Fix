import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/screens/provider/provider_dashboard_screen.dart';
import 'package:homemate/screens/provider/provider_services_screen.dart';
import 'package:homemate/screens/provider/provider_bookings_screen.dart';
import 'package:homemate/screens/setting.dart';
import 'package:homemate/screens/profile_info_screen.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:homemate/core/theme/theme_provider.dart';

/// شاشة التبويب الرئيسية لمزوّد الخدمة.
/// Provider Tab Screen – main navigation shell for the provider role.
class ProviderTabsScreen extends StatefulWidget {
  const ProviderTabsScreen({super.key});

  @override
  State<ProviderTabsScreen> createState() => _ProviderTabsScreenState();
}

class _ProviderTabsScreenState extends State<ProviderTabsScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = ['الرئيسية', 'خدماتي', 'الطلبات', 'الإعدادات'];

  void _selectScreen(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primary = AppTheme.getPrimary(isDark);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? '';

    // Build screens list here so the dashboard gets the callback
    final screens = <Widget>[
      ProviderDashboardScreen(onSwitchTab: _selectScreen),
      const ProviderServicesScreen(),
      const ProviderBookingsScreen(),
      const SettingScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileInfoScreen(),
                  ),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppTheme.darkElevated, AppTheme.darkSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'الرئيسية',
                index: 0,
                isDark: isDark,
                primary: primary,
              ),
              _buildNavItem(
                icon: Icons.design_services_rounded,
                label: 'خدماتي',
                index: 1,
                isDark: isDark,
                primary: primary,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'الطلبات',
                index: 2,
                isDark: isDark,
                primary: primary,
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                index: 3,
                isDark: isDark,
                primary: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
    required Color primary,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectScreen(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? primary.withOpacity(0.15)
                  : primary.withOpacity(0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primary
                  : (isDark
                        ? AppTheme.darkTextSecondary.withOpacity(0.5)
                        : AppTheme.lightTextSecondary.withOpacity(0.5)),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
