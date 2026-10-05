import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';
import 'my_booking_page.dart';

class BookingPage extends StatefulWidget {
  final VehicleModel? preselectedVehicle;

  const BookingPage({super.key, this.preselectedVehicle});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  List<VehicleModel> _availableVehicles = [];
  bool _isLoadingVehicles = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _selectedVehicleId;
  final _pickupLocCtrl = TextEditingController(text: 'Bhubaneswar Airport');
  final _destLocCtrl = TextEditingController(text: 'Puri Sea Beach Resort');
  final _passengersCtrl = TextEditingController(text: '2');
  final _notesCtrl = TextEditingController();

  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 3));

  late TextEditingController _pickupDateCtrl;
  late TextEditingController _returnDateCtrl;

  @override
  void initState() {
    super.initState();
    _pickupDateCtrl = TextEditingController(text: _pickupDate.toIso8601String().split('T').first);
    _returnDateCtrl = TextEditingController(text: _returnDate.toIso8601String().split('T').first);
    _loadAvailableVehicles();
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      final list = await _api.getVehicles(status: 'Available');
      if (mounted) {
        setState(() {
          _availableVehicles = list;
          _isLoadingVehicles = false;
          if (widget.preselectedVehicle != null) {
            _selectedVehicleId = widget.preselectedVehicle!.id;
          } else if (list.isNotEmpty) {
            _selectedVehicleId = list.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available vehicle')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final selectedVeh = _availableVehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
    final days = _returnDate.difference(_pickupDate).inDays + 1;
    final safeDays = days > 0 ? days : 1;
    final estFare = (selectedVeh != null ? selectedVeh.perDayRate : 2000.0) * safeDays;

    try {
      await _api.createBooking({
        'vehicle_id': _selectedVehicleId,
        'pickup_location': _pickupLocCtrl.text.trim(),
        'destination_location': _destLocCtrl.text.trim(),
        'pickup_date': _pickupDateCtrl.text.trim(),
        'return_date': _returnDateCtrl.text.trim(),
        'passengers': int.tryParse(_passengersCtrl.text.trim()) ?? 1,
        'base_fare': estFare.toStringAsFixed(2),
        'notes': _notesCtrl.text.trim(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              SizedBox(width: 8),
              Text('Booking Confirmed!'),
            ],
          ),
          content: Text(
            'Your reservation for ${selectedVeh?.makeModel ?? "the vehicle"} has been successfully recorded in PostgreSQL. An invoice with 5% GST tax has been generated.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                );
              },
              child: const Text('View My Bookings'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _returnDate.difference(_pickupDate).inDays + 1;
    final safeDays = days > 0 ? days : 1;
    final selectedVeh = _availableVehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;
    final dailyRate = selectedVeh?.perDayRate ?? 2000.0;
    final baseFare = dailyRate * safeDays;
    final gstTax = baseFare * 0.05;
    final totalPayable = baseFare + gstTax;

    return Scaffold(
      appBar: TamsAppBar(
        title: 'Reserve a Vehicle',
      ),
      drawer: const TamsDrawer(currentRoute: 'Book a Vehicle'),
      body: _isLoadingVehicles
          ? const LoadingIndicator(message: 'Checking fleet availability in PostgreSQL...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 20, color: AppTheme.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Step 1: Vehicle Selection Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELECT FLEET VEHICLE',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 10),
                            if (_availableVehicles.isEmpty)
                              const Text('No vehicles available for booking right now.', style: TextStyle(color: AppTheme.danger))
                            else
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _selectedVehicleId,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.directions_car, color: AppTheme.accent),
                                ),
                                items: _availableVehicles.map((v) {
                                  return DropdownMenuItem<int>(
                                    value: v.id,
                                    child: Text(
                                      '${v.makeModel} (${AppTheme.formatCurrency(v.perDayRate)}/day)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedVehicleId = v),
                                validator: (v) => v == null ? 'Please select a vehicle' : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 2: Trip Itinerary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRIP ROUTE & SCHEDULE',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _pickupLocCtrl,
                              label: 'Pickup Location *',
                              hint: 'Airport, Hotel, Address',
                              prefixIcon: Icons.my_location,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pickup location required' : null,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _destLocCtrl,
                              label: 'Destination Location *',
                              hint: 'City, Tourist spot, Hotel',
                              prefixIcon: Icons.location_on_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Destination required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _pickupDateCtrl,
                                    label: 'Pickup Date *',
                                    prefixIcon: Icons.calendar_today,
                                    readOnly: true,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _pickupDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _pickupDate = picked;
                                          _pickupDateCtrl.text = picked.toIso8601String().split('T').first;
                                          if (_returnDate.isBefore(_pickupDate)) {
                                            _returnDate = _pickupDate;
                                            _returnDateCtrl.text = _returnDate.toIso8601String().split('T').first;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _returnDateCtrl,
                                    label: 'Return Date *',
                                    prefixIcon: Icons.calendar_month,
                                    readOnly: true,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _returnDate.isBefore(_pickupDate) ? _pickupDate : _returnDate,
                                        firstDate: _pickupDate,
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _returnDate = picked;
                                          _returnDateCtrl.text = picked.toIso8601String().split('T').first;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _passengersCtrl,
                                    label: 'Passengers',
                                    prefixIcon: Icons.people_outline,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _notesCtrl,
                                    label: 'Special Requests',
                                    hint: 'e.g. Child seat',
                                    prefixIcon: Icons.edit_note,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 3: Fare & Tax Estimation Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRICE ESTIMATE (LIVE CALCULATOR)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 12),
                            _calcRow('Vehicle Daily Rate', AppTheme.formatCurrency(dailyRate)),
                            _calcRow('Trip Duration', '$safeDays day(s)'),
                            _calcRow('Base Fare', AppTheme.formatCurrency(baseFare)),
                            _calcRow('GST Tax (5%)', AppTheme.formatCurrency(gstTax)),
                            const Divider(height: 16, color: AppTheme.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Grand Total (Payable)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    AppTheme.formatCurrency(totalPayable),
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.accentDark),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Confirm & Reserve Vehicle',
                      isLoading: _isSubmitting,
                      onPressed: _submitBooking,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _calcRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}