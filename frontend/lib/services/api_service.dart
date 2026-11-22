import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../models/donation.dart';
import '../models/expense.dart';
import '../models/cash_transaction.dart';
import '../models/donation_confirmation.dart';
import '../models/report.dart';
import '../models/mosque_info.dart';

class ApiService {
  String? _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==========================================
  // AUTH (FR-01 - FR-05)
  // ==========================================
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      _authToken = data['data']['token'];
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Pendaftaran gagal.');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _authToken = data['data']['token'];
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Gagal masuk.');
  }

  Future<User?> getMe() async {
    if (_authToken == null) return null;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']);
    }
    return null;
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => User.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat pengguna.');
  }

  Future<void> createUser(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal membuat pengguna.');
    }
  }

  Future<void> toggleUserActive(int userId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId/toggle-active'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengubah status pengguna.');
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId/reset-password'),
      headers: _headers(),
      body: jsonEncode({'new_password': newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengatur ulang kata sandi.');
    }
  }

  // ==========================================
  // ACTIVITIES (FR-06 - FR-10)
  // ==========================================
  Future<List<Activity>> getActivities({String? status}) async {
    String url = '${ApiConfig.baseUrl}/activities';
    if (status != null) {
      url += '?status=$status';
    }
    final response = await http.get(Uri.parse(url), headers: _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => Activity.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat daftar kegiatan.');
  }

  Future<Activity> getActivityDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/activities/$id'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Activity.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memuat detail kegiatan.');
  }

  Future<void> createActivity(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/activities'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal menambahkan kegiatan.');
    }
  }

  Future<void> updateActivity(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/activities/$id'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal memperbarui kegiatan.');
    }
  }

  Future<void> cancelActivity(int id, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/activities/$id/cancel'),
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal membatalkan kegiatan.');
    }
  }

  Future<void> copyActivity(int id, {String? newDate, String? newTime}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/activities/$id/copy'),
      headers: _headers(),
      body: jsonEncode({'activity_date': newDate, 'activity_time': newTime}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal menyalin kegiatan.');
    }
  }

  // ==========================================
  // DONATIONS (FR-11 - FR-17)
  // ==========================================
  Future<List<Donation>> getDonations({int? activityId, String? type, String? status}) async {
    final params = <String>[];
    if (activityId != null) params.add('activity_id=$activityId');
    if (type != null) params.add('type=$type');
    if (status != null) params.add('status=$status');
    
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/donations$query'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => Donation.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat daftar donasi.');
  }

  Future<void> createDonation(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/donations'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mencatat donasi.');
    }
  }

  Future<void> cancelDonation(int id, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/donations/$id/cancel'),
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal membatalkan donasi.');
    }
  }

  // ==========================================
  // EXPENSES (FR-18 - FR-21)
  // ==========================================
  Future<List<Expense>> getExpenses({int? activityId}) async {
    final query = activityId != null ? '?activity_id=$activityId' : '';
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/expenses$query'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => Expense.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat pengeluaran.');
  }

  Future<void> createExpense(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/expenses'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mencatat pengeluaran.');
    }
  }

  Future<void> cancelExpense(int id, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/expenses/$id/cancel'),
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal membatalkan pengeluaran.');
    }
  }

  // ==========================================
  // KAS & SELISIH (FR-22 - FR-26)
  // ==========================================
  Future<Map<String, dynamic>> getCashSummary() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cash/summary'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Gagal memuat ringkasan kas.');
  }

  Future<List<CashTransaction>> getCashTransactions() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cash/transactions'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => CashTransaction.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat transaksi kas.');
  }

  Future<void> recordCashTransaction(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cash/transaction'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mencatat transaksi kas.');
    }
  }

  // ==========================================
  // CONFIRMATIONS (FR-27 - FR-31)
  // ==========================================
  Future<String> submitConfirmation(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/confirmations'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data']['reference_code'];
    }
    throw Exception(data['message'] ?? 'Gagal mengirim konfirmasi donasi.');
  }

  Future<DonationConfirmation> checkConfirmation(String refCode) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/confirmations/check/$refCode'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return DonationConfirmation.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Kode referensi tidak ditemukan.');
  }

  Future<List<DonationConfirmation>> getConfirmations({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/confirmations$query'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => DonationConfirmation.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat daftar konfirmasi.');
  }

  Future<void> approveConfirmation(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/confirmations/$id/approve'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal menyetujui konfirmasi.');
    }
  }

  Future<void> rejectConfirmation(int id, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/confirmations/$id/reject'),
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal menolak konfirmasi.');
    }
  }

  // ==========================================
  // REPORTS & PUBLICATION (FR-32 - FR-37)
  // ==========================================
  Future<Map<String, dynamic>> getReportSummary({String? startDate, String? endDate, int? activityId}) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (activityId != null) params.add('activity_id=$activityId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/summary$query'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Gagal menyusun ringkasan laporan.');
  }

  Future<List<PublishedReport>> getPublishedReports() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/published'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => PublishedReport.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat laporan publik.');
  }

  Future<List<PublishedReport>> getAllReportsAdmin() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/admin'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => PublishedReport.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Gagal memuat laporan pengurus.');
  }

  Future<void> publishReport(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reports/publish'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mempublikasikan laporan.');
    }
  }

  Future<void> unpublishReport(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reports/$id/unpublish'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal menarik publikasi laporan.');
    }
  }

  // ==========================================
  // MOSQUE INFO & WHATSAPP (FR-38 - FR-42)
  // ==========================================
  Future<MosqueInfo> getMosqueInfo() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/mosque'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return MosqueInfo.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Gagal memuat info masjid.');
  }

  Future<void> updateMosqueInfo(Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/mosque'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal memperbarui info masjid.');
    }
  }

  Future<String> getActivityWhatsAppText(int activityId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/whatsapp/activity/$activityId'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['share_text'];
    }
    return '';
  }

  Future<String> getReportWhatsAppText(int reportId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/whatsapp/report/$reportId'),
      headers: _headers(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['share_text'];
    }
    return '';
  }
}

// Global Singleton Instance
final apiService = ApiService();
