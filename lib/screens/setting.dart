import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homemate/providers/theme_provider.dart';
import 'package:homemate/theme/app_theme.dart';
import 'package:homemate/services/local_storage_service.dart';
import 'package:homemate/screens/profile_info_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = true;

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textHint = AppTheme.getTextHint(isDark);

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12, top: 32),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textHint,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
    bool showArrow = true,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textHint = AppTheme.getTextHint(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final primary = AppTheme.getPrimary(isDark);

    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(AppTheme.radiusLg) : Radius.zero,
      bottom: isLast ? const Radius.circular(AppTheme.radiusLg) : Radius.zero,
    );

    return Material(
      color: surfaceColor,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (iconColor ?? primary).withOpacity(
                        isDark ? 0.16 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? textPrimary,
                      ),
                    ),
                  ),
                  if (value != null) ...[
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 14,
                        color: textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (trailing != null) trailing,
                  if (trailing == null && showArrow)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: textHint,
                    ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 80),
                child: Divider(
                  height: 1,
                  color: dividerColor.withOpacity(isDark ? 0.35 : 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'مستخدم@gofix.com';
    final userName = user?.displayName ?? userEmail.split('@').first;

    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final primary = AppTheme.getPrimary(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileInfoScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppTheme.darkSurface, AppTheme.darkElevated]
                        : [Colors.white, const Color(0xFFFCFDFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.getPremiumShadow(isDark),
                  border: Border.all(
                    color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                          style: const TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                              border: Border.all(color: dividerColor),
                            ),
                            child: Text(
                              userEmail,
                              style: TextStyle(
                                fontFamily: 'ElMessiri',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('عام'),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                ),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'الإشعارات',
                    showArrow: false,
                    isFirst: true,
                    isLast: true,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                      activeColor: primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionHeader('المظهر'),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                ),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'الوضع الداكن',
                    showArrow: false,
                    isFirst: true,
                    isLast: true,
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionHeader('سياسة ودعم'),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                ),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'عن التطبيق',
                    isFirst: true,
                    isLast: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                ),
              ),
              child: _buildSettingsTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                iconColor: AppTheme.errorColor,
                textColor: AppTheme.errorColor,
                showArrow: false,
                isFirst: true,
                isLast: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(
            color: dividerColor.withOpacity(isDark ? 0.3 : 0.7),
          ),
        ),
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
          style: TextStyle(
            fontFamily: 'ElMessiri',
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalStorageService.clear();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('login', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final primary = AppTheme.getPrimary(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'images/Logo.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Go Fix',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'الإصدار 1.0.0',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
                textDirection: TextDirection.ltr,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: textSecondary.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيقنا يسعى الى توفير جميع الخدمات التي تخص منزلك من تنظيف وصيانة والاهتمام بالمرافق، وذلك بيد مهنيين ذو كفاءة واحترافية عالية والأهم من ذلك بيتك في أمان.\n\nالتطبيق يخدم ثلاثة محافظات حتى هذه اللحظة الا وهي عمان واربد والعقبة ونعمل على ضم باقي المحافظات في القريب العاجل.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'ElMessiri',
                      color: textPrimary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: primary.withOpacity(isDark ? 0.18 : 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.headset_mic_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تواصل معنا الدعم الفني',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            launchUrl(Uri.parse("mailto:gofix.app@gmail.com"));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email, size: 18, color: primary),
                              const SizedBox(width: 6),
                              Text(
                                'gofix.app@gmail.com',
                                style: TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500, // Medium
                                  color: primary,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}