import 'package:flutter/material.dart';
import '../../models/work_order_model.dart';
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

class MaintenanceLogPage extends StatefulWidget {
  const MaintenanceLogPage({super.key});

  @override
  State<MaintenanceLogPage> createState() => _MaintenanceLogPageState();
}

class _MaintenanceLogPageState extends State<MaintenanceLogPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<WorkOrderModel> _workOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Scheduled', 'In Service', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getWorkOrders(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _workOrders = list;
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

  void _showStartServiceDialog(WorkOrderModel wo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start Service for ${wo.vehicleName}?'),
        content: Text('Starting this work order will automatically set the vehicle status to "Maintenance" and prevent bookings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Service'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.startService(wo.id);
      _loadWorkOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Work Order ${wo.workOrderId} started. Vehicle locked to Maintenance.')),
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

  void _showCompleteServiceDialog(WorkOrderModel wo) {
    final costCtrl = TextEditingController(text: wo.estimatedCost > 0 ? wo.estimatedCost.toString() : '2500');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Complete Service: ${wo.workOrderId}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle: ${wo.vehicleName} (${wo.vehicleReg})\nService: ${wo.serviceType}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: costCtrl,
                  label: 'Actual Cost (₹) *',
                  hint: 'e.g. 2500',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid cost' : null,
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
                        await _api.completeService(wo.id, double.parse(costCtrl.text.trim()));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadWorkOrders();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Service completed! Vehicle restored to "Available".')),
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
              child: const Text('Complete & Release Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkOrderDialog() async {
    List<VehicleModel> vehicles = [];
    try {
      vehicles = await _api.getVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
      return;
    }

    if (!mounted) return;

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles available in fleet.')),
      );
      return;
    }

    int? selectedVehicleId = vehicles.first.id;
    final serviceTypeCtrl = TextEditingController(text: 'Routine Maintenance');
    final issueDescCtrl = TextEditingController(text: 'Periodic engine oil and filter change');
    final garageCtrl = TextEditingController(text: 'Apex Auto Care, Bhubaneswar');
    final estCostCtrl = TextEditingController(text: '3500');
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    String priority = 'Normal';

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
                        'New Service Work Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 10),

                  // Vehicle dropdown
                  const Text('Select Vehicle *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedVehicleId,
                    items: vehicles.map((v) {
                      return DropdownMenuItem<int>(
                        value: v.id,
                        child: Text('${v.makeModel} (${v.registrationNumber})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => selectedVehicleId = v),
                    validator: (v) => v == null ? 'Vehicle required' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: serviceTypeCtrl,
                    label: 'Service Type *',
                    hint: 'e.g. Brake Overhaul, Oil Change',
                    prefixIcon: Icons.build_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Service type required' : null,
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: issueDescCtrl,
                    label: 'Issue Description *',
                    hint: 'Details of service or repair needed',
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Description required' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: priority,
                              items: const [
                                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                                DropdownMenuItem(value: 'High', child: Text('High')),
                                DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                              ],
                              onChanged: (v) => setModalState(() => priority = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: estCostCtrl,
                          label: 'Estimated Cost (₹)',
                          hint: '3500',
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: garageCtrl,
                    label: 'Garage / Service Center',
                    hint: 'Authorized Service Center',
                    prefixIcon: Icons.store_outlined,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Schedule Work Order',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);
                      try {
                        await _api.createWorkOrder({
                          'vehicle_id': selectedVehicleId,
                          'service_type': serviceTypeCtrl.text.trim(),
                          'issue_description': issueDescCtrl.text.trim(),
                          'priority': priority,
                          'garage_name': garageCtrl.text.trim(),
                          'estimated_cost': double.tryParse(estCostCtrl.text.trim()) ?? 0.0,
                          'scheduled_date': dateCtrl.text.trim(),
                          'status': 'Scheduled',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadWorkOrders();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service work order scheduled in PostgreSQL')),
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
        title: 'Fleet Maintenance',
        onRefresh: _loadWorkOrders,
      ),
      drawer: const TamsDrawer(currentRoute: 'Maintenance'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Service', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showAddWorkOrderDialog,
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
                  onSubmitted: (_) => _loadWorkOrders(),
                  decoration: InputDecoration(
                    hintText: 'Search work orders by ID, vehicle or type...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadWorkOrders();
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
                              _loadWorkOrders();
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

          // Work Order List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading maintenance orders from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadWorkOrders)
                    : _workOrders.isEmpty
                        ? EmptyState(
                            icon: Icons.build_outlined,
                            title: 'No Work Orders Found',
                            description: 'No maintenance logs match your filter or search query.',
                            actionText: 'Schedule Service',
                            onAction: _showAddWorkOrderDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadWorkOrders,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _workOrders.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final wo = _workOrders[index];

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
                                                      wo.workOrderId,
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
                                                      'Priority: ${wo.priority}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: wo.priority == 'Urgent'
                                                            ? AppTheme.danger
                                                            : (wo.priority == 'High' ? AppTheme.warning : AppTheme.textMuted),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: wo.status),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.directions_car, size: 16, color: AppTheme.accent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${wo.vehicleName} (${wo.vehicleReg})',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${wo.serviceType}: ${wo.issueDescription}',
                                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
                                        ),
                                        if (wo.garageName.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Garage: ${wo.garageName}',
                                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),

                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              'Scheduled: ${wo.scheduledDate}',
                                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                            ),
                                            Text(
                                              wo.actualCost > 0
                                                  ? 'Cost: ${AppTheme.formatCurrency(wo.actualCost)}'
                                                  : 'Est: ${AppTheme.formatCurrency(wo.estimatedCost)}',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (wo.status == 'Scheduled' || wo.status == 'In Service') ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            alignment: WrapAlignment.end,
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              if (wo.status == 'Scheduled')
                                                CustomButton(
                                                  text: 'Start Service',
                                                  icon: Icons.play_arrow,
                                                  color: AppTheme.danger,
                                                  height: 36,
                                                  width: 140,
                                                  onPressed: () => _showStartServiceDialog(wo),
                                                ),
                                              if (wo.status == 'In Service')
                                                CustomButton(
                                                  text: 'Complete Service',
                                                  icon: Icons.check,
                                                  color: AppTheme.success,
                                                  height: 36,
                                                  width: 160,
                                                  onPressed: () => _showCompleteServiceDialog(wo),
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