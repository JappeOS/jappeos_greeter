import 'package:shadcn_flutter/shadcn_flutter.dart';

class DebugUiProvider extends ChangeNotifier {
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void writeLog(String log) {
    _logs.add(log);
    notifyListeners();
  }
}