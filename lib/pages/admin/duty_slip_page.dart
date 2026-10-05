import 'package:flutter/material.dart';
import '../../models/duty_slip_model.dart';
import '../../models/booking_model.dart';
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

class DutySlipPage extends StatefulWidget {
  const DutySlipPage({super.key});

  @override
  State<DutySlipPage> createState() => _DutySlipPageState();
}

class _DutySlipPageState extends State<DutySlipPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DutySlipModel> _slips = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Upcoming', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadSlips();
  }

  Future<void> _loadSlips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getDutySlips(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
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
          title: Text('Start Trip: ${slip.slipId}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver: ${slip.driverName}\nVehicle: ${slip.vehicleName} (${slip.vehicleReg})\nRoute: ${slip.pickup} → ${slip.destination}',
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
                        _loadSlips();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Trip ${slip.slipId} started! Vehicle set to "On Trip".')),
                          );
                        }
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
          title: Text('Complete Trip: ${slip.slipId}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Odometer: $startOdo km\nDriver: ${slip.driverName}\nVehicle: ${slip.vehicleName}',
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
                        _loadSlips();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Trip ${slip.slipId} completed! Vehicle & driver returned to "Available".')),
                          );
                        }
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

  void _showCreateDutySlipDialog() async {
    List<BookingModel> bookings = [];
    List<DriverModel> drivers = [];

    try {
      final bFuture = _api.getBookings(status: 'Pending');
      final dFuture = _api.getDrivers(status: 'Available');
      bookings = await bFuture;
      drivers = await dFuture;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    if (!mounted) return;

    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending bookings available to dispatch duty slip.')),
      );
      return;
    }

    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drivers currently available for duty assignment.')),
      );
      return;
    }

    int? selectedBookingId = bookings.first.id;
    int? selectedDriverId = drivers.first.id;
    final startOdoCtrl = TextEditingController(text: '15000');
    final timeCtrl = TextEditingController(text: '08:00');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        'Dispatch Duty Slip',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 10),

                  // Booking dropdown
                  const Text('Select Booking *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedBookingId,
                    items: bookings.map((b) {
                      return DropdownMenuItem<int>(
                        value: b.id,
                        child: Text('${b.bookingId} - ${b.customer?.name} (${b.vehicleName})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => selectedBookingId = v),
                    validator: (v) => v == null ? 'Booking required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Driver dropdown
                  const Text('Assign Driver *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedDriverId,
                    items: drivers.map((d) {
                      return DropdownMenuItem<int>(
                        value: d.id,
                        child: Text('${d.name} (${d.driverId}) · Lic: ${d.licenseStatus}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => selectedDriverId = v),
                    validator: (v) => v == null ? 'Driver required' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: startOdoCtrl,
                          label: 'Start Odometer (KM)',
                          hint: '15000',
                          prefixIcon: Icons.speed,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: timeCtrl,
                          label: 'Reporting Time',
                          hint: '08:00 AM',
                          prefixIcon: Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Generate Duty Slip',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);
                      try {
                        final b = bookings.where((x) => x.id == selectedBookingId).first;
                        await _api.createDutySlip({
                          'booking_id': selectedBookingId,
                          'driver_id': selectedDriverId,
                          'vehicle_id': b.vehicleId,
                          'date': b.pickupDate,
                          'time': timeCtrl.text.trim(),
                          'start_odometer': int.tryParse(startOdoCtrl.text.trim()) ?? 15000,
                          'pickup': b.pickupLocation,
                          'destination': b.destinationLocation,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadSlips();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Duty Slip created successfully!')),
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
        title: 'Duty Slips & Dispatch',
        onRefresh: _loadSlips,
      ),
      drawer: const TamsDrawer(currentRoute: 'Duty Slips'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_add),
        label: const Text('Dispatch Slip', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showCreateDutySlipDialog,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadSlips(),
                  decoration: InputDecoration(
                    hintText: 'Search by slip ID, driver, vehicle or booking...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadSlips();
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
                              _loadSlips();
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

          // Slip List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading duty slips from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadSlips)
                    : _slips.isEmpty
                        ? EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No Duty Slips Found',
                            description: 'No dispatch slips match your filter or search query.',
                            actionText: 'Dispatch Slip',
                            onAction: _showCreateDutySlipDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSlips,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _slips.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final s = _slips[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      s.slipId,
                                                      style: const TextStyle(
                                                        color: AppTheme.primary,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Booking: ${s.bookingCode}',
                                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: s.status),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.badge, size: 15, color: AppTheme.accent),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Driver: ${s.driverName}',
                                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.directions_car, size: 15, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${s.vehicleName}${s.vehicleReg.isNotEmpty ? ' (${s.vehicleReg})' : ''}',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.route, size: 15, color: AppTheme.textMuted),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${s.pickup} → ${s.destination}',
                                                style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
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
                                                const Icon(Icons.speed, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Odo: ${s.startOdometer ?? "—"} km → ${s.endOdometer != null ? "${s.endOdometer} km" : "Open"}',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${s.date} ${s.time}',
                                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                                                  icon: Icons.check_circle_outline,
                                                  color: AppTheme.success,
                                                  height: 36,
                                                  width: 150,
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