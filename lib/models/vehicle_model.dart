class VehicleModel {
  final int id;
  final String makeModel;
  final String registrationNumber;
  final String vehicleType;
  final int capacity;
  final String fuelType;
  final String transmission;
  final bool ac;
  final String luggageCapacity;
  final double perDayRate;
  final String status; // Available, On Trip, Maintenance, Unavailable
  final String insuranceInfo;
  final String permitInfo;
  final String description;
  final String? createdAt;

  VehicleModel({
    required this.id,
    required this.makeModel,
    required this.registrationNumber,
    required this.vehicleType,
    required this.capacity,
    required this.fuelType,
    this.transmission = 'Manual',
    this.ac = true,
    this.luggageCapacity = '3 bags',
    required this.perDayRate,
    required this.status,
    this.insuranceInfo = '',
    this.permitInfo = '',
    this.description = '',
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      makeModel: json['make_model'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'Sedan',
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? '4') ?? 4,
      fuelType: json['fuel_type'] ?? 'Petrol',
      transmission: json['transmission'] ?? 'Manual',
      ac: json['ac'] is bool ? json['ac'] : (json['ac'] == null ? true : json['ac'].toString() == 'true'),
      luggageCapacity: json['luggage_capacity'] ?? '3 bags',
      perDayRate: json['per_day_rate'] != null
          ? double.tryParse(json['per_day_rate'].toString()) ?? 2000.0
          : 2000.0,
      status: json['status'] ?? 'Available',
      insuranceInfo: json['insurance_info'] ?? '',
      permitInfo: json['permit_info'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make_model': makeModel,
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType,
      'capacity': capacity,
      'fuel_type': fuelType,
      'transmission': transmission,
      'ac': ac,
      'luggage_capacity': luggageCapacity,
      'per_day_rate': perDayRate.toStringAsFixed(2),
      'status': status,
      'insurance_info': insuranceInfo,
      'permit_info': permitInfo,
      'description': description,
    };
  }
}
