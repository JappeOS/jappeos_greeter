import 'package:shade_ui/shade_ui.dart';

import 'greeter.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'JappeOS Greeter',
      theme: ThemeData(
        colorScheme: ColorSchemes.darkViolet,
        radius: 0.5,
      ),
      home: Greeter(usersList: const [ "Joe", "Mama" ], onLogin: (p0, p1) { /*TODO: login*/ return null;}),
    );
  }
}