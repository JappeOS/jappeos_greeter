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

// ignore_for_file: control_flow_in_finally

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

import '../provider/greeter_provider.dart';
import 'create_initial_user_prompt.dart';
import 'greeter_action_buttons.dart';

class Greeter extends StatefulWidget {
  const Greeter({super.key});

  @override
  State<Greeter> createState() => _GreeterState();
}

class _GreeterState extends State<Greeter> {
  static const String kBackgroundsPath = "/usr/share/backgrounds/";
  static const Duration kInactivityTimeout = Duration(seconds: 30);
  static const Duration kTimeUpdateInterval = Duration(minutes: 1);

  late final Future<void> _initializationFuture;
  File? _backgroundImageFile;
  Timer? _clockTimer;
  Timer? _inactivityTimer;

  GreeterPage _currentPage = GreeterPage.main;
  bool _shouldAnimatePageTransition = false;
  final _focusNode = FocusNode();

  final _timeNotifier = ValueNotifier<String>('');
  final _dateNotifier = ValueNotifier<String>('');

  // User login state
  String _selectedUsername = "";
  String _selectedDisplayName = "";
  String _passwordInput = "";
  String? _loginError;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
    _startClockTimer();
    _loadRandomWallpaper();
    //ServicesBinding.instance.keyboard.addHandler(_onAnyKey);
    _focusNode.requestFocus();
  }

  Future<void> _initialize() async {
    final greeterProvider = context.read<GreeterProvider>();
    final accountManager = context.read<AccountManagerService>();
    await greeterProvider.initialize(accountManager);
  }

  void _startClockTimer() {
    _updateTime();
    _clockTimer = Timer.periodic(kTimeUpdateInterval, (_) => _updateTime());
  }

  void _updateTime() {
    if (_currentPage != GreeterPage.main) return;

    final now = DateTime.now();
    _timeNotifier.value = DateFormat('HH:mm').format(now);
    _dateNotifier.value = DateFormat('EEEE, MMMM d').format(now);
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(kInactivityTimeout, _returnToMainPage);
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _returnToMainPage() {
    if (_currentPage != GreeterPage.main) {
      setState(() => _currentPage = GreeterPage.main);
    }
  }

  Future<void> _loadRandomWallpaper() async {
    final wallpaperFile = await _getRandomWallpaper();
    if (wallpaperFile != null && mounted) {
      setState(() => _backgroundImageFile = wallpaperFile);
    }
  }

  Future<File?> _getRandomWallpaper() async {
    final dir = Directory(kBackgroundsPath);

    if (!await dir.exists()) {
      debugPrint("Background directory does not exist: $kBackgroundsPath");
      return null;
    }

    final imageFiles = await dir
        .list()
        .where((entity) => entity is File && _isSupportedImageFormat(entity.path))
        .map((entity) => entity as File)
        .toList();

    if (imageFiles.isEmpty) {
      debugPrint("No supported wallpaper images found in $kBackgroundsPath");
      return null;
    }

    final random = Random();
    return imageFiles[random.nextInt(imageFiles.length)];
  }

  bool _isSupportedImageFormat(String path) {
    const supportedExtensions = ['.jpg', '.jpeg', '.png'];
    final lowerPath = path.toLowerCase();
    return supportedExtensions.any(lowerPath.endsWith);
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    _cancelInactivityTimer();
    setState(() => _isLoggingIn = true);

    try {
      final sessionManager = context.read<SessionManagerService>();
      final greeterProvider = context.read<GreeterProvider>();
      await greeterProvider.login(sessionManager, _selectedUsername, _passwordInput);
      _navigateToPage(GreeterPage.none);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loginError = "Incorrect password. Please try again.");
    } finally {
      if (!mounted) return;

      setState(() => _isLoggingIn = false);
      _startInactivityTimer();
    }
  }

  void _navigateToPage(GreeterPage page) {
    setState(() {
      _shouldAnimatePageTransition = true;
      _currentPage = page;
    });
    _startInactivityTimer();
  }

  void _selectUser(String username, String displayName) {
    _selectedUsername = username;
    _selectedDisplayName = displayName;
    _passwordInput = "";
    _loginError = null;
    _navigateToPage(GreeterPage.user);
  }

  /*bool _onAnyKey(KeyEvent _) {
    return _onUnlockMainPage();
  }*/

  bool _onUnlockMainPage() {
    if (_currentPage == GreeterPage.main) {
      final greeterProvider = context.read<GreeterProvider>();
      if (greeterProvider.usersList.length == 1) {
        final entry = greeterProvider.usersList.entries.first;
        _selectUser(entry.key, entry.value);
      } else {
        _navigateToPage(GreeterPage.userList);
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    //ServicesBinding.instance.keyboard.removeHandler(_onAnyKey);
    _clockTimer?.cancel();
    _cancelInactivityTimer();
    _timeNotifier.dispose();
    _dateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        return GreeterCreateInitialUserGate(
          child: _buildGreeterContent(),
        );
      },
    );
  }

  Widget _buildGreeterContent() {
    return Focus(
      focusNode: _focusNode,
      //autofocus: true,
      onKeyEvent: (node, event) {
        if (_onUnlockMainPage()) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TapRegion(
        behavior: HitTestBehavior.opaque,
        onTapInside: (_) => _onUnlockMainPage(),
        child: _buildBackgroundWithContent(),
      ),
    );
  }

  Widget _buildBackgroundWithContent() {
    final content = _buildBlurredSurface();

    if (_backgroundImageFile == null) {
      return content;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.file(
            _backgroundImageFile!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: content),
      ],
    );
  }

  Widget _buildBlurredSurface() {
    final isMainPage = _currentPage == GreeterPage.main;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      tween: Tween<double>(
        begin: 0,
        end: isMainPage ? 0 : Theme.of(context).surfaceBlur,
      ),
      builder: (context, blurValue, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isMainPage
                ? Colors.transparent
                : Theme.of(context).colorScheme.background.withValues(alpha: 0.8),
          ),
          child: SurfaceBlur(
            surfaceBlur: blurValue,
            child: child!,
          ),
        );
      },
      child: _buildPageContent(),
    );
  }

  Widget _buildPageContent() {
    final greeterProvider = context.watch<GreeterProvider>();
    final sortedUsers = SplayTreeMap<String, String>()
      ..addAll(greeterProvider.usersList);

    Widget pageWidget = switch (_currentPage) {
      GreeterPage.main => _MainPage(
        timeNotifier: _timeNotifier,
        dateNotifier: _dateNotifier,
      ),
      GreeterPage.userList => _UsersListPage(
        users: sortedUsers,
        onUserSelected: _selectUser,
        onPopoverOpened: _cancelInactivityTimer,
        onPopoverClosed: _startInactivityTimer,
      ),
      GreeterPage.user => _UserLoginPage(
        displayName: _selectedDisplayName,
        isLoggingIn: _isLoggingIn,
        loginError: _loginError,
        onPasswordChanged: (value) {
          _passwordInput = value;
          _startInactivityTimer();
        },
        onPasswordSubmitted: (value) {
          _passwordInput = value;
          _handleLogin();
        },
        onPopoverOpened: _cancelInactivityTimer,
        onPopoverClosed: _startInactivityTimer,
      ),
      GreeterPage.none => SizedBox.shrink(),
    };

    return WidgetAnimator(
      key: ValueKey(_currentPage),
      incomingEffect: _shouldAnimatePageTransition
          ? WidgetTransitionEffects.incomingSlideInFromBottom()
          : null,
      outgoingEffect: WidgetTransitionEffects.outgoingSlideOutToTop(),
      child: pageWidget,
    );
  }
}

