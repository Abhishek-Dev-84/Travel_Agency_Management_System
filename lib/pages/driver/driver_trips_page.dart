import 'package:flutter/material.dart';
import '../../models/duty_slip_model.dart';
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

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  final ApiService _api = ApiService();

  List<DutySlipModel> _slips = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Upcoming', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getMyDutySlips();
      if (mounted) {
        setState(() {
          _slips = list;
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
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid odometer reading' : null,
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
                        _loadTrips();
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
                    if (val == null) return 'Enter valid odometer reading';
                    if (val < startOdo) return 'Cannot be less than start odometer ($startOdo km)';
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
                        _loadTrips();
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
    final filtered = _selectedStatus == 'All'
        ? _slips
        : _slips.where((s) => s.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();

    return Scaffold(
      appBar: TamsAppBar(
        title: 'My Assigned Trips',
        onRefresh: _loadTrips,
      ),
      drawer: const TamsDrawer(currentRoute: 'My Trips & Duty Slips'),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
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
                        if (val) setState(() => _selectedStatus = st);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading assigned trips...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadTrips)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.route_outlined,
                            title: 'No Trips Found',
                            description: 'No trips match the selected status filter.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTrips,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final s = filtered[index];
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
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: AppTheme.primary,
                                              ),
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
                                                  'Passenger: ${s.customerName} (${s.customerPhone})',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (s.startOdometer != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.speed, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Odometer: ${s.startOdometer} km → ${s.endOdometer != null ? "${s.endOdometer} km" : "In Progress"}',
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
                          ),
          ),
        ],
      ),
    );
  }
}
