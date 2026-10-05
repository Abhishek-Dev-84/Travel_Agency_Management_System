import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../models/customer_model.dart';
import '../models/booking_model.dart';
import '../models/duty_slip_model.dart';
import '../models/invoice_model.dart';
import '../models/work_order_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _prefBaseUrlKey = 'tams_api_base_url';
  static const String _prefTokenKey = 'tams_auth_token';
  static const String _prefUserKey = 'tams_auth_user';

  String? _customBaseUrl;
  String? _authToken;
  UserModel? _currentUser;

  static const List<String> defaultCandidates = [
    'http://127.0.0.1:8000/api/v1', // USB adb reverse / Desktop / Web
    'http://10.106.1.72:8000/api/v1', // Wi-Fi LAN
    'http://10.0.2.2:8000/api/v1', // Android Emulator
  ];

  String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    // Default to 127.0.0.1:8000/api/v1
    // Works seamlessly with USB cable when "adb reverse tcp:8000 tcp:8000" is run,
    // as well as on desktop and web.
    return 'http://127.0.0.1:8000/api/v1';
  }

  set baseUrl(String url) {
    _customBaseUrl = url.trim();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefBaseUrlKey, _customBaseUrl!);
    });
  }

  Future<Map<String, dynamic>> testConnection([String? testUrl]) async {
    final url = (testUrl != null && testUrl.isNotEmpty) ? testUrl.trim() : baseUrl;
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final res = await http
          .get(Uri.parse('$cleanUrl/vehicles/'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode >= 200 && res.statusCode < 500) {
        return {
          'success': true,
          'message': 'Connected successfully (HTTP ${res.statusCode})',
          'statusCode': res.statusCode,
          'url': cleanUrl,
        };
      }
      return {
        'success': false,
        'message': 'Server responded with status HTTP ${res.statusCode}',
        'statusCode': res.statusCode,
        'url': cleanUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'url': cleanUrl,
      };
    }
  }

  Future<String?> autoDetectBaseUrl() async {
    for (final candidate in defaultCandidates) {
      final res = await testConnection(candidate);
      if (res['success'] == true) {
        baseUrl = candidate;
        return candidate;
      }
    }
    return null;
  }

  String? get token => _authToken;
  UserModel? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customBaseUrl = prefs.getString(_prefBaseUrlKey);
    _authToken = prefs.getString(_prefTokenKey);
    final userJson = prefs.getString(_prefUserKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    if (_customBaseUrl == null || _customBaseUrl!.isEmpty) {
      autoDetectBaseUrl().then((detected) {
        if (detected != null) {
          debugPrint('TAMS API Auto-detected backend at: $detected');
        }
      });
    }
  }

  Future<void> setAuthSession({required String token, required UserModel user}) async {
    _authToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, token);
    await prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
  }

  Future<void> clearAuthSession() async {
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefUserKey);
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract clean error message from Django / DRF
    String errorMessage = 'Server error (${response.statusCode})';
    if (body is Map) {
      if (body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      } else if (body.containsKey('error')) {
        errorMessage = body['error'].toString();
      } else {
        final List<String> parts = [];
        body.forEach((key, val) {
          final prefix = key == 'non_field_errors' ? '' : '$key: ';
          if (val is List) {
            parts.add('$prefix${val.join(", ")}');
          } else {
            parts.add('$prefix$val');
          }
        });
        if (parts.isNotEmpty) {
          errorMessage = parts.join('\n');
        }
      }
    } else if (body is String && body.isNotEmpty) {
      errorMessage = body;
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  // ================= AUTHENTICATION =================
  Future<Map<String, dynamic>> login(String email, String password, {String? role}) async {
    final url = Uri.parse('$baseUrl/auth/login/');
    final payload = {
      'email': email.trim(),
      'password': password,
    };
    if (role != null && role.isNotEmpty) {
      payload['role'] = role;
    }

    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(payload));
      final data = _processResponse(res);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);
      await setAuthSession(token: token, user: user);
      return data;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String address = '',
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    final payload = {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone.trim(),
      'address': address.trim(),
    };

    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(payload));
      final data = _processResponse(res);
      if (data['token'] != null && data['user'] != null) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user']);
        await setAuthSession(token: token, user: user);
      }
      return data;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    final url = Uri.parse('$baseUrl/auth/me/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final data = _processResponse(res);
      final user = UserModel.fromJson(data);
      _currentUser = user;
      return user;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> patchData) async {
    final url = Uri.parse('$baseUrl/auth/me/');
    try {
      final res = await http.patch(url, headers: _buildHeaders(), body: jsonEncode(patchData));
      final data = _processResponse(res);
      final user = UserModel.fromJson(data);
      _currentUser = user;
      return user;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout/');
      await http.post(url, headers: _buildHeaders());
    } catch (_) {}
    await clearAuthSession();
  }

  // ================= VEHICLES =================
  Future<List<VehicleModel>> getVehicles({String? status, String? search}) async {
    var uriString = '$baseUrl/vehicles/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => VehicleModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/vehicles/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return VehicleModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<VehicleModel> updateVehicle(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/vehicles/$id/');
    try {
      final res = await http.patch(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return VehicleModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<void> deleteVehicle(int id) async {
    final url = Uri.parse('$baseUrl/vehicles/$id/');
    try {
      final res = await http.delete(url, headers: _buildHeaders());
      if (res.statusCode >= 400) {
        _processResponse(res);
      }
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= DRIVERS =================
  Future<List<DriverModel>> getDrivers({String? status, String? licenseStatus, String? search}) async {
    var uriString = '$baseUrl/drivers/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (licenseStatus != null && licenseStatus != 'All') params['license_status'] = licenseStatus;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => DriverModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DriverModel> createDriver(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/drivers/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return DriverModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DriverModel> updateDriver(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/drivers/$id/');
    try {
      final res = await http.patch(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return DriverModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DriverModel> getDriverMyProfile() async {
    final url = Uri.parse('$baseUrl/drivers/my_profile/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final body = _processResponse(res);
      return DriverModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<void> updateDriverStatus(String status) async {
    final url = Uri.parse('$baseUrl/drivers/update_status/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode({'status': status}));
      _processResponse(res);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= CUSTOMERS =================
  Future<List<CustomerModel>> getCustomers({String? search}) async {
    var uriString = '$baseUrl/customers/';
    if (search != null && search.isNotEmpty) {
      uriString += '?search=${Uri.encodeComponent(search)}';
    }
    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => CustomerModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/customers/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return CustomerModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= BOOKINGS =================
  Future<List<BookingModel>> getBookings({String? status, String? search}) async {
    var uriString = '$baseUrl/bookings/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => BookingModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    final url = Uri.parse('$baseUrl/bookings/my_bookings/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => BookingModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/bookings/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return BookingModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<BookingModel> cancelBooking(int id) async {
    final url = Uri.parse('$baseUrl/bookings/$id/cancel/');
    try {
      final res = await http.post(url, headers: _buildHeaders());
      final body = _processResponse(res);
      if (body['booking'] != null) {
        return BookingModel.fromJson(body['booking']);
      }
      return BookingModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<BookingModel> acceptBooking(
    int id, {
    int? driverId,
    String? time,
    double? payout,
    String? remarks,
  }) async {
    final url = Uri.parse('$baseUrl/bookings/$id/accept/');
    final payload = <String, dynamic>{};
    if (driverId != null) payload['driver_id'] = driverId;
    if (time != null && time.isNotEmpty) payload['time'] = time;
    if (payout != null) payload['payout'] = payout;
    if (remarks != null && remarks.isNotEmpty) payload['remarks'] = remarks;

    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      );
      final body = _processResponse(res);
      if (body['booking'] != null) {
        return BookingModel.fromJson(body['booking']);
      }
      return BookingModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<BookingModel> updateBookingStatus(int id, String status) async {
    final url = Uri.parse('$baseUrl/bookings/$id/');
    try {
      final res = await http.patch(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({'status': status}),
      );
      final body = _processResponse(res);
      return BookingModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= DUTY SLIPS / ASSIGNMENTS =================
  Future<List<DutySlipModel>> getDutySlips({String? status, String? search}) async {
    var uriString = '$baseUrl/duty-slips/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => DutySlipModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<List<DutySlipModel>> getMyDutySlips() async {
    final url = Uri.parse('$baseUrl/duty-slips/my_slips/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => DutySlipModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DutySlipModel> createDutySlip(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/duty-slips/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return DutySlipModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DutySlipModel> startTrip(int slipId, int startOdometer) async {
    final url = Uri.parse('$baseUrl/duty-slips/$slipId/start_trip/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({'start_odometer': startOdometer}),
      );
      final body = _processResponse(res);
      if (body['duty_slip'] != null) {
        return DutySlipModel.fromJson(body['duty_slip']);
      }
      return DutySlipModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<DutySlipModel> completeTrip(int slipId, int endOdometer) async {
    final url = Uri.parse('$baseUrl/duty-slips/$slipId/complete_trip/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({'end_odometer': endOdometer}),
      );
      final body = _processResponse(res);
      if (body['duty_slip'] != null) {
        return DutySlipModel.fromJson(body['duty_slip']);
      }
      return DutySlipModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= INVOICES / BILLING =================
  Future<List<InvoiceModel>> getInvoices({String? status, String? search}) async {
    var uriString = '$baseUrl/invoices/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => InvoiceModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<List<InvoiceModel>> getMyInvoices() async {
    final url = Uri.parse('$baseUrl/invoices/my_invoices/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => InvoiceModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<InvoiceModel> markInvoicePaid(int id, {String method = 'Cash'}) async {
    final url = Uri.parse('$baseUrl/invoices/$id/mark_paid/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({'payment_method': method}),
      );
      final body = _processResponse(res);
      if (body['invoice'] != null) {
        return InvoiceModel.fromJson(body['invoice']);
      }
      return InvoiceModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= SIMULATED PAYMENTS =================
  Future<Map<String, dynamic>> initiatePayment({
    required dynamic invoiceId,
    String paymentMethod = 'UPI',
  }) async {
    final url = Uri.parse('$baseUrl/payments/initiate/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({
          'invoice_id': invoiceId.toString(),
          'payment_method': paymentMethod,
        }),
      );
      final body = _processResponse(res);
      return body;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String transactionRef,
    String? paymentId,
  }) async {
    final url = Uri.parse('$baseUrl/payments/confirm/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({
          'transaction_ref': transactionRef,
          'payment_id': paymentId,
        }),
      );
      final body = _processResponse(res);
      return body;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelPayment({
    required String transactionRef,
    String? paymentId,
  }) async {
    final url = Uri.parse('$baseUrl/payments/cancel/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({
          'transaction_ref': transactionRef,
          'payment_id': paymentId,
        }),
      );
      final body = _processResponse(res);
      return body;
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= MAINTENANCE =================
  Future<List<WorkOrderModel>> getWorkOrders({String? status, String? search}) async {
    var uriString = '$baseUrl/maintenance/';
    final params = <String, String>{};
    if (status != null && status != 'All') params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      uriString += '?${Uri(queryParameters: params).query}';
    }

    try {
      final res = await http.get(Uri.parse(uriString), headers: _buildHeaders());
      final data = _processResponse(res);
      if (data is List) {
        return data.map((item) => WorkOrderModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<WorkOrderModel> createWorkOrder(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/maintenance/');
    try {
      final res = await http.post(url, headers: _buildHeaders(), body: jsonEncode(data));
      final body = _processResponse(res);
      return WorkOrderModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<WorkOrderModel> startService(int id) async {
    final url = Uri.parse('$baseUrl/maintenance/$id/start_service/');
    try {
      final res = await http.post(url, headers: _buildHeaders());
      final body = _processResponse(res);
      if (body['work_order'] != null) {
        return WorkOrderModel.fromJson(body['work_order']);
      }
      return WorkOrderModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<WorkOrderModel> completeService(int id, double actualCost) async {
    final url = Uri.parse('$baseUrl/maintenance/$id/complete_service/');
    try {
      final res = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({'actual_cost': actualCost}),
      );
      final body = _processResponse(res);
      if (body['work_order'] != null) {
        return WorkOrderModel.fromJson(body['work_order']);
      }
      return WorkOrderModel.fromJson(body);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  // ================= DASHBOARD & REPORTS =================
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final url = Uri.parse('$baseUrl/dashboard/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      return _processResponse(res);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final url = Uri.parse('$baseUrl/reports/analytics/');
    try {
      final res = await http.get(url, headers: _buildHeaders());
      return _processResponse(res);
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  void _handleNetworkError(dynamic error) {
    if (error is ApiException) return;
    final msg = error.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection timed out') ||
        msg.contains('ClientException')) {
      throw ApiException(
        'Unable to connect to TAMS backend ($baseUrl).\n\n'
        '• If connected via USB: Run "adb reverse tcp:8000 tcp:8000" and use http://127.0.0.1:8000/api/v1\n'
        '• If connected via Wi-Fi: Ensure phone & PC are on same Wi-Fi, run Django with "py manage.py runserver 0.0.0.0:8000", and use http://10.106.1.72:8000/api/v1\n'
        '• If using Emulator: Use http://10.0.2.2:8000/api/v1',
        statusCode: 0,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}
