import 'package:flutter/material.dart';
import 'package:homemate/theme/app_theme.dart';
import 'package:homemate/services/local_storage_service.dart';

class WelcomScreen extends StatefulWidget {
  static String id = 'welcomScreen';

  const WelcomScreen({super.key});

  @override
  _WelcomScreenState createState() => _WelcomScreenState();
}

class _WelcomScreenState extends State<WelcomScreen>
    with TickerProviderStateMixin {
  PageController nextpage = PageController();
  int pagenumber = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    nextpage.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void onPageChanged(int value) {
    setState(() {
      pagenumber = value;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Image container with elegant border
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: 240,
                  height: 240,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'ElMessiri',
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 17,
                fontFamily: 'ElMessiri',
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = pagenumber == 2;
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.onboardingGradient),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button row
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: pagenumber < 2
                        ? InkWell(
                            onTap: () async {
                              await LocalStorageService.setOnboardingCompleted(true);
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('login');
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'تخطي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'ElMessiri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 48),
                  ),
                ),
                // Page view
                Expanded(
                  child: PageView(
                    onPageChanged: onPageChanged,
                    controller: nextpage,
                    children: [
                      _buildOnboardingPage(
                        imagePath: 'images/m2.png',
                        title: 'أهلاً بك في Go Fix',
                        subtitle: 'الحل الأمثل لجميع احتياجات منزلك.',
                        isLast: false,
                      ),
                      _buildOnboardingPage(
                        imagePath: 'images/S1.jpg',
                        title: 'ما هو Go Fix؟',
                        subtitle:
                            'يوصلك بمهنيين ذوي خبرة لجميع احتياجات منزلك.',
                        isLast: false,
                      ),
                      _buildOnboardingPage(
                        imagePath: 'images/m3.png',
                        title: 'استكشف خدماتنا',
                        subtitle:
                            'اكتشف خدمات متنوعة مصممة خصيصًا لتلبية احتياجاتك',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                // Bottom controls area
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    children: [
                      // Dot indicator – amber accent on teal background
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final isActive = i == pagenumber;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              color: isActive
                                  ? AppTheme.accentColor
                                  : Colors.white.withOpacity(0.35),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Action button – amber accent for pop on teal bg
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isLast) {
                              await LocalStorageService.setOnboardingCompleted(true);
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('login');
                              }
                            } else {
                              nextpage.animateToPage(
                                pagenumber + 1,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: const Color(0xFF1A1A1A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isLast ? 'ابدأ الآن' : 'التالي'),
                              const SizedBox(width: 8),
                              Icon(
                                isLast
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
