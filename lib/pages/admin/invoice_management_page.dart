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
import '../customer/demo_payment_page.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({super.key});

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Unpaid', 'Paid', 'Overdue', 'Cancelled'];

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
      final list = await _api.getInvoices(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        search: _searchCtrl.text,
      );
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

  void _markPaidCash(InvoiceModel inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark ${inv.invoiceId} as Paid?'),
        content: Text('Confirm receipt of ${AppTheme.formatCurrency(inv.grandTotal)} in cash?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cash Receipt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.markInvoicePaid(inv.id, method: 'Cash');
      _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${inv.invoiceId} marked as PAID')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Billing & Invoices',
        onRefresh: _loadInvoices,
      ),
      drawer: const TamsDrawer(currentRoute: 'Billing & Invoices'),
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
                  onSubmitted: (_) => _loadInvoices(),
                  decoration: InputDecoration(
                    hintText: 'Search by invoice ID, customer or booking...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadInvoices();
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
                              _loadInvoices();
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

          // Invoices List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading invoices from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadInvoices)
                    : _invoices.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Invoices Found',
                            description: 'No billing records match your filter or search query.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadInvoices,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _invoices.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final inv = _invoices[index];
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
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      inv.invoiceId,
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
                                                      'Booking: ${inv.bookingCode}',
                                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: inv.paymentStatus),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_outline, size: 15, color: AppTheme.accent),
                                                const SizedBox(width: 6),
                                                Text(
                                                  inv.customerName,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.directions_car, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${inv.vehicleName} (${inv.vehicleReg})',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (inv.route.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.route, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
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
                                              child: Text(
                                                'Base: ${AppTheme.formatCurrency(inv.baseFare)} + 5% GST (${AppTheme.formatCurrency(inv.taxAmount)})',
                                                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                AppTheme.formatCurrency(inv.grandTotal),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.accentDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (!isPaid && inv.paymentStatus != 'Cancelled') ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomButton(
                                                  text: 'Mark Paid (Cash)',
                                                  height: 36,
                                                  color: AppTheme.success,
                                                  onPressed: () => _markPaidCash(inv),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: CustomButton(
                                                  text: 'Demo Pay (QR/Card)',
                                                  height: 36,
                                                  color: AppTheme.primary,
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