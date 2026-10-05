class InvoiceModel {
  final int id;
  final String invoiceId;
  final String bookingCode;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String vehicleName;
  final String vehicleReg;
  final String route;
  final String issueDate;
  final String dueDate;
  final double baseFare;
  final double discount;
  final double taxableAmount;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;
  final String paymentStatus; // Unpaid, Paid, Overdue, Cancelled
  final String paymentMethod;
  final String notes;

  InvoiceModel({
    required this.id,
    required this.invoiceId,
    required this.bookingCode,
    required this.customerName,
    this.customerEmail = '',
    this.customerPhone = '',
    required this.vehicleName,
    required this.vehicleReg,
    this.route = '',
    required this.issueDate,
    required this.dueDate,
    required this.baseFare,
    this.discount = 0.0,
    required this.taxableAmount,
    this.taxRate = 0.05,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentStatus,
    this.paymentMethod = '',
    this.notes = '',
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceId: json['invoice_id'] ?? '',
      bookingCode: json['booking_code'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehicleReg: json['vehicle_reg'] ?? '',
      route: json['route'] ?? '',
      issueDate: json['issue_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      baseFare: json['base_fare'] != null ? double.tryParse(json['base_fare'].toString()) ?? 0.0 : 0.0,
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) ?? 0.0 : 0.0,
      taxableAmount: json['taxable_amount'] != null ? double.tryParse(json['taxable_amount'].toString()) ?? 0.0 : 0.0,
      taxRate: json['tax_rate'] != null ? double.tryParse(json['tax_rate'].toString()) ?? 0.05 : 0.05,
      taxAmount: json['tax_amount'] != null ? double.tryParse(json['tax_amount'].toString()) ?? 0.0 : 0.0,
      grandTotal: json['grand_total'] != null ? double.tryParse(json['grand_total'].toString()) ?? 0.0 : 0.0,
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      paymentMethod: json['payment_method'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
