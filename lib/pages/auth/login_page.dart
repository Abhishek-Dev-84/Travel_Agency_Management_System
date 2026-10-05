import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/server_config_dialog.dart';

import '../admin/admin_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../customer/customer_dashboard.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'Customer';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to Customer demo account for quick convenience
    _fillCredentials('customer@tams.local', 'TamsCustomer@123', 'Customer');
  }

  void _fillCredentials(String email, String password, String role) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _role = role;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text,
        role: _role.toUpperCase(),
      );

      if (!mounted) return;

      final userRole = user.role.toUpperCase();
      Widget targetDashboard;
      if (userRole == 'ADMIN' || userRole == 'STAFF') {
        targetDashboard = const AdminDashboard();
      } else if (userRole == 'DRIVER') {
        targetDashboard = const DriverDashboard();
      } else {
        targetDashboard = const CustomerDashboard();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetDashboard),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showApiSettingsDialog() {
    showServerConfigDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // Background ambient glows matching website
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.info.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Settings Icon Top Right
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white70),
                          tooltip: 'API Server Settings',
                          onPressed: _showApiSettingsDialog,
                        ),
                      ),

                      // Logo & Branding
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'TAMS',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Travel Agency Management System',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Card
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign In to Your Account',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Enter your credentials to access the portal',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 18),

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.error_outline, size: 18, color: AppTheme.danger),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(fontSize: 12, color: AppTheme.danger),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_errorMessage!.contains('Unable to connect') || _errorMessage!.contains('backend')) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: _showApiSettingsDialog,
                                            icon: const Icon(Icons.settings, size: 14),
                                            label: const Text('Configure Server / Connection Mode', style: TextStyle(fontSize: 11)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.danger,
                                              side: const BorderSide(color: AppTheme.danger),
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Email
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email / Username',
                                hint: 'e.g. admin@tams.local',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter email' : null,
                              ),
                              const SizedBox(height: 14),

                              // Password
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                validator: (v) => (v == null || v.isEmpty) ? 'Please enter password' : null,
                              ),
                              const SizedBox(height: 14),

                              // Role Selector
                              const Text(
                                'Select Role',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: ValueKey(_role),
                                initialValue: _role,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppTheme.textMuted),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                  DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                                  DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                                ],
                                onChanged: (v) => setState(() => _role = v!),
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              CustomButton(
                                text: 'Sign In',
                                isLoading: _isLoading,
                                onPressed: _handleLogin,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Fill Demo Accounts
                      const Text(
                        'Demo Quick-Fill Accounts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _demoChip('Admin', 'admin@tams.local', 'TamsAdmin@123', 'Admin'),
                          _demoChip('Staff', 'staff@tams.local', 'TamsStaff@123', 'Staff'),
                          _demoChip('Driver', 'driver@tams.local', 'TamsDriver@123', 'Driver'),
                          _demoChip('Customer', 'customer@tams.local', 'TamsCustomer@123', 'Customer'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Register Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have a customer account? ",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterPage()),
                              );
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, String email, String password, String role) {
    final isSelected = _role == role && _emailController.text == email;

    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
      ),
      backgroundColor: isSelected ? AppTheme.accent : const Color(0xFF1B3A5C),
      side: BorderSide(
        color: isSelected ? AppTheme.accent : const Color(0xFF264D73),
      ),
      onPressed: () => _fillCredentials(email, password, role),
    );
  }
}