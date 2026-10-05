import 'customer_model.dart';

class BookingModel {
  final int id;
  final String bookingId;
  final CustomerModel? customer;
  final int? vehicleId;
  final String vehicleName;
  final String vehicleRegistration;
  final String vehicleType;
  final String pickupLocation;
  final String destinationLocation;
  final String pickupDate;
  final String returnDate;
  final int passengers;
  final String notes;
  final double baseFare;
  final String status; // Pending, Confirmed, Completed, Cancelled
  final int durationDays;
  final String? createdAt;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final int? assignedDriverId;
  final String? dutySlipId;

  BookingModel({
    required this.id,
    required this.bookingId,
    this.customer,
    this.vehicleId,
    required this.vehicleName,
    this.vehicleRegistration = '',
    this.vehicleType = 'Sedan',
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupDate,
    required this.returnDate,
    this.passengers = 1,
    this.notes = '',
    required this.baseFare,
    required this.status,
    this.durationDays = 1,
    this.createdAt,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.assignedDriverId,
    this.dutySlipId,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    CustomerModel? cust;
    if (json['customer'] != null && json['customer'] is Map<String, dynamic>) {
      cust = CustomerModel.fromJson(json['customer']);
    }

    String vName = 'Vehicle';
    String vReg = '';
    String vType = 'Sedan';
    int? vId;

    if (json['vehicle_details'] != null && json['vehicle_details'] is Map<String, dynamic>) {
      final vd = json['vehicle_details'];
      vName = vd['make_model'] ?? 'Vehicle';
      vReg = vd['registration_number'] ?? '';
      vType = vd['vehicle_type'] ?? 'Sedan';
      vId = vd['id'] is int ? vd['id'] : int.tryParse(vd['id']?.toString() ?? '');
    } else if (json['vehicle'] != null) {
      if (json['vehicle'] is Map<String, dynamic>) {
        vName = json['vehicle']['make_model'] ?? 'Vehicle';
        vReg = json['vehicle']['registration_number'] ?? '';
        vType = json['vehicle']['vehicle_type'] ?? 'Sedan';
        vId = json['vehicle']['id'];
      } else if (json['vehicle'] is int) {
        vId = json['vehicle'];
      }
    }

    String? driverName;
    String? driverPhone;
    int? driverId;
    String? slipId;

    if (json['assigned_driver'] != null && json['assigned_driver'] is Map<String, dynamic>) {
      driverName = json['assigned_driver']['name'];
      driverPhone = json['assigned_driver']['phone'];
      driverId = json['assigned_driver']['id'] is int
          ? json['assigned_driver']['id']
          : int.tryParse(json['assigned_driver']['id']?.toString() ?? '');
    }
    if (json['duty_slip'] != null && json['duty_slip'] is Map<String, dynamic>) {
      slipId = json['duty_slip']['slip_id'];
    }

    return BookingModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      bookingId: json['booking_id'] ?? '',
      customer: cust,
      vehicleId: vId,
      vehicleName: vName,
      vehicleRegistration: vReg,
      vehicleType: vType,
      pickupLocation: json['pickup_location'] ?? '',
      destinationLocation: json['destination_location'] ?? '',
      pickupDate: json['pickup_date'] ?? '',
      returnDate: json['return_date'] ?? '',
      passengers: json['passengers'] is int ? json['passengers'] : int.tryParse(json['passengers']?.toString() ?? '1') ?? 1,
      notes: json['notes'] ?? '',
      baseFare: json['base_fare'] != null ? double.tryParse(json['base_fare'].toString()) ?? 0.0 : 0.0,
      status: json['status'] ?? 'Pending',
      durationDays: json['duration_days'] is int ? json['duration_days'] : int.tryParse(json['duration_days']?.toString() ?? '1') ?? 1,
      createdAt: json['created_at'],
      assignedDriverName: driverName,
      assignedDriverPhone: driverPhone,
      assignedDriverId: driverId,
      dutySlipId: slipId,
    );
  }
}
