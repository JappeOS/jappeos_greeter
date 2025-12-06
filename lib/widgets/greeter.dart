import 'dart:async';

import 'package:intl/intl.dart';
import 'package:jappeos_greeter/provider/greeter_provider.dart';
import 'package:jappeos_greeter/widgets/create_initial_user_prompt.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shade_ui/shade_ui.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

import 'greeter_action_buttons.dart';

typedef UserList = List<String>;

class Greeter extends StatefulWidget {
  const Greeter({super.key});

  @override
  State<Greeter> createState() => _GreeterState();
}

class _GreeterState extends State<Greeter> {
  late Future<void> _initializationFuture;
  String _timeString = '';
  String _dateString = '';
  Timer? _timer;
  Timer? _backToMainPageTimer;
  _Page _currentPage = _Page.main;
  bool _initialBaseBuild = true;
  String _selectedUser = "";
  String _currentPassword = "";
  String? _currentLoginError;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = context.read<GreeterProvider>().initialize(context.read<AccountManagerService>()); // TODO: Error handling
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);
    if (_currentPage == _Page.main) {
      setState(() {
        _timeString = formattedTime;
        _dateString = formattedDate;
      });
    }
  }

  void _beginBackToMainPageTimer() {
    _backToMainPageTimer?.cancel();
    _backToMainPageTimer = Timer(const Duration(seconds: 30), () => setState(() => _currentPage = _Page.main));
  }

  Future<void> _onLogin(String username, String password) async {
    await context.read<GreeterProvider>().login(context.read<SessionManagerService>(), username, password);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backToMainPageTimer?.cancel();
    super.dispose();
  }

  Widget _buildBase(Widget child) {
    final w = WidgetAnimator(
      incomingEffect: _initialBaseBuild ? null : WidgetTransitionEffects.incomingSlideInFromBottom(),
      outgoingEffect: WidgetTransitionEffects.outgoingSlideOutToTop(),
      child: child,
    );
    _initialBaseBuild = false;
    return w;
  }

  Widget _buildMainPage() => Column(
    key: const ValueKey('main-page'),
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: 16 * Theme.of(context).scaling,
    children: [
      Gap(16 * Theme.of(context).scaling),
      Spacer(),
      Text(
        _timeString,
      ).x8Large(),
      Text(
        _dateString,
      ).x4Large(),
      Spacer(),
      TextAnimator(
        "Press any key to unlock.",
        atRestEffect: WidgetRestingEffects.wave(),
      ),
      Gap(16 * Theme.of(context).scaling),
    ],
  );

  Widget _buildUsersList(List<String> usersList) => GreeterActionButtons(
    key: const ValueKey('users-list'),
    onPopoverOpened: () => _backToMainPageTimer?.cancel(),
    onPopoverClosed: () => _beginBackToMainPageTimer(),
    child: Center(
      child: SizedBox(
        width: 250,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: usersList.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(left: 4 * Theme.of(context).scaling, right: 4 * Theme.of(context).scaling, bottom: 4 * Theme.of(context).scaling),
            child: GhostButton(
              leading: const Icon(Icons.account_circle_rounded),
              onPressed: () => setState(() {
                _currentPage = _Page.user;
                _selectedUser = usersList[index];
                _beginBackToMainPageTimer();
              }),
              child: Text(usersList[index]),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildUserPage() => GreeterActionButtons(
    key: const ValueKey('user-page'),
    onPopoverOpened: () => _backToMainPageTimer?.cancel(),
    onPopoverClosed: () => _beginBackToMainPageTimer(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_circle_rounded,
          size: 100,
        ),
        SizedBox(height: 4 * Theme.of(context).scaling),
        Text(
          _selectedUser,
        ).h3(),
        SizedBox(height: 8 * Theme.of(context).scaling),
        SizedBox(
          width: 250,
          child: TextField( // TODO: Error text and password visibility toggle
            /*decoration: InputDecoration(
              hintText: "Password",
              errorText: _currentLoginError,
            ),*/
            hintText: "Password",
            placeholder: const Text("Password"),
            textAlign: TextAlign.center,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            filled: true,
            onChanged: (str) {
              _currentPassword = str;
              _beginBackToMainPageTimer();
            },
            onSubmitted: (p0) async {
              _currentPassword = p0;
              _backToMainPageTimer?.cancel();
              setState(() => _isLoggingIn = true);
              try {
                await _onLogin(_selectedUser, _currentPassword);
              } catch (e) {
                if (!mounted) return;
                _currentLoginError = e.toString();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Login Error'),
                    content: Text(e.toString()),
                    actions: [
                      PrimaryButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } finally {
                if (!mounted) return;
                _beginBackToMainPageTimer();
                setState(() => _isLoggingIn = false);
              }
            },
          ),
        )
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_currentPage == _Page.user) _currentLoginError = null;

    final greeterProvider = context.watch<GreeterProvider>();

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        return GreeterCreateInitialUserGate(
          child: TapRegion(
            behavior: HitTestBehavior.opaque,
            onTapInside: (_) {
              if (_currentPage == _Page.main) {
                setState(() {
                  _currentPage = _Page.list;
                  _beginBackToMainPageTimer();
                });
              }
            },
            child: SurfaceBlur(
              surfaceBlur: Theme.of(context).surfaceBlur,
              child: _buildBase(switch (_currentPage) {
                _Page.main => _buildMainPage(),
                _Page.list => _buildUsersList(greeterProvider.usersList.values.toList()..sort((a, b) => a.toString().toLowerCase().compareTo(b.toString().toLowerCase()))), // TODO: Cache sorted list and update only on changes
                _Page.user => _buildUserPage(),
              }),
            ),
          ),
        );
      },
    );
  }
}

enum _Page {
  main,
  list,
  user,
}