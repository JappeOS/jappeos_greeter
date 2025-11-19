import 'package:jappeos_services/jappeos_services.dart';
import 'package:shade_ui/shade_ui.dart';

class GreeterProvider extends ChangeNotifier {
  Map<String, String> _usersMap = {};
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

  Future<void> createInitialUser(AccountManagerService service, String realName, String password) async {
    if (!_isInitialized) {
      throw StateError("GreeterProvider must be initialized before creating an initial user.");
    }

    if (realName.trim().isEmpty) {
      throw ArgumentError("Real name cannot be empty.");
    }

    if (password.isEmpty) {
      throw ArgumentError("Password cannot be empty.");
    }

    // TODO: Crypt password
    await service.createInitialUserWithPassword(realName.toLowerCase().trim().replaceAll(" ", "_"), realName, password);

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
      await service.createSession(username, password);
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> _refreshUsersList(AccountManagerService service) async {
    var users = await service.listUsers();
    _usersMap.clear();
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
}