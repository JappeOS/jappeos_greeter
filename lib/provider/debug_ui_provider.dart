import 'package:shade_ui/shade_ui.dart';

class DebugUiProvider extends ChangeNotifier {
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void writeLog(String log) {
    _logs.add(log);
    notifyListeners();
  }
}