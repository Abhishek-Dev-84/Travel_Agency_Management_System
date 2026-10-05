class DriverModel {
  final int id;
  final String driverId;
  final String name;
  final String phone;
  final String email;
  final String licenseNumber;
  final String licenseExpiry;
  final int experienceYears;
  final String bloodGroup;
  final String address;
  final String status; // Available, On Duty, On Leave, Inactive
  final double rating;
  final bool isLicenseValid;
  final String licenseStatus; // Valid, Expiring Soon, Expired

  DriverModel({
    required this.id,
    required this.driverId,
    required this.name,
    required this.phone,
    this.email = '',
    required this.licenseNumber,
    required this.licenseExpiry,
    this.experienceYears = 1,
    this.bloodGroup = '',
    this.address = '',
    this.status = 'Available',
    this.rating = 5.0,
    this.isLicenseValid = true,
    this.licenseStatus = 'Valid',
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      driverId: json['driver_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseExpiry: json['license_expiry'] ?? '',
      experienceYears: json['experience_years'] is int
          ? json['experience_years']
          : int.tryParse(json['experience_years']?.toString() ?? '1') ?? 1,
      bloodGroup: json['blood_group'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'Available',
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 5.0 : 5.0,
      isLicenseValid: json['is_license_valid'] ?? true,
      licenseStatus: json['license_status'] ?? 'Valid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'license_number': licenseNumber,
      'license_expiry': licenseExpiry,
      'experience_years': experienceYears,
      'blood_group': bloodGroup,
      'address': address,
      'status': status,
    };
  }
}
