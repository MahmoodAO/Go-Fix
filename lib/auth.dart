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
class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    final role = await UserService().getUserRole(widget.uid);
    await LocalStorageService.setUserRole(role);
    if (!mounted) return;

    if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin');
    } else if (role == 'provider') {
      Navigator.of(context).pushReplacementNamed('provider_tabscreen');
    } else {
      Navigator.of(context).pushReplacementNamed('tabscreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
