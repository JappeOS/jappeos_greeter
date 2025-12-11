import 'package:jappeos_greeter/provider/debug_ui_provider.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/greeter_provider.dart';
import 'debug_ui_gate.dart';
import 'greeter.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DebugUiProvider>(
      create: (_) => DebugUiProvider(),
      child: ChangeNotifierProvider<GreeterProvider>(
        create: (_) => GreeterProvider(),
        child: JappeosServiceProvider(
          child: ShadcnApp(
            title: 'JappeOS Greeter',
            theme: ThemeData(
              colorScheme: ColorSchemes.darkViolet,
              radius: 0.5,
              surfaceBlur: 10,
            ),
            home: DebugUiGate(child: Greeter()),
          ),
        ),
      ),
    );
  }
}