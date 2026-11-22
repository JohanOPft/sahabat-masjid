import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthState extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isTakmir => _currentUser?.isTakmir ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> register(String name, String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await apiService.register(name, email, password, role);
      _token = res['token'];
      _currentUser = User.fromJson(res['user']);
      apiService.setToken(_token);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await apiService.login(email, password);
      _token = res['token'];
      _currentUser = User.fromJson(res['user']);
      apiService.setToken(_token);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    apiService.setToken(null);
    notifyListeners();
  }
}
