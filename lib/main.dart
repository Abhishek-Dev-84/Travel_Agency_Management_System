import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/driver/driver_dashboard.dart';
import 'pages/customer/customer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();

  runApp(const TamsApp());
}

class TamsApp extends StatelessWidget {
  const TamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    Widget initialScreen;
    if (auth.isAuthenticated) {
      final role = auth.role.toUpperCase();
      if (role == 'ADMIN' || role == 'STAFF') {
        initialScreen = const AdminDashboard();
      } else if (role == 'DRIVER') {
        initialScreen = const DriverDashboard();
      } else {
        initialScreen = const CustomerDashboard();
      }
    } else {
      initialScreen = const LoginPage();
    }

    return MaterialApp(
      title: 'TAMS · Travel Agency Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
