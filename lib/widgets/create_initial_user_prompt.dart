import 'package:shade_ui/shade_ui.dart';

class GreeterCreateInitialUserPrompt extends StatelessWidget {
  final void Function(String username, String password)? onCreated;

  final FormController controller = FormController();

  GreeterCreateInitialUserPrompt({super.key, this.onCreated});

  @override
  Widget build(BuildContext context) {
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
              child: const FormTableLayout(rows: [
                FormField<String>(
                  key: FormKey(#name),
                  label: Text('Name'),
                  child: TextField(
                    initialValue: 'JappeOS User',
                    autofocus: true,
                  ),
                ),
                FormField<String>(
                  key: FormKey(#password),
                  label: Text('Password'),
                  child: TextField(
                    obscureText: true,
                  ),
                ),
              ]),
            ).withPadding(vertical: 16),
          ),
        ],
      ),
      actions: [
        PrimaryButton(
          onPressed: onCreated != null && controller.errors.isEmpty ? () {
            onCreated!(controller.values[FormKey(#name)], controller.values[FormKey(#password)]);
            Navigator.of(context).pop(controller.values);
          } : null,
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}