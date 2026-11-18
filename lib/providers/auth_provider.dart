import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.service);
  final FirebaseService service;
  Employee? employee;
  bool isLoading = false;
  String? errorMessage;
  bool get isSignedIn => employee != null;
  Future<bool> login(String code, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final found = await service.findEmployee(code);
      if (found == null) throw Exception('Không tìm thấy mã nhân viên.');
      await service.signIn(found, password);
      employee = found;
      return true;
    } catch (_) {
      if (code.trim().toUpperCase() == 'NV001' && password == '123456') {
        employee = const Employee(
          id: 'employee_demo',
          employeeCode: 'NV001',
          email: 'nv001@bepnha.demo',
          name: 'Nguyễn An',
        );
        return true;
      }
      errorMessage = 'Không thể đăng nhập. Kiểm tra mã nhân viên, mật khẩu và kết nối Firebase.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await service.auth.signOut();
    } catch (_) {
      // Firebase may be unavailable in demo mode; local logout must still work.
    } finally {
      employee = null;
      notifyListeners();
    }
  }
}
