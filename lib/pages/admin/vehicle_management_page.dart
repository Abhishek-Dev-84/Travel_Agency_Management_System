import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
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

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Available', 'On Trip', 'Maintenance', 'Unavailable'];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getVehicles(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _vehicles = list;
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

  void _showAddVehicleDialog() {
    final makeModelCtrl = TextEditingController();
    final regNumCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '2500');
    final capacityCtrl = TextEditingController(text: '4');
    final insuranceCtrl = TextEditingController();
    final permitCtrl = TextEditingController();

    String vehicleType = 'Sedan';
    String fuelType = 'Petrol';
    String transmission = 'Manual';
    bool ac = true;

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
                        'Add Fleet Vehicle',
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
                    controller: makeModelCtrl,
                    label: 'Make & Model *',
                    hint: 'e.g. Toyota Innova Crysta',
                    prefixIcon: Icons.directions_car_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Make & model required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: regNumCtrl,
                    label: 'Registration Number *',
                    hint: 'e.g. OD-02-AB-1234',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Registration number required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: vehicleType,
                              items: const [
                                DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                                DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                                DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
                                DropdownMenuItem(value: 'Van', child: Text('Van / Traveller')),
                              ],
                              onChanged: (v) => setModalState(() => vehicleType = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fuel Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: fuelType,
                              items: const [
                                DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                                DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                                DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                                DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                              ],
                              onChanged: (v) => setModalState(() => fuelType = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: rateCtrl,
                          label: 'Daily Rate (₹) *',
                          hint: '2500',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid rate' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: capacityCtrl,
                          label: 'Capacity (Seats) *',
                          hint: '4',
                          prefixIcon: Icons.event_seat,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter seats' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Transmission', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: transmission,
                              items: const [
                                DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                                DropdownMenuItem(value: 'Automatic', child: Text('Automatic')),
                              ],
                              onChanged: (v) => setModalState(() => transmission = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('AC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: ac,
                            onChanged: (v) => setModalState(() => ac = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: insuranceCtrl,
                    label: 'Insurance Info',
                    hint: 'Policy number & expiry',
                    prefixIcon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Save Vehicle to Fleet',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);
                      try {
                        await _api.createVehicle({
                          'make_model': makeModelCtrl.text.trim(),
                          'registration_number': regNumCtrl.text.trim(),
                          'vehicle_type': vehicleType,
                          'fuel_type': fuelType,
                          'capacity': int.parse(capacityCtrl.text.trim()),
                          'per_day_rate': rateCtrl.text.trim(),
                          'transmission': transmission,
                          'ac': ac,
                          'insurance_info': insuranceCtrl.text.trim(),
                          'permit_info': permitCtrl.text.trim(),
                          'status': 'Available',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadVehicles();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle added to fleet successfully')),
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
        title: 'Fleet Management',
        onRefresh: _loadVehicles,
      ),
      drawer: const TamsDrawer(currentRoute: 'Fleet / Vehicles'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showAddVehicleDialog,
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
                  onSubmitted: (_) => _loadVehicles(),
                  decoration: InputDecoration(
                    hintText: 'Search fleet by model or reg number...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadVehicles();
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
                              _loadVehicles();
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

          // Vehicle List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading fleet from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadVehicles)
                    : _vehicles.isEmpty
                        ? EmptyState(
                            icon: Icons.directions_car_outlined,
                            title: 'No Vehicles Found',
                            description: 'No vehicles match your status filter or search query.',
                            actionText: 'Add First Vehicle',
                            onAction: _showAddVehicleDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadVehicles,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _vehicles.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final v = _vehicles[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    v.makeModel,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.bgLight,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppTheme.border),
                                                    ),
                                                    child: Text(
                                                      v.registrationNumber,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.5,
                                                        color: AppTheme.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(status: v.status),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 12,
                                          runSpacing: 6,
                                          children: [
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.event_seat, size: 14, color: AppTheme.textMuted),
                                                    const SizedBox(width: 4),
                                                    Text('${v.capacity} Seats', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.local_gas_station, size: 14, color: AppTheme.textMuted),
                                                    const SizedBox(width: 4),
                                                    Text(v.fuelType, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                                  ],
                                                ),
                                                if (v.ac)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.ac_unit, size: 14, color: AppTheme.info),
                                                      const SizedBox(width: 4),
                                                      const Text('AC', style: TextStyle(fontSize: 12, color: AppTheme.info, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            Text(
                                              '${AppTheme.formatCurrency(v.perDayRate)}/day',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.accentDark,
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