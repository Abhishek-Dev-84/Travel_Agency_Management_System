import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

class DriverManagementPage extends StatefulWidget {
  const DriverManagementPage({super.key});

  @override
  State<DriverManagementPage> createState() => _DriverManagementPageState();
}

class _DriverManagementPageState extends State<DriverManagementPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DriverModel> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Available', 'On Duty', 'On Leave', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getDrivers(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _drivers = list;
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

  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final licNumCtrl = TextEditingController();
    final expYearsCtrl = TextEditingController(text: '3');
    final licExpiryCtrl = TextEditingController();
    final bloodCtrl = TextEditingController(text: 'O+');
    final addressCtrl = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
    licExpiryCtrl.text = selectedDate.toIso8601String().split('T').first;

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register New Driver',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: nameCtrl,
                    label: 'Driver Full Name *',
                    hint: 'e.g. Alok Das',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Driver name required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number *',
                    hint: '10-digit mobile number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Valid phone number required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: licNumCtrl,
                    label: 'Driving License Number *',
                    hint: 'e.g. OD-2021-123456',
                    prefixIcon: Icons.credit_card_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'License number required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: licExpiryCtrl,
                          label: 'License Expiry *',
                          hint: 'YYYY-MM-DD',
                          prefixIcon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                                licExpiryCtrl.text = picked.toIso8601String().split('T').first;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: expYearsCtrl,
                          label: 'Experience (Years)',
                          hint: '3',
                          prefixIcon: Icons.timeline_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: bloodCtrl,
                          label: 'Blood Group',
                          hint: 'O+',
                          prefixIcon: Icons.bloodtype_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: emailCtrl,
                          label: 'Email Address',
                          hint: 'driver@tams.local',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: addressCtrl,
                    label: 'Address',
                    hint: 'City, Odisha',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Register Driver',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);
                      try {
                        await _api.createDriver({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'license_number': licNumCtrl.text.trim(),
                          'license_expiry': licExpiryCtrl.text.trim(),
                          'experience_years': int.tryParse(expYearsCtrl.text.trim()) ?? 1,
                          'blood_group': bloodCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'status': 'Available',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadDrivers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Driver registered successfully in PostgreSQL')),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Driver Management',
        onRefresh: _loadDrivers,
      ),
      drawer: const TamsDrawer(currentRoute: 'Drivers'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showAddDriverDialog,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadDrivers(),
                  decoration: InputDecoration(
                    hintText: 'Search by driver name, ID or license...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadDrivers();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((st) {
                      final isSel = _selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(st),
                          selected: isSel,
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textDark,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatus = st);
                              _loadDrivers();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Drivers List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading drivers from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadDrivers)
                    : _drivers.isEmpty
                        ? EmptyState(
                            icon: Icons.badge_outlined,
                            title: 'No Drivers Found',
                            description: 'No driver profiles match your filter or search query.',
                            actionText: 'Register Driver',
                            onAction: _showAddDriverDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDrivers,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _drivers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final d = _drivers[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                              child: Text(
                                                d.name.isNotEmpty ? d.name[0].toUpperCase() : 'D',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.primary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          d.name,
                                                          style: const TextStyle(
                                                            fontSize: 15.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: AppTheme.textDark,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.bgLight,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: AppTheme.border),
                                                        ),
                                                        child: Text(
                                                          d.driverId,
                                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${d.phone} · ${d.experienceYears} yrs exp',
                                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(status: d.status),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.credit_card, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Lic: ${d.licenseNumber}',
                                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: d.isLicenseValid ? AppTheme.successSoft : AppTheme.dangerSoft,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Exp: ${d.licenseExpiry} (${d.licenseStatus})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: d.isLicenseValid ? AppTheme.success : AppTheme.danger,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}