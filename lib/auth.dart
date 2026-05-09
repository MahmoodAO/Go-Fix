import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:homemate/auth/login_screen.dart';
import 'package:homemate/screens/tabs_screen.dart';
import 'package:homemate/screens/provider/provider_tabs_screen.dart';
import 'package:homemate/screens/Admin_screen.dart';
import 'package:homemate/services/user_service.dart';
import 'package:homemate/core/utils/local_storage_service.dart';

/// StreamBuilder-based auth gate used by the 'auth' named route.
/// Now role-aware: routes admin → AdminScreen, provider → ProviderTabsScreen.
/// بوابة المصادقة العامة، وتحدد الشاشة المناسبة بناءً على حالة تسجيل الدخول.
class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  /// استخدام StreamBuilder للاستماع المباشر لحالة المصادقة وتوجيه المستخدم.
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // عرض مؤشر تحميل أثناء انتظار أول نتيجة من Firebase Auth.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // عند وجود مستخدم مسجل يتم تحديد الوجهة حسب الدور المخزن في Firestore.
          if (snapshot.hasData) {
            return _RoleRouter(uid: snapshot.data!.uid);
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

/// Fetches the user's role from Firestore and routes accordingly.
/// موجه داخلي يقرأ دور المستخدم ثم ينقله إلى الواجهة المناسبة.
class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  @override
  /// بدء قراءة الدور بمجرد إنشاء الموجه.
  void initState() {
    super.initState();
    _resolveRole();
  }

  /// جلب الدور من Firestore ثم حفظه محليًا لتسريع التوجيه لاحقًا.
  Future<void> _resolveRole() async {
    final role = await UserService().getUserRole(widget.uid);
    await LocalStorageService.setUserRole(role);
    if (!mounted) return;

    // التوجيه يعتمد على نوع المستخدم: إدارة أو مزود خدمة أو عميل.
    if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin');
    } else if (role == 'provider') {
      Navigator.of(context).pushReplacementNamed('provider_tabscreen');
    } else {
      Navigator.of(context).pushReplacementNamed('tabscreen');
    }
  }

  @override
  /// عرض شاشة تحميل قصيرة إلى أن يتم حسم التوجيه النهائي.
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
