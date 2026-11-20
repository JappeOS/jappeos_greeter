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

import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GreeterActionButtons extends StatefulWidget {
  final void Function()? onPopoverOpened;
  final void Function()? onPopoverClosed;
  final Widget child;

  const GreeterActionButtons({
    super.key,
    required this.child,
    this.onPopoverOpened,
    this.onPopoverClosed,
  });

  @override
  State<GreeterActionButtons> createState() => _GreeterActionButtonsState();
}

class _GreeterActionButtonsState extends State<GreeterActionButtons> {
  int _openPopovers = 0;
  int _openPopoversPrev = 0;

  void _openPopover(bool open) {
    if (open) {
      _openPopovers++;
    } else {
      _openPopovers--;
    }

    if (_openPopovers > 0 && _openPopoversPrev == 0) {
      widget.onPopoverOpened?.call();
    }

    if (_openPopovers == 0 && _openPopoversPrev > 0) {
      widget.onPopoverClosed?.call();
    }

    _openPopoversPrev = _openPopovers;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();
    final audioDevice = audio.activeOutputDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(child: widget.child),
        Padding(
          padding: EdgeInsets.all(16 * Theme.of(context).scaling),
          child: Row(
            spacing: 8 * Theme.of(context).scaling,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                tooltip: (_) => const TooltipContainer(
                  child: Text("Accessibility"),
                ),
                child: IconButton.secondary(icon: Icon(Icons.accessibility), onPressed: null /*() {}*/), // TODO: Implement accessibility features
              ),
              Tooltip(
                tooltip: (_) => const TooltipContainer(
                  child: Text("Audio"),
                ),
                child: _GreeterVolumeButton(
                  value: audioDevice?.volume ?? 0,
                  onChanged: (v) => audioDevice != null
                      ? audio.setDeviceVolume(audioDevice, v)
                      : null,
                  onPopoverOpened: () => _openPopover(true),
                  onPopoverClosed: () => _openPopover(false),
                ),
              ),
              Tooltip(
                tooltip: (_) => const TooltipContainer(
                  child: Text("Power"),
                ),
                child: _GreeterPowerButton(
                  onPopoverOpened: () => _openPopover(true),
                  onPopoverClosed: () => _openPopover(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreeterVolumeButton extends StatelessWidget {
  final double value;
  final void Function(double)? onChanged;
  final void Function()? onPopoverOpened;
  final void Function()? onPopoverClosed;

  const _GreeterVolumeButton({
    required this.value,
    this.onChanged,
    this.onPopoverOpened,
    this.onPopoverClosed,
  });

  @override
  Widget build(BuildContext context) {
    final scaling = Theme.of(context).scaling;
    return IconButton.secondary(
      icon: Icon(Icons.volume_up),
      onPressed: onChanged == null ? null : () {
        onPopoverOpened?.call();
        showPopover(
          context: context,
          rootOverlay: false,
          alignment: Alignment.bottomCenter,
          offset: Offset(0, -4 * scaling),
          builder: (context) {
            return ModalContainer(
              padding: EdgeInsets.all(2 * scaling),
              child: SizedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2 * scaling,
                  children: [
                    IconButton.ghost(icon: Icon(Icons.volume_up)),
                    SizedBox(
                      width: 250,
                      child: Slider(
                        enabled: onChanged != null,
                        value: SliderValue.single(value),
                        onChanged: (v) => onChanged != null
                            ? onChanged!(v.value)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).future.then((_) {
          onPopoverClosed?.call();
        });
      },
    );
  }
}

class _GreeterPowerButton extends StatefulWidget {
  final void Function()? onPopoverOpened;
  final void Function()? onPopoverClosed;

  const _GreeterPowerButton({
    this.onPopoverOpened,
    this.onPopoverClosed,
  });

  @override
  State<_GreeterPowerButton> createState() => _GreeterPowerButtonState();
}

class _GreeterPowerButtonState extends State<_GreeterPowerButton> {
  Future<PowerActionCapability?> _checkCapability(
    Future<PowerActionCapability> Function() check,
  ) async {
    try {
      return await check();
    } catch (error, stack) {
      debugPrint('Power capability check failed: $error\n$stack');
      return null;
    }
  }

  bool _canOffer(PowerActionCapability? capability) =>
      capability == PowerActionCapability.allowed ||
      capability == PowerActionCapability.authenticationRequired;

  MenuButton _powerAction(
    String label,
    PowerActionCapability? capability,
    Future<void> Function(bool interactive) invoke,
  ) {
    final interactive =
        capability == PowerActionCapability.authenticationRequired;
    return MenuButton(
      trailing: interactive ? const Icon(Icons.lock_outline) : null,
      onPressed: (_) async {
        try {
          await invoke(interactive);
        } catch (error, stack) {
          debugPrint('$label failed: $error\n$stack');
          if (!mounted) return;
          showToast(
            context: context,
            builder: (context, overlay) => SurfaceCard(
              child: Basic(
                title: Text('$label could not be completed'),
                subtitle: const Text(
                    'Authorization may be required, or the system may be busy.'),
              ),
            ),
          );
        }
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.secondary(
      icon: const Icon(Icons.power_settings_new),
      onPressed: () {
        final powerService = context.read<PowerManagerService>();
        final sessionService = context.read<SessionManagerService>();

        // Recheck each time the menu opens: session policy and inhibitors change.
        final capabilities = Future.wait([
          _checkCapability(powerService.canSuspend),
          _checkCapability(powerService.canHibernate),
          _checkCapability(powerService.canReboot),
          _checkCapability(powerService.canShutdown),
        ]);

        widget.onPopoverOpened?.call();
        showDropdown(
          context: context,
          rootOverlay: false,
          builder: (context) {
            return FutureBuilder<List<PowerActionCapability?>>(
              future: capabilities,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = snapshot.data ??
                    List<PowerActionCapability?>.filled(4, null);
                return DropdownMenu(
                  children: [
                    if (_canOffer(results[0]))
                      _powerAction(
                          'Suspend',
                          results[0],
                          (interactive) =>
                              powerService.suspend(interactive: interactive)),
                    if (_canOffer(results[1]))
                      _powerAction(
                          'Hibernate',
                          results[1],
                          (interactive) =>
                              powerService.hibernate(interactive: interactive)),
                    if (_canOffer(results[2]))
                      _powerAction(
                          'Restart',
                          results[2],
                          (interactive) =>
                              powerService.reboot(interactive: interactive)),
                    if (_canOffer(results[3]))
                      _powerAction(
                          'Power Off',
                          results[3],
                          (interactive) =>
                              powerService.shutdown(interactive: interactive)),
                    if (results.contains(null))
                      const MenuLabel(
                          child:
                              Text('Some power options could not be checked.'))
                    else if (!results.any(_canOffer))
                      const MenuLabel(
                          child: Text('No power actions available.')),
                    const MenuDivider(),
                    MenuButton(
                      onPressed: (_) => sessionService.stopSession(),
                      child: const Text('Log Out'),
                    ),
                  ],
                );
              },
            );
          }
        ).future.then((_) {
          widget.onPopoverClosed?.call();
        });
      },
    );
  }
}