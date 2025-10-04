import 'package:flutter/foundation.dart';

class LogProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> logs = const [];

  Future<void> fetchLogs() async {
    // TODO: implement fetching
  }

  void clearLogs() {
    logs = const [];
    notifyListeners();
  }
}
