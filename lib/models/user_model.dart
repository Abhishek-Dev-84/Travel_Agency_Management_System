class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role; // ADMIN, STAFF, DRIVER, CUSTOMER
  final String phone;
  final String address;
  final String bloodGroup;
  final String identityType;
  final String identityNumber;
  final bool isActive;
  final String? dateJoined;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.address = '',
    this.bloodGroup = '',
    this.identityType = '',
    this.identityNumber = '',
    this.isActive = true,
    this.dateJoined,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? (json['name'] ?? json['username'] ?? ''),
      role: (json['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      identityType: json['identity_type'] ?? '',
      identityNumber: json['identity_number'] ?? '',
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'address': address,
      'blood_group': bloodGroup,
      'identity_type': identityType,
      'identity_number': identityNumber,
      'is_active': isActive,
      'date_joined': dateJoined,
    };
  }
}
