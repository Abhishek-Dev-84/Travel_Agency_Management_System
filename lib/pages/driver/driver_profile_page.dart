import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final ApiService _api = ApiService();

  DriverModel? _driver;
  bool _isLoading = true;
  String? _errorMessage;

  final _phoneCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final d = await _api.getDriverMyProfile();
      if (mounted) {
        setState(() {
          _driver = d;
          _phoneCtrl.text = d.phone;
          _bloodCtrl.text = d.bloodGroup;
          _addressCtrl.text = d.address;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _api.updateDriver(_driver!.id, {
        'phone': _phoneCtrl.text.trim(),
        'blood_group': _bloodCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      setState(() => _isEditing = false);
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
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
        title: 'Driver Profile',
        onRefresh: _loadProfile,
      ),
      drawer: const TamsDrawer(currentRoute: 'My Profile'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading driver credentials...')
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _loadProfile)
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
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
                                    _driver!.name.isNotEmpty ? _driver!.name[0].toUpperCase() : 'D',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _driver!.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Driver ID: ${_driver!.driverId}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(height: 6),
                                      StatusBadge(status: _driver!.status),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // License Details Box
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OFFICIAL LICENSE CREDENTIALS',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 12),
                                _infoRow('License Number', _driver!.licenseNumber),
                                _infoRow('License Expiry', _driver!.licenseExpiry),
                                _infoRow('License Status', _driver!.licenseStatus, isHighlight: true),
                                _infoRow('Driving Experience', '${_driver!.experienceYears} Years'),
                                _infoRow('Driver Rating', '⭐ ${_driver!.rating.toStringAsFixed(1)} / 5.0'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Details Box
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
                                      'CONTACT & PERSONAL INFO',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
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
                                  _infoRow('Phone Number', _driver!.phone),
                                  _infoRow('Email Address', _driver!.email.isNotEmpty ? _driver!.email : 'Not specified'),
                                  _infoRow('Blood Group', _driver!.bloodGroup.isNotEmpty ? _driver!.bloodGroup : 'Not recorded'),
                                  _infoRow('Residential Address', _driver!.address.isNotEmpty ? _driver!.address : 'Not recorded'),
                                ] else ...[
                                  CustomTextField(controller: _phoneCtrl, label: 'Phone Number', prefixIcon: Icons.phone),
                                  const SizedBox(height: 12),
                                  CustomTextField(controller: _bloodCtrl, label: 'Blood Group', prefixIcon: Icons.bloodtype),
                                  const SizedBox(height: 12),
                                  CustomTextField(controller: _addressCtrl, label: 'Address', prefixIcon: Icons.location_on),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    text: 'Save Changes',
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

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isHighlight ? AppTheme.accentDark : AppTheme.textDark,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
