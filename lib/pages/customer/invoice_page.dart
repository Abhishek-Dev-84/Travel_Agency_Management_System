import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';
import 'demo_payment_page.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final ApiService _api = ApiService();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Unpaid', 'Paid'];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getMyInvoices();
      if (mounted) {
        setState(() {
          _invoices = list;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedStatus == 'All'
        ? _invoices
        : _invoices.where((i) => i.paymentStatus.toLowerCase() == _selectedStatus.toLowerCase()).toList();

    return Scaffold(
      appBar: TamsAppBar(
        title: 'My Invoices & Payments',
        onRefresh: _loadInvoices,
      ),
      drawer: const TamsDrawer(currentRoute: 'Invoices & Payments'),
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
                ? const LoadingIndicator(message: 'Retrieving invoices from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadInvoices)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Invoices Found',
                            description: 'No billing statements match this filter.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadInvoices,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final inv = filtered[index];
                                final isPaid = inv.paymentStatus == 'Paid';

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
                                              child: Text(
                                                inv.invoiceId,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: inv.paymentStatus),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Linked to Booking: ${inv.bookingCode}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.directions_car, size: 15, color: AppTheme.accent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${inv.vehicleName} (${inv.vehicleReg})',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (inv.route.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.route, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  inv.route,
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),

                                        // Financial breakdown (5% GST calculation)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Base: ${AppTheme.formatCurrency(inv.baseFare)} + 5% GST (${AppTheme.formatCurrency(inv.taxAmount)})',
                                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'Issued: ${inv.issueDate} · Due: ${inv.dueDate}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                AppTheme.formatCurrency(inv.grandTotal),
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.accentDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (!isPaid && inv.paymentStatus != 'Cancelled') ...[
                                          const SizedBox(height: 12),
                                          CustomButton(
                                            text: 'Pay Now (Demo Simulation)',
                                            icon: Icons.payment,
                                            height: 38,
                                            onPressed: () async {
                                              final res = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => DemoPaymentPage(invoice: inv)),
                                              );
                                              if (res == true) {
                                                _loadInvoices();
                                              }
                                            },
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