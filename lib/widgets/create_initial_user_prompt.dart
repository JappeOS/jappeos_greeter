import 'package:jappeos_greeter/provider/greeter_provider.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shade_ui/shade_ui.dart';

class GreeterCreateInitialUserGate extends StatefulWidget {
  final Widget child;

  const GreeterCreateInitialUserGate({super.key, required this.child});

  @override
  State<GreeterCreateInitialUserGate> createState() => _GreeterCreateInitialUserGateState();
}

class _GreeterCreateInitialUserGateState extends State<GreeterCreateInitialUserGate> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldShowDialog = context.watch<GreeterProvider>().shouldShowInitialUserCreationDialog;

    if (shouldShowDialog && !_dialogShown) {
      _dialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _GreeterCreateInitialUserPrompt(
            onCreated: (username, password) async => await context.read<GreeterProvider>().createInitialUser(context.read<AccountManagerService>(), username, password),
          ),
        );
      });
    } else if (shouldShowDialog && _dialogShown) {
      _dialogShown = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _GreeterCreateInitialUserPrompt extends StatefulWidget {
  final Future<void> Function(String username, String password)? onCreated;

  const _GreeterCreateInitialUserPrompt({this.onCreated});

  @override
  State<_GreeterCreateInitialUserPrompt> createState() => _GreeterCreateInitialUserPromptState();
}

class _GreeterCreateInitialUserPromptState extends State<_GreeterCreateInitialUserPrompt> {
  final FormController controller = FormController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    Widget errorDialog(String message) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('User Creation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'This system does not have a user yet. Create a user profile below.'),
          const Gap(16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              controller: controller,
              child: FormTableLayout(rows: [
                FormField<String>(
                  key: FormKey(#name),
                  label: Text('Name'),
                  child: TextField(
                    initialValue: 'JappeOS User',
                    autofocus: true,
                    enabled: !_isCreating,
                  ),
                ),
                FormField<String>(
                  key: FormKey(#password),
                  label: Text('Password'),
                  child: TextField(
                    obscureText: true,
                    enabled: !_isCreating,
                  ),
                ),
              ]),
            ).withPadding(vertical: 16),
          ),
        ],
      ),
      actions: [
        PrimaryButton(
          onPressed: !_isCreating && widget.onCreated != null && controller.errors.isEmpty ? () async {
            setState(() => _isCreating = true);
            try {
              await widget.onCreated!(controller.values[FormKey(#name)], controller.values[FormKey(#password)]);
            } catch (e) {
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => errorDialog(e.toString()),
              );
            } finally {
              setState(() => _isCreating = false);
            }
          } : null,
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}