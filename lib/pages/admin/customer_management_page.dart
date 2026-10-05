import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/tams_app_bar.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getCustomers(search: _searchCtrl.text);
      if (mounted) {
        setState(() {
          _customers = list;
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

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final idNumCtrl = TextEditingController();
    String idType = 'Driving Licence';
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
                        'Add New Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
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
                    label: 'Full Name *',
                    hint: 'e.g. Ramesh Chandra',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number *',
                    hint: '10-digit mobile number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    hint: 'customer@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: addressCtrl,
                    label: 'Address',
                    hint: 'City, State',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Identity Proof',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: idType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppTheme.textMuted),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Driving Licence', child: Text('Driving Licence')),
                      DropdownMenuItem(value: 'Aadhaar Card', child: Text('Aadhaar Card')),
                      DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                      DropdownMenuItem(value: 'Voter ID', child: Text('Voter ID')),
                    ],
                    onChanged: (v) => setModalState(() => idType = v!),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: idNumCtrl,
                    label: 'ID Number',
                    hint: 'e.g. DL-XXXXX or 1234-5678-9012',
                    prefixIcon: Icons.pin_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Create Customer',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);
                      try {
                        await _api.createCustomer({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'identity_type': idType,
                          'identity_number': idNumCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadCustomers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer registered successfully')),
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
        title: 'Customer Directory',
        onRefresh: _loadCustomers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: _showAddCustomerDialog,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadCustomers(),
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadCustomers();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Customer List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading customers...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadCustomers)
                    : _customers.isEmpty
                        ? EmptyState(
                            icon: Icons.people_outline,
                            title: 'No Customers Found',
                            description: 'No registered customer profiles match your search criteria.',
                            actionText: 'Add Customer',
                            onAction: _showAddCustomerDialog,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCustomers,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _customers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final c = _customers[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
                                              child: Text(
                                                c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.name,
                                                    style: const TextStyle(
                                                      fontSize: 15.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.textDark,
                                                    ),
                                                  ),
                                                  if (c.email.isNotEmpty)
                                                    Text(
                                                      c.email,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: AppTheme.textMuted,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.infoSoft,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${c.bookingsCount} Bookings',
                                                style: const TextStyle(
                                                  color: AppTheme.info,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(color: AppTheme.border, height: 1),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 6),
                                                Text(
                                                  c.phone.isNotEmpty ? c.phone : 'No phone',
                                                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                                ),
                                              ],
                                            ),
                                            if (c.identityType.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.badge, size: 14, color: AppTheme.textMuted),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${c.identityType}: ${c.identityNumber.isNotEmpty ? c.identityNumber : "Recorded"}',
                                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        if (c.address.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  c.address,
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
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
