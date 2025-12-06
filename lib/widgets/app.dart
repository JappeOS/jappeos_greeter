import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shade_ui/shade_ui.dart';

import '../provider/greeter_provider.dart';
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
      home: ChangeNotifierProvider<GreeterProvider>(
        create: (_) => GreeterProvider(),
        child: JappeosServiceProvider(child: Greeter()),
      ),
    );
  }
}