enum GreeterPage {
  main,
  userList,
  user,
  none,
}

class _MainPage extends StatelessWidget {
  final ValueNotifier<String> timeNotifier;
  final ValueNotifier<String> dateNotifier;

  const _MainPage({
    required this.timeNotifier,
    required this.dateNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final scaling = Theme.of(context).scaling;
    final textShadow = Shadow(
      color: Colors.black.withValues(alpha: 0.6),
      offset: const Offset(2, 2),
      blurRadius: 4,
    );

    return Column(
      key: const ValueKey('main-page'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Gap(16 * scaling),
        const Spacer(),
        ValueListenableBuilder<String>(
          valueListenable: timeNotifier,
          builder: (context, time, _) => Text(
            time,
            style: TextStyle(shadows: [textShadow]),
          ).x8Large(),
        ),
        Gap(16 * scaling),
        ValueListenableBuilder<String>(
          valueListenable: dateNotifier,
          builder: (context, date, _) => Text(
            date,
            style: TextStyle(shadows: [textShadow]),
          ).x3Large(),
        ),
        const Spacer(),
        TextAnimator(
          "Press any key to unlock.",
          atRestEffect: WidgetRestingEffects.wave(),
          style: TextStyle(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(2, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        Gap(16 * scaling),
      ],
    );
  }
}

class _UsersListPage extends StatelessWidget {
  final SplayTreeMap<String, String> users;
  final Function(String username, String displayName) onUserSelected;
  final VoidCallback onPopoverOpened;
  final VoidCallback onPopoverClosed;

  const _UsersListPage({
    required this.users,
    required this.onUserSelected,
    required this.onPopoverOpened,
    required this.onPopoverClosed,
  });

  @override
  Widget build(BuildContext context) {
    final scaling = Theme.of(context).scaling;

    return GreeterActionButtons(
      key: const ValueKey('users-list'),
      onPopoverOpened: onPopoverOpened,
      onPopoverClosed: onPopoverClosed,
      child: Center(
        child: SizedBox(
          width: 250,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final entry = users.entries.elementAt(index);
              return Padding(
                padding: EdgeInsets.only(
                  left: 4 * scaling,
                  right: 4 * scaling,
                  bottom: 4 * scaling,
                ),
                child: GhostButton(
                  leading: const Icon(Icons.account_circle_rounded),
                  onPressed: () => onUserSelected(entry.key, entry.value),
                  child: Text(entry.value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserLoginPage extends StatefulWidget {
  final String displayName;
  final bool isLoggingIn;
  final String? loginError;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onPasswordSubmitted;
  final VoidCallback onPopoverOpened;
  final VoidCallback onPopoverClosed;

  const _UserLoginPage({
    required this.displayName,
    required this.isLoggingIn,
    this.loginError,
    required this.onPasswordChanged,
    required this.onPasswordSubmitted,
    required this.onPopoverOpened,
    required this.onPopoverClosed,
  });

  @override
  State<_UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<_UserLoginPage> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return GreeterActionButtons(
      key: const ValueKey('user-page'),
      onPopoverOpened: widget.onPopoverOpened,
      onPopoverClosed: widget.onPopoverClosed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_rounded,
            size: 100,
          ),
          Gap(8 * scaling),
          Text(widget.displayName).h3(),
          Gap(16 * scaling),
          SizedBox(
            width: 250,
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              features: !widget.isLoggingIn ? [
                InputFeature.passwordToggle(
                  visibility: InputFeatureVisibility.textNotEmpty,
                  mode: PasswordPeekMode.hold,
                ),
                InputFeature.trailing(
                  IconButton.text(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () => widget.onPasswordSubmitted(_controller.text),
                    density: ButtonDensity.compact,
                  ),
                  visibility: InputFeatureVisibility.textNotEmpty,
                ),
              ] : [
                InputFeature.trailing(
                  const SizedBox.square(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              hintText: "Password",
              placeholder: const Text("Password"),
              textAlign: TextAlign.left,
              enabled: !widget.isLoggingIn,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              //autofocus: true,
              filled: true,
              onChanged: widget.onPasswordChanged,
              onSubmitted: widget.onPasswordSubmitted,
            ),
          ),
          Gap(6 * scaling),
          Text(
            widget.loginError ?? "",
            style: theme.typography.small.copyWith(color: Colors.red),
          ),
        ],
      ),
    );
  }
}