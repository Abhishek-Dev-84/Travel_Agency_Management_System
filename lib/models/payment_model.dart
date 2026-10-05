class PaymentModel {
  final int id;
  final String paymentId;
  final int? invoiceId;
  final String invoiceCode;
  final String customerName;
  final double amount;
  final String paymentMethod; // UPI, CREDIT_CARD, DEBIT_CARD, CASH
  final String paymentStatus; // PENDING, PAID, FAILED, CANCELLED
  final String transactionRef;
  final String qrPayload;
  final bool isDemo;
  final String? paidAt;
  final String notes;

  PaymentModel({
    required this.id,
    required this.paymentId,
    this.invoiceId,
    required this.invoiceCode,
    this.customerName = '',
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionRef,
    this.qrPayload = '',
    this.isDemo = true,
    this.paidAt,
    this.notes = '',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      paymentId: json['payment_id'] ?? '',
      invoiceId: json['invoice'] is int ? json['invoice'] : int.tryParse(json['invoice']?.toString() ?? ''),
      invoiceCode: json['invoice_code'] ?? '',
      customerName: json['customer_name'] ?? '',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      paymentMethod: json['payment_method'] ?? 'UPI',
      paymentStatus: (json['payment_status'] ?? 'PENDING').toString().toUpperCase(),
      transactionRef: json['transaction_ref'] ?? '',
      qrPayload: json['qr_payload'] ?? '',
      isDemo: json['is_demo'] ?? true,
      paidAt: json['paid_at'],
      notes: json['notes'] ?? '',
    );
  }
}
