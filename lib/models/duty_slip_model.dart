class DutySlipModel {
  final int id;
  final String slipId;
  final String bookingCode;
  final String driverName;
  final String driverPhone;
  final String driverCode;
  final String vehicleName;
  final String vehicleReg;
  final String date;
  final String time;
  final String pickup;
  final String destination;
  final String customerName;
  final String customerPhone;
  final int? startOdometer;
  final int? endOdometer;
  final String fuelLevel;
  final String remarks;
  final double payout;
  final String status; // Upcoming, In Progress, Completed, Cancelled
  final String? createdAt;

  DutySlipModel({
    required this.id,
    required this.slipId,
    required this.bookingCode,
    required this.driverName,
    this.driverPhone = '',
    this.driverCode = '',
    required this.vehicleName,
    required this.vehicleReg,
    required this.date,
    this.time = '08:00',
    required this.pickup,
    required this.destination,
    this.customerName = '',
    this.customerPhone = '',
    this.startOdometer,
    this.endOdometer,
    this.fuelLevel = 'Full',
    this.remarks = '',
    this.payout = 0.0,
    required this.status,
    this.createdAt,
  });

  factory DutySlipModel.fromJson(Map<String, dynamic> json) {
    return DutySlipModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      slipId: json['slip_id'] ?? '',
      bookingCode: json['booking_code'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'] ?? '',
      driverCode: json['driver_code'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehicleReg: json['vehicle_reg'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '08:00',
      pickup: json['pickup'] ?? '',
      destination: json['destination'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      startOdometer: json['start_odometer'] != null ? int.tryParse(json['start_odometer'].toString()) : null,
      endOdometer: json['end_odometer'] != null ? int.tryParse(json['end_odometer'].toString()) : null,
      fuelLevel: json['fuel_level'] ?? 'Full',
      remarks: json['remarks'] ?? '',
      payout: json['payout'] != null ? double.tryParse(json['payout'].toString()) ?? 0.0 : 0.0,
      status: json['status'] ?? 'Upcoming',
      createdAt: json['created_at'],
    );
  }
}
