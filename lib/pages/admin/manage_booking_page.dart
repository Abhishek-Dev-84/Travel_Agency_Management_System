import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
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

class ManageBookingPage extends StatefulWidget {
  const ManageBookingPage({super.key});

  @override
  State<ManageBookingPage> createState() => _ManageBookingPageState();
}

class _ManageBookingPageState extends State<ManageBookingPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getBookings(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _bookings = list;
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

  Future<void> _handleCancelBooking(BookingModel b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking ${b.bookingId}?'),
        content: const Text('Are you sure you want to cancel this booking? This will also cancel any unpaid invoices.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.cancelBooking(b.id);
      _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking ${b.bookingId} cancelled')),
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

  Future<void> _showAcceptAssignDialog(BookingModel b) async {
    List<DriverModel> drivers = [];
    try {
      drivers = await _api.getDrivers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load drivers: $e'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    if (!mounted) return;

    // Filter active and valid drivers
    final validDrivers = drivers.where((d) => d.isLicenseValid && d.status != 'Inactive' && d.status != 'On Leave').toList();
    int? selectedDriverId = validDrivers.isNotEmpty ? validDrivers.first.id : (drivers.isNotEmpty ? drivers.first.id : null);

    final timeCtrl = TextEditingController(text: '08:00 AM');
    final payoutCtrl = TextEditingController(text: '500');
    final remarksCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final selectedDriver = drivers.where((d) => d.id == selectedDriverId).firstOrNull;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accept Booking: ${b.bookingId}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Assign an available driver and issue trip duty slip',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Booking brief summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${b.customer?.name ?? "Customer"} (${b.customer?.phone ?? "N/A"})',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('Route: ${b.pickupLocation} → ${b.destinationLocation}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('Vehicle: ${b.vehicleName} · Dates: ${b.pickupDate} to ${b.returnDate}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Driver to Assign',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  if (drivers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No drivers found in system. Please add drivers first.',
                          style: TextStyle(color: AppTheme.danger, fontSize: 12.5)),
                    )
                  else
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: selectedDriverId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: drivers.map((d) {
                        final isExpired = !d.isLicenseValid;
                        return DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(
                            '${d.name} (${d.driverId}) · ${d.status}${isExpired ? " [EXPIRED LIC]" : ""}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isExpired ? AppTheme.danger : AppTheme.textDark,
                              fontWeight: isExpired ? FontWeight.w600 : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() => selectedDriverId = val);
                      },
                    ),
                  if (selectedDriver != null && !selectedDriver.isLicenseValid) ...[
                    const SizedBox(height: 6),
                    Text(
                      '⚠️ Warning: ${selectedDriver.name}\'s license expired on ${selectedDriver.licenseExpiry}. Backend will reject assignment of expired licenses.',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.danger),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Pickup / Report Time',
                          controller: timeCtrl,
                          prefixIcon: Icons.access_time,
                          hint: '08:00 AM',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Driver Advance (₹)',
                          controller: payoutCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.currency_rupee,
                          hint: '500',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Special Remarks / Instructions',
                    controller: remarksCtrl,
                    maxLines: 2,
                    hint: 'e.g. Flight arrival pickup, call passenger upon reaching',
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: isSaving ? 'Processing...' : 'Accept & Assign Driver',
                    icon: Icons.check_circle,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            setSheetState(() => isSaving = true);
                            try {
                              final payoutVal = double.tryParse(payoutCtrl.text.trim()) ?? 0.0;
                              final res = await _api.acceptBooking(
                                b.id,
                                driverId: selectedDriverId,
                                time: timeCtrl.text.trim(),
                                payout: payoutVal,
                                remarks: remarksCtrl.text.trim(),
                              );
                              navigator.pop();
                              _loadBookings();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Booking ${b.bookingId} accepted and assigned to ${res.assignedDriverName ?? "driver"}!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateBookingDialog() async {
    // Load available customers and vehicles
    List<CustomerModel> customers = [];
    List<VehicleModel> vehicles = [];

    try {
      final custFuture = _api.getCustomers();
      final vehFuture = _api.getVehicles(status: 'Available');
      customers = await custFuture;
      vehicles = await vehFuture;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading options: $e'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    if (!mounted) return;

    int? selectedCustomerId = customers.isNotEmpty ? customers.first.id : null;
    int? selectedVehicleId = vehicles.isNotEmpty ? vehicles.first.id : null;

    final pickupLocCtrl = TextEditingController(text: 'Bhubaneswar Airport');
    final destLocCtrl = TextEditingController(text: 'Puri Beach Resort');
    final passengersCtrl = TextEditingController(text: '2');
    final notesCtrl = TextEditingController();

    DateTime pickupDate = DateTime.now().add(const Duration(days: 1));
    DateTime returnDate = DateTime.now().add(const Duration(days: 3));

    final pickupDateCtrl = TextEditingController(text: pickupDate.toIso8601String().split('T').first);
    final returnDateCtrl = TextEditingController(text: returnDate.toIso8601String().split('T').first);

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
        builder: (ctx, setModalState) {
          // Calculate days & fare
          final days = returnDate.difference(pickupDate).inDays + 1;
          final safeDays = days > 0 ? days : 1;
          final selectedVeh = vehicles.where((v) => v.id == selectedVehicleId).firstOrNull;
          final estFare = (selectedVeh != null ? selectedVeh.perDayRate : 2000.0) * safeDays;

          return Padding(
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
                          'Create New Booking',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 10),

                    // Customer Selection
                    const Text('Select Customer *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCustomerId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.textMuted),
                      ),
                      items: customers.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedCustomerId = v),
                      validator: (v) => v == null ? 'Customer is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Vehicle Selection
                    const Text('Select Vehicle *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedVehicleId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.directions_car_outlined, size: 20, color: AppTheme.textMuted),
                      ),
                      items: vehicles.map((v) {
                        return DropdownMenuItem<int>(
                          value: v.id,
                          child: Text('${v.makeModel} (${AppTheme.formatCurrency(v.perDayRate)}/d)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedVehicleId = v),
                      validator: (v) => v == null ? 'Vehicle is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Locations
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: pickupLocCtrl,
                            label: 'Pickup Location *',
                            hint: 'e.g. Airport',
                            prefixIcon: Icons.my_location,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: destLocCtrl,
                            label: 'Destination *',
                            hint: 'e.g. Resort',
                            prefixIcon: Icons.location_on_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: pickupDateCtrl,
                            label: 'Pickup Date *',
                            prefixIcon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: pickupDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  pickupDate = picked;
                                  pickupDateCtrl.text = picked.toIso8601String().split('T').first;
                                  if (returnDate.isBefore(pickupDate)) {
                                    returnDate = pickupDate;
                                    returnDateCtrl.text = returnDate.toIso8601String().split('T').first;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: returnDateCtrl,
                            label: 'Return Date *',
                            prefixIcon: Icons.calendar_month_outlined,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: returnDate.isBefore(pickupDate) ? pickupDate : returnDate,
                                firstDate: pickupDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  returnDate = picked;
                                  returnDateCtrl.text = picked.toIso8601String().split('T').first;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Passengers & Estimated Fare Box
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: passengersCtrl,
                            label: 'Passengers',
                            prefixIcon: Icons.people_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Est. Fare ($safeDays days)', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  AppTheme.formatCurrency(estFare),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.accentDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: 'Confirm Booking',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isSaving = true);
                        try {
                          await _api.createBooking({
                            'customer_id': selectedCustomerId,
                            'vehicle_id': selectedVehicleId,
                            'pickup_location': pickupLocCtrl.text.trim(),
                            'destination_location': destLocCtrl.text.trim(),
                            'pickup_date': pickupDateCtrl.text.trim(),
                            'return_date': returnDateCtrl.text.trim(),
                            'passengers': int.tryParse(passengersCtrl.text.trim()) ?? 1,
                            'base_fare': estFare.toStringAsFixed(2),
                            'notes': notesCtrl.text.trim(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadBookings();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking created & Invoice auto-generated in PostgreSQL')),
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Booking Management',
        onRefresh: _loadBookings,
      ),
      drawer: const TamsDrawer(currentRoute: 'Bookings'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Booking', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showCreateBookingDialog,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadBookings(),
                  decoration: InputDecoration(
                    hintText: 'Search by booking ID, customer or route...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadBookings();
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
                              _loadBookings();
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

          // Booking List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading bookings from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadBookings)
                    : _bookings.isEmpty
                        ? EmptyState(
                            icon: Icons.calendar_month_outlined,
                            title: 'No Bookings Found',
                            description: 'No bookings match your filter or search query.',
                            actionText: 'Create Booking',
                            onAction: _showCreateBookingDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _bookings.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final b = _bookings[index];
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      b.bookingId,
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
                                                      b.customer?.name ?? 'Customer',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.textDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: b.status),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.route, size: 16, color: AppTheme.accent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${b.pickupLocation} → ${b.destinationLocation}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.directions_car, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${b.vehicleName}${b.vehicleRegistration.isNotEmpty ? ' (${b.vehicleRegistration})' : ''}',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.date_range, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${b.pickupDate} to ${b.returnDate} (${b.durationDays}d)',
                                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (b.assignedDriverName != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_pin, size: 14, color: AppTheme.success),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    'Driver: ${b.assignedDriverName}${b.assignedDriverPhone != null && b.assignedDriverPhone!.isNotEmpty ? ' (${b.assignedDriverPhone})' : ''}${b.dutySlipId != null ? ' · ${b.dutySlipId}' : ''}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              'Fare: ${AppTheme.formatCurrency(b.baseFare)}',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.accentDark,
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                if (b.status == 'Pending')
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.success,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                    icon: const Icon(Icons.check_circle_outline, size: 14),
                                                    label: const Text('Accept & Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                    onPressed: () => _showAcceptAssignDialog(b),
                                                  )
                                                else if (b.status == 'Confirmed' && b.assignedDriverName == null)
                                                  OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppTheme.primary,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                    icon: const Icon(Icons.person_add, size: 13),
                                                    label: const Text('Assign Driver', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                                    onPressed: () => _showAcceptAssignDialog(b),
                                                  ),
                                                if (b.status != 'Completed' && b.status != 'Cancelled')
                                                  TextButton.icon(
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    icon: const Icon(Icons.cancel_outlined, size: 14, color: AppTheme.danger),
                                                    label: const Text('Cancel', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                                                    onPressed: () => _handleCancelBooking(b),
                                                  ),
                                              ],
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