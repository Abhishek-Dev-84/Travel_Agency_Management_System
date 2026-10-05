class CustomerModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String identityType;
  final String identityNumber;
  final int bookingsCount;
  final String? createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    this.address = '',
    this.identityType = 'Driving Licence',
    this.identityNumber = '',
    this.bookingsCount = 0,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      identityType: json['identity_type'] ?? 'Driving Licence',
      identityNumber: json['identity_number'] ?? '',
      bookingsCount: json['bookings_count'] is int
          ? json['bookings_count']
          : int.tryParse(json['bookings_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_type': identityType,
      'identity_number': identityNumber,
    };
  }
}
