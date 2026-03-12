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

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/debug_ui_provider.dart';

class DebugUiGate extends StatefulWidget {
  final Widget child;

  const DebugUiGate({super.key, required this.child});

  @override
  State<DebugUiGate> createState() => _DebugUiGateState();
}

class _DebugUiGateState extends State<DebugUiGate> {
  @override
  Widget build(BuildContext context) {
    final logs = context.watch<DebugUiProvider>().logs;

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (logs.isNotEmpty && kDebugMode)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.all(2 * Theme.of(context).scaling),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8 * Theme.of(context).scaling),
              ),
              constraints: BoxConstraints(
                maxHeight: 200 * Theme.of(context).scaling,
                maxWidth: 500 * Theme.of(context).scaling,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: logs.map((log) => Text(
                    log,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.foreground,
                      fontSize: 10 * Theme.of(context).scaling,
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}