import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/screens/categorie_screen.dart';
import 'package:homemate/screens/favorite_screen.dart';
import 'package:homemate/screens/my_bookings_screen.dart';
import 'package:homemate/screens/setting.dart';
import 'package:homemate/screens/profile_info_screen.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:homemate/core/theme/theme_provider.dart';

/// الشاشة الرئيسية للعميل، وتدير التنقل بين التبويبات الأساسية للتطبيق.
class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => TabsScreenState();
}

class TabsScreenState extends State<TabsScreen> {
  /// مؤشر التبويب الحالي والقائمة المرتبطة به من الشاشات.
  int _selectedScreenIndex = 0;
  late List<Widget> screens;

  final List<String> _titles = ['الرئيسية', 'المفضلة', 'حجوزاتي', 'الإعدادات'];

  @override
  /// تهيئة الشاشات التي ستظهر داخل التبويبات السفلية.
  void initState() {
    super.initState();
    screens = [
      const CategoryScreen(),
      const FavoriteServicesScreen(),
      const MyBookingsScreen(),
      const SettingScreen(),
    ];
  }

  /// تحديث التبويب النشط عند اختيار عنصر من شريط التنقل السفلي.
  void _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  @override
  /// بناء واجهة التبويبات مع الشريط العلوي والتنقل السفلي.
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primary = AppTheme.getPrimary(isDark);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedScreenIndex],
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
                // الانتقال إلى شاشة الملف الشخصي عند الضغط على صورة المستخدم.
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
                child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarInitial(userName),
                        ),
                      )
                    : _buildAvatarInitial(userName),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: screens[_selectedScreenIndex],
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
                icon: Icons.favorite_rounded,
                label: 'المفضلة',
                index: 1,
                isDark: isDark,
                primary: primary,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'حجوزاتي',
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

  /// بناء عنصر تنقل سفلي موحد لكل تبويب.
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
    required Color primary,
  }) {
    final isSelected = _selectedScreenIndex == index;

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

  /// إنشاء الحرف الأول من اسم المستخدم كبديل في صورة الملف الشخصي.
  Widget _buildAvatarInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
