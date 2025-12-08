import 'package:crypt/crypt.dart';
import 'package:jappeos_greeter/provider/debug_ui_provider.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:shade_ui/shade_ui.dart';

class GreeterProvider extends ChangeNotifier {
  final Map<String, String> _usersMap = {};
  Map<String, String> get usersList => Map.unmodifiable(_usersMap);
  bool _isInitialized = false;
  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;
  bool _shouldShowInitialUserCreationDialog = false;
  bool get shouldShowInitialUserCreationDialog => _shouldShowInitialUserCreationDialog;

  Future<void> initialize(AccountManagerService service) async {
    await _refreshUsersList(service);
    if (_usersMap.isEmpty) {
      _shouldShowInitialUserCreationDialog = true;
      notifyListeners();
    }
    _isInitialized = true;
  }

  Future<void> createInitialUser(DebugUiProvider dbg, AccountManagerService service, String realName, String password) async {
    if (!_isInitialized) {
      throw StateError("GreeterProvider must be initialized before creating an initial user.");
    }

    if (realName.trim().isEmpty) {
      throw ArgumentError("Real name cannot be empty.");
    }

    if (password.isEmpty) {
      throw ArgumentError("Password cannot be empty.");
    }

    await service.createInitialUserWithPassword(realName.toLowerCase().trim().replaceAll(" ", "_"), realName, _cryptPassword(password));

    // If successful, update state
    _shouldShowInitialUserCreationDialog = false;
    await _refreshUsersList(service);
    notifyListeners();
  }

  Future<void> login(SessionManagerService service, String username, String password) async {
    if (!_isInitialized) {
      throw StateError("GreeterProvider must be initialized before creating an initial user.");
    }

    if (_isLoggingIn) {
      throw StateError("A login attempt is already in progress.");
    }

    if (!_usersMap.containsKey(username)) {
      throw ArgumentError("User '$username' does not exist.");
    }

    _isLoggingIn = true;
    notifyListeners();

    try {
      await service.createSession(username, /*_cryptPassword(*/password/*)*/);
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> _refreshUsersList(AccountManagerService service) async {
    _usersMap.clear();

    List<String> users;
    try {
      users = await service.listUsers();
    } catch (e) {
      _usersMap.clear();
      return;
    }

    for (final user in users) {
      try {
        final name = await service.getUserProperty(user, "UserName");     // actual username
        final realname = await service.getUserProperty(user, "RealName"); // display name
        _usersMap[name.asString()] = realname.asString();
      } catch (e) {
        // Ignore users we can't get the name of
      }
    }
  }

  String _cryptPassword(String password) {
    return Crypt.sha512(password, rounds: 5000).toString();
  }
}