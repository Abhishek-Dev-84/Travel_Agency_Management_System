import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final u = await AuthService().refreshProfile();
      if (mounted) {
        setState(() {
          _user = u;
          _nameCtrl.text = u.fullName;
          _phoneCtrl.text = u.phone;
          _addressCtrl.text = u.address;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final u = AuthService().user;
        setState(() {
          _user = u;
          if (u != null) {
            _nameCtrl.text = u.fullName;
            _phoneCtrl.text = u.phone;
            _addressCtrl.text = u.address;
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await AuthService().updateProfile({
        'first_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      setState(() => _isEditing = false);
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully in PostgreSQL')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Customer Profile',
        onRefresh: _loadProfile,
      ),
      drawer: const TamsDrawer(currentRoute: 'My Profile'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading user profile from PostgreSQL...')
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Role Banner
                    Card(
                      color: AppTheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.accent,
                              child: Text(
                                _user?.fullName.isNotEmpty == true ? _user!.fullName[0].toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.fullName ?? 'Customer',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _user?.email ?? '',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  StatusBadge(status: _user?.role ?? 'CUSTOMER'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profile Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ACCOUNT INFORMATION',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
                                ),
                                IconButton(
                                  icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 18, color: AppTheme.accent),
                                  onPressed: () => setState(() => _isEditing = !_isEditing),
                                ),
                              ],
                            ),
                            const Divider(height: 1, color: AppTheme.border),
                            const SizedBox(height: 12),

                            if (!_isEditing) ...[
                              _infoRow('Username', _user?.username ?? ''),
                              _infoRow('Email Address', _user?.email ?? ''),
                              _infoRow('Phone Number', _user?.phone.isNotEmpty == true ? _user!.phone : 'Not provided'),
                              _infoRow('Address', _user?.address.isNotEmpty == true ? _user!.address : 'Not provided'),
                              _infoRow('Account Status', _user?.isActive == true ? 'Active' : 'Inactive'),
                            ] else ...[
                              CustomTextField(controller: _nameCtrl, label: 'Full Name', prefixIcon: Icons.person),
                              const SizedBox(height: 12),
                              CustomTextField(controller: _phoneCtrl, label: 'Phone Number', prefixIcon: Icons.phone),
                              const SizedBox(height: 12),
                              CustomTextField(controller: _addressCtrl, label: 'Address', prefixIcon: Icons.location_on),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Save Profile',
                                isLoading: _isSaving,
                                onPressed: _saveProfile,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}