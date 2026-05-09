import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:homemate/auth/signup_screen.dart';
import 'package:homemate/auth.dart';
import 'package:homemate/screens/Admin_screen.dart';
import 'package:homemate/screens/add_service.dart';
import 'package:homemate/screens/categorie_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:homemate/firebase_options.dart';
import 'package:homemate/auth/login_screen.dart';
import 'package:homemate/screens/category_services_screen.dart';
import 'package:homemate/screens/service_details_screen.dart';
import 'package:homemate/screens/booking_screen.dart';
import 'package:homemate/screens/booking_details_screen.dart';
import 'package:homemate/screens/profile_info_screen.dart';
import 'package:homemate/screens/generate_report.dart';

import 'package:homemate/core/theme/app_theme.dart';
import './screens/filters_screen.dart';
import 'package:homemate/screens/welcome_screen.dart';
import 'package:homemate/screens/tabs_screen.dart';
import 'package:homemate/screens/provider/provider_tabs_screen.dart';
import 'package:homemate/screens/provider/provider_booking_details_screen.dart';
import 'package:homemate/screens/provider/provider_service_details_screen.dart';
import 'package:homemate/screens/auth_wrapper_screen.dart';


import 'package:provider/provider.dart';
import 'package:homemate/core/theme/theme_provider.dart';
import 'package:homemate/services/user_service.dart';

/// نقطة تشغيل التطبيق وتهيئة Firebase ومزود الثيم قبل بناء الواجهة.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة خدمات Firebase قبل تشغيل التطبيق.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// الجذر الرئيسي للتطبيق، ويضبط الثيم والمسارات وشاشة البداية.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// حالات الفلاتر المستخدمة في شاشة التصنيفات والخدمات.
  Map<String, bool> filters = {'Irbid': false, 'Amman': false, 'Aqaba': false};

  @override
  /// الاستماع لتغييرات جلسة المصادقة لأغراض المتابعة أثناء التطوير.
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (kDebugMode) {
        debugPrint(user == null ? 'User is currently signed out!' : 'User is signed in!');
      }
    });
  }

  /// تحديث قيم الفلاتر المشتركة بين الشاشات المرتبطة بالخدمات.
  void changeFilters(Map<String, bool> filterData) {
    setState(() {
      filters = filterData;
    });
  }

  @override
  /// بناء التطبيق بالكامل مع تفعيل الثيم والمسارات المسمّاة.
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'EN'), Locale('ar', 'AR')],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // شاشة البداية تحدد المسار المناسب حسب التخزين المحلي وحالة المستخدم.
      home: const AuthWrapperScreen(),
      routes: {
        'welcome': (context) => const WelcomScreen(),
        'login': (context) => const LoginScreen(),
        'signup': (context) => const SignupScreen(),
        'tabscreen': (context) => const TabsScreen(),
        'provider_tabscreen': (context) => const ProviderTabsScreen(),
        'auth': (context) => Auth(),
        'addservice': (context) => AddService(),
        '/admin': (context) => _AdminGuard(),
        'categoriescreen': (context) => CategoryScreen(),
        'generate_report': (ctx) => GenerateReportScreen(),
        CategoryServicesScreen.screenRoute:
            (context) => CategoryServicesScreen(filters: filters),
        FiltersScreen.screenRoute:
            (context) => FiltersScreen(filters, changeFilters),
        ServiceDetailsScreen.screenRoute:
            (context) => const ServiceDetailsScreen(),
        BookingScreen.screenRoute:
            (context) => const BookingScreen(),
        BookingDetailsScreen.screenRoute:
            (context) => const BookingDetailsScreen(),
        ProviderBookingDetailsScreen.screenRoute:
            (context) => const ProviderBookingDetailsScreen(),
        ProviderServiceDetailsScreen.screenRoute:
            (context) => const ProviderServiceDetailsScreen(),
        'profile': (context) => const ProfileInfoScreen(),
      },
    );
  }
}

/// Guard widget for the /admin route.
/// Verifies the current user is authenticated AND has role == 'admin'.
/// حارس مسار الإدارة للتحقق من الصلاحية قبل فتح لوحة التحكم.
class _AdminGuard extends StatefulWidget {
  @override
  State<_AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<_AdminGuard> {
  @override
  /// بدء التحقق من دور المستخدم مباشرة بعد فتح الحارس.
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  /// التحقق من أن المستخدم الحالي يملك دور الإدارة قبل السماح بالدخول.
  Future<void> _verifyAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('login');
      return;
    }

    try {
      // قراءة دور المستخدم من Firestore لتحديد صلاحية الوصول.
      final role = await UserService().getUserRole(user.uid);
      if (!mounted) return;

      if (role == 'admin') {
        // Verified — replace this guard with the real admin screen
        // توجيه المستخدم إلى شاشة الإدارة الفعلية بعد نجاح التحقق.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('غير مصرح لك بالوصول إلى لوحة الإدارة')),
        );
        Navigator.of(context).pushReplacementNamed('login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('login');
      }
    }
  }

  @override
  /// عرض حالة تحميل مؤقتة أثناء فحص صلاحيات الإدارة.
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
