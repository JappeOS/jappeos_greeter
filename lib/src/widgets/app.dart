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

import 'package:jappeos_desktop_base/jappeos_desktop_base.dart';
import 'package:jappeos_greeter/src/provider/debug_ui_provider.dart';
import 'package:jappeos_greeter/src/provider/greeter_provider.dart';
import 'package:jdwm/jdwm.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'debug_ui_gate.dart';
import 'greeter.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<WindowManagerState> _wmControllerKey
      = GlobalKey<WindowManagerState>();

  /*final List<MonitorConfig> _monitors = [
    const MonitorConfig(id: "a", bounds: Rect.fromLTWH(0,    0, 1920 / 2, 1080 / 2)),
    const MonitorConfig(id: "b", bounds: Rect.fromLTWH(1920 / 2, 0, 1920 / 2, 1080 / 2)),
    //const MonitorConfig(id: "c", bounds: Rect.fromLTWH(0,   540, 960, 540)),
  ];*/

  @override
  Widget build(BuildContext context) {
    return ShellApp(
      title: 'jappeos_greeter',
      debugShowCheckedModeBanner: false,
      wmKey: _wmControllerKey,
      providers: [
        ListenableProvider<DebugUiProvider>(create: (_) => DebugUiProvider()),
        ListenableProvider<GreeterProvider>(create: (_) => GreeterProvider()),
      ],
      theme: _getTheme(false),
      darkTheme: _getTheme(true),
      monitorBuilder: (context, monitor) {
        final mobileMode = false;
        if (monitor.isPrimary) {
          return OverlayManagerLayer(
            menuHandler:
                (mobileMode
                    ? const SheetOverlayHandler()
                    : const PopoverOverlayHandler()),
            popoverHandler:
                (mobileMode
                    ? const SheetOverlayHandler()
                    : const PopoverOverlayHandler()),
            tooltipHandler:
                (mobileMode
                    ? const FixedTooltipOverlayHandler()
                    : const PopoverOverlayHandler()),
            child: Navigator(
              onGenerateRoute: (settings) => PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => DebugUiGate(child: Greeter())
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }
    );
  }

  ThemeData _getTheme(bool dark) => ThemeData(
    colorScheme: dark
        ? ColorSchemes.darkDefaultColor
        : ColorSchemes.lightDefaultColor,
    radius: 0.9,
    surfaceOpacity: 0.85,
    surfaceBlur: 9,
  );
}