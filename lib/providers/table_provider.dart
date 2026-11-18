import 'package:flutter/foundation.dart';

import '../main.dart';
import '../models/table_model.dart';
import '../services/firebase_service.dart';

class TableProvider extends ChangeNotifier {
  TableProvider(this.service);
  final FirebaseService service;
  List<RestaurantTable> tables = [];
  bool isLoading = false;
  String? errorMessage;
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      tables = await service.fetchTables();
    } catch (_) {
      tables = List<RestaurantTable>.from(demoTables);
      errorMessage = 'Đang dùng dữ liệu demo. Hãy kiểm tra cấu hình Firebase.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateLocal(RestaurantTable table) {
    final index = tables.indexWhere((item) => item.id == table.id);
    if (index >= 0) {
      tables[index] = table;
      notifyListeners();
    }
  }
}
