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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/debug_ui_provider.dart';
import '../provider/greeter_provider.dart';

class GreeterCreateInitialUserGate extends StatefulWidget {
  final Widget child;

  const GreeterCreateInitialUserGate({super.key, required this.child});

  @override
  State<GreeterCreateInitialUserGate> createState()
      => _GreeterCreateInitialUserGateState();
}

class _GreeterCreateInitialUserGateState
    extends State<GreeterCreateInitialUserGate> {
  @override
  void initState() {
    super.initState();

    final greeterProvider = context.read<GreeterProvider>();
    final shouldShowDialog = greeterProvider.shouldShowInitialUserCreationDialog;
    if (shouldShowDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          useRootNavigator: false,
          barrierDismissible: false,
          builder: (_) => _GreeterCreateInitialUserPrompt(
            onCreated: (username, password) async =>
              await greeterProvider.createInitialUser(
                context.read<DebugUiProvider>(),
                context.read<AccountManagerService>(),
                username,
                password,
              ),
          ),
        );
      });
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
  State<_GreeterCreateInitialUserPrompt> createState()
      => _GreeterCreateInitialUserPromptState();
}

class _GreeterCreateInitialUserPromptState
    extends State<_GreeterCreateInitialUserPrompt> {
  final FormController _controller = FormController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    Widget errorDialog(String message) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.pop(context),
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
              'This system does not have a user yet. Please create a user profile below.'),
          const Gap(16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              controller: _controller,
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
          onPressed: !_isCreating
              && widget.onCreated != null
              && _controller.errors.isEmpty
          ? () async {
            setState(() => _isCreating = true);
            try {
              await widget.onCreated!(
                _controller.values[FormKey(#name)] as String,
                _controller.values[FormKey(#password)] as String,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            } catch (e) {
              if (!context.mounted) return;
              showDialog(
                context: context,
                useRootNavigator: false,
                builder: (_) => errorDialog(e.toString()),
              );
            } finally {
              if (!context.mounted) return;
              setState(() => _isCreating = false);
            }
          } : null,
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}