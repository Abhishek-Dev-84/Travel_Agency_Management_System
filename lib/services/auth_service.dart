import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _api = ApiService();

  bool get isAuthenticated => _api.token != null && _api.token!.isNotEmpty;
  UserModel? get user => _api.currentUser;
  String get role => _api.currentUser?.role ?? 'CUSTOMER';

  Future<void> init() async {
    await _api.init();
    notifyListeners();
  }

  Future<UserModel> login(String email, String password, {String? role}) async {
    final res = await _api.login(email, password, role: role);
    final user = UserModel.fromJson(res['user']);
    notifyListeners();
    return user;
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String address = '',
  }) async {
    final res = await _api.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      address: address,
    );
    if (res['user'] != null) {
      final user = UserModel.fromJson(res['user']);
      notifyListeners();
      return user;
    }
    return null;
  }

  Future<void> logout() async {
    await _api.logout();
    notifyListeners();
  }

  Future<UserModel> refreshProfile() async {
    final u = await _api.getMe();
    notifyListeners();
    return u;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final u = await _api.updateProfile(data);
    notifyListeners();
    return u;
  }
}
