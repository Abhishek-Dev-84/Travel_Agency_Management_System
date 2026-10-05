import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/tams_app_bar.dart';

class DemoPaymentPage extends StatefulWidget {
  final InvoiceModel invoice;

  const DemoPaymentPage({super.key, required this.invoice});

  @override
  State<DemoPaymentPage> createState() => _DemoPaymentPageState();
}

class _DemoPaymentPageState extends State<DemoPaymentPage> {
  final ApiService _api = ApiService();

  String _paymentMethod = 'UPI'; // UPI, CREDIT_CARD, DEBIT_CARD, CASH
  bool _isInitiating = false;
  bool _isConfirming = false;
  bool _isCancelling = false;

  Map<String, dynamic>? _paymentSession;
  String? _errorMessage;
  bool _paymentSuccess = false;

  Future<void> _initiatePayment() async {
    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.initiatePayment(
        invoiceId: widget.invoice.id,
        paymentMethod: _paymentMethod,
      );
      if (mounted) {
        setState(() {
          _paymentSession = res['payment'];
          _isInitiating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isInitiating = false;
        });
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_paymentSession == null) return;
    final txnRef = _paymentSession!['transaction_ref'] as String;

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      await _api.confirmPayment(transactionRef: txnRef);
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _paymentSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _cancelPayment() async {
    if (_paymentSession == null) return;
    final txnRef = _paymentSession!['transaction_ref'] as String;

    setState(() {
      _isCancelling = true;
      _errorMessage = null;
    });

    try {
      await _api.cancelPayment(transactionRef: txnRef);
      if (mounted) {
        setState(() {
          _isCancelling = false;
          _paymentSession = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo payment session cancelled. Invoice remains unpaid.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Demo Simulated Payment',
        showRoleBadge: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner: SIMULATED PAYMENT
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_outlined, color: AppTheme.warning, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIMULATED PAYMENT MODE',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.warning,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This is a demonstration payment environment for academic and evaluation purposes. No real bank transaction will occur.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_paymentSuccess) ...[
              _buildSuccessState(),
            ] else if (_paymentSession != null) ...[
              _buildSessionState(),
            ] else ...[
              _buildInitiationForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitiationForm() {
    final inv = widget.invoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        inv.invoiceId,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Booking: ${inv.bookingCode}',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),

                _infoRow('Customer', inv.customerName),
                _infoRow('Vehicle', '${inv.vehicleName} (${inv.vehicleReg})'),
                if (inv.route.isNotEmpty) _infoRow('Route', inv.route),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 8),

                _infoRow('Base Fare', AppTheme.formatCurrency(inv.baseFare)),
                if (inv.discount > 0) _infoRow('Discount', '- ${AppTheme.formatCurrency(inv.discount)}'),
                _infoRow('GST (5%)', AppTheme.formatCurrency(inv.taxAmount)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payable Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    Text(
                      AppTheme.formatCurrency(inv.grandTotal),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.accentDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Method Selection
        const Text(
          'SELECT PAYMENT METHOD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        _methodTile('UPI', 'Instant UPI / QR Code simulation', Icons.qr_code),
        const SizedBox(height: 8),
        _methodTile('CREDIT_CARD', 'Credit Card simulation', Icons.credit_card),
        const SizedBox(height: 8),
        _methodTile('DEBIT_CARD', 'Debit Card simulation', Icons.credit_card_outlined),
        const SizedBox(height: 8),
        _methodTile('CASH', 'Cash on Duty simulation', Icons.payments_outlined),

        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
        ],

        const SizedBox(height: 24),
        CustomButton(
          text: 'Initiate Demo Payment (₹${inv.grandTotal.toStringAsFixed(2)})',
          isLoading: _isInitiating,
          onPressed: _initiatePayment,
        ),
      ],
    );
  }

  Widget _methodTile(String value, String subtitle, IconData icon) {
    final isSel = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? AppTheme.accent : AppTheme.border, width: isSel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSel ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSel ? AppTheme.accentDark : AppTheme.textDark,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(
              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSel ? AppTheme.accent : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionState() {
    final session = _paymentSession!;
    final txnRef = session['transaction_ref'] ?? '';
    final amount = session['amount'] ?? widget.invoice.grandTotal;
    final qrPayload = session['qr_payload'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'TAMS SIMULATED GATEWAY',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transaction Reference: $txnRef',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),

                // Simulated QR Code Frame
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2, size: 100, color: AppTheme.primary),
                      const SizedBox(height: 6),
                      Text(
                        'DEMO QR CODE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accentDark),
                      ),
                      Text(
                        AppTheme.formatCurrency(amount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Text payload representation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    qrPayload.isNotEmpty
                        ? qrPayload
                        : "TAMS DEMO PAYMENT\nRef: $txnRef\nAmount: ₹$amount\nStatus: SIMULATED DEMO ONLY",
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textDark, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to Pay:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      AppTheme.formatCurrency(amount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.accentDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          const SizedBox(height: 12),
        ],

        CustomButton(
          text: 'Confirm Demo Payment (Complete)',
          icon: Icons.check_circle_outline,
          color: AppTheme.success,
          isLoading: _isConfirming,
          onPressed: _confirmPayment,
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Cancel / Abort Transaction',
          icon: Icons.close,
          color: AppTheme.danger,
          isOutlined: true,
          isLoading: _isCancelling,
          onPressed: _cancelPayment,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Demo Payment Completed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Invoice ${widget.invoice.invoiceId} is now verified and marked as PAID in PostgreSQL.',
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Done & Return',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
