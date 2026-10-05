import 'package:flutter/material.dart';
import '../../models/duty_slip_model.dart';
import '../../models/driver_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

import 'driver_trips_page.dart';
import 'driver_profile_page.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final ApiService _api = ApiService();

  DriverModel? _profile;
  List<DutySlipModel> _mySlips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pFuture = _api.getDriverMyProfile();
      final sFuture = _api.getMyDutySlips();
      final profile = await pFuture;
      final slips = await sFuture;

      if (mounted) {
        setState(() {
          _profile = profile;
          _mySlips = slips;
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _api.updateDriverStatus(newStatus);
      _loadDriverData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duty status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _showStartTripDialog(DutySlipModel slip) {
    final odoCtrl = TextEditingController(text: slip.startOdometer?.toString() ?? '15000');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Start Trip ${slip.slipId}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route: ${slip.pickup} → ${slip.destination}\nVehicle: ${slip.vehicleName} (${slip.vehicleReg})',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: odoCtrl,
                  label: 'Start Odometer (KM) *',
                  hint: 'e.g. 15000',
                  prefixIcon: Icons.speed,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid odometer number' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.info),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSaving = true);
                      try {
                        await _api.startTrip(slip.id, int.parse(odoCtrl.text.trim()));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadDriverData();
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: const Text('Start Trip'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteTripDialog(DutySlipModel slip) {
    final startOdo = slip.startOdometer ?? 15000;
    final odoCtrl = TextEditingController(text: (startOdo + 120).toString());
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Complete Trip ${slip.slipId}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Odometer: $startOdo km\nVehicle: ${slip.vehicleName}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: odoCtrl,
                  label: 'Closing Odometer (KM) *',
                  hint: 'e.g. ${startOdo + 100}',
                  prefixIcon: Icons.speed,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = int.tryParse(v ?? '');
                    if (val == null) return 'Enter valid odometer number';
                    if (val < startOdo) return 'Cannot be less than start ($startOdo km)';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSaving = true);
                      try {
                        await _api.completeTrip(slip.id, int.parse(odoCtrl.text.trim()));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadDriverData();
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                          );
                        }
                      }
                    },
              child: const Text('Complete Trip'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Driver Portal',
        onRefresh: _loadDriverData,
      ),
      drawer: const TamsDrawer(currentRoute: 'Dashboard'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading driver roster & trips...')
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _loadDriverData)
              : RefreshIndicator(
                  onRefresh: _loadDriverData,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Banner Card
                        _buildProfileCard(),
                        const SizedBox(height: 16),

                        // Duty Status Toggle
                        _buildStatusToggle(),
                        const SizedBox(height: 20),

                        // Stats Summary
                        _buildStatsSummary(),
                        const SizedBox(height: 24),

                        // Active / Upcoming Trips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MY ASSIGNED DISPATCH SLIPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripsPage())),
                              child: const Text(
                                'View All →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_mySlips.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.assignment_outlined, size: 40, color: AppTheme.textMuted),
                                    const SizedBox(height: 8),
                                    const Text('No Trips Assigned', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    const Text('You have no active trips dispatched at this time.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _mySlips.length > 3 ? 3 : _mySlips.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final s = _mySlips[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.slipId,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary),
                                          ),
                                          StatusBadge(status: s.status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.route, size: 16, color: AppTheme.accent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${s.pickup} → ${s.destination}',
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.directions_car, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Text('${s.vehicleName} (${s.vehicleReg})', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Text('${s.date} ${s.time}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (s.customerName.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 14, color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Client: ${s.customerName} (${s.customerPhone})',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (s.status == 'Upcoming' || s.status == 'In Progress') ...[
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (s.status == 'Upcoming')
                                              CustomButton(
                                                text: 'Start Trip',
                                                icon: Icons.play_arrow,
                                                color: AppTheme.info,
                                                height: 36,
                                                width: 130,
                                                onPressed: () => _showStartTripDialog(s),
                                              ),
                                            if (s.status == 'In Progress')
                                              CustomButton(
                                                text: 'Complete Trip',
                                                icon: Icons.check,
                                                color: AppTheme.success,
                                                height: 36,
                                                width: 140,
                                                onPressed: () => _showCompleteTripDialog(s),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    final name = _profile?.name ?? 'Driver';
    final id = _profile?.driverId ?? 'DRV-101';
    final licExp = _profile?.licenseExpiry ?? '';
    final licStatus = _profile?.licenseStatus ?? 'Valid';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DriverProfilePage()),
        ).then((_) => _loadDriverData());
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.accent,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            id,
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lic: ${_profile?.licenseNumber ?? "—"} (Exp: $licExp)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: $licStatus · ${_profile?.experienceYears ?? 1} yrs experience',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    final curStatus = _profile?.status ?? 'Available';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CURRENT DUTY STATUS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statusBtn('Available', curStatus == 'Available', AppTheme.success),
                const SizedBox(width: 8),
                _statusBtn('On Duty', curStatus == 'On Duty', AppTheme.info),
                const SizedBox(width: 8),
                _statusBtn('On Leave', curStatus == 'On Leave', AppTheme.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(String label, bool isSelected, Color col) {
    return Expanded(
      child: InkWell(
        onTap: () => _updateStatus(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? col : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? col : AppTheme.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final upcoming = _mySlips.where((s) => s.status == 'Upcoming').length;
    final inProg = _mySlips.where((s) => s.status == 'In Progress').length;
    final done = _mySlips.where((s) => s.status == 'Completed').length;

    return Row(
      children: [
        Expanded(
          child: _countCard('Upcoming', upcoming.toString(), AppTheme.warning),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _countCard('In Progress', inProg.toString(), AppTheme.info),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _countCard('Completed', done.toString(), AppTheme.success),
        ),
      ],
    );
  }

  Widget _countCard(String label, String count, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: col)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}