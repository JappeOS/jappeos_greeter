//  jappeos_greeter, The login UI for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:crypt/crypt.dart';
import 'package:jappeos_greeter/src/provider/debug_ui_provider.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GreeterProvider extends ChangeNotifier {
  final Map<String, String> _usersMap = {};
  Map<String, String> get usersList => Map.unmodifiable(_usersMap);
  bool _isInitialized = false;
  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;
  bool _shouldShowInitialUserCreationDialog = false;
  bool get shouldShowInitialUserCreationDialog
      => _shouldShowInitialUserCreationDialog;

  Future<void> initialize(AccountManagerService service) async {
    await _refreshUsersList(service);
    if (_usersMap.isEmpty) {
      _shouldShowInitialUserCreationDialog = true;
      notifyListeners();
    }
    _isInitialized = true;
  }

  Future<void> createInitialUser(
    DebugUiProvider dbg,
    AccountManagerService service,
    String realName,
    String password,
  ) async {
    if (!_isInitialized) {
      throw StateError("GreeterProvider must be initialized before creating an initial user.");
    }

    if (realName.trim().isEmpty) {
      throw ArgumentError("Real name cannot be empty.");
    }

    if (password.isEmpty) {
      throw ArgumentError("Password cannot be empty.");
    }

    await service.createInitialUserWithPassword(
      realName.toLowerCase().trim().replaceAll(" ", "_"),
      realName,
      _cryptPassword(password),
    );

    // If successful, update state
    _shouldShowInitialUserCreationDialog = false;
    await _refreshUsersList(service);
    notifyListeners();
  }

  Future<void> login(
    SessionManagerService service,
    String username,
    String password,
  ) async {
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

class DummyGreeterProvider extends ChangeNotifier {
  final Map<String, String> _usersMap = {};
  Map<String, String> get usersList => Map.unmodifiable(_usersMap);
  bool _isInitialized = false;
  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;
  bool _shouldShowInitialUserCreationDialog = false;
  bool get shouldShowInitialUserCreationDialog
      => _shouldShowInitialUserCreationDialog;

  Future<void> initialize(AccountManagerService service) async {
    _shouldShowInitialUserCreationDialog = true;
    await Future.delayed(Duration.zero);
    notifyListeners();
    _isInitialized = true;
  }

  Future<void> createInitialUser(
    DebugUiProvider dbg,
    AccountManagerService service,
    String realName,
    String password,
  ) async {
    _usersMap.addAll({
      "user1": "User One",
      "user2": "User Two",
    });

    await Future.delayed(const Duration(seconds: 2));

    _shouldShowInitialUserCreationDialog = false;
    notifyListeners();
  }

  Future<void> login(
    SessionManagerService service,
    String username,
    String password,
  ) async {
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
      await Future.delayed(const Duration(seconds: 5));
      throw Exception("Simulated login failure");
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }
}