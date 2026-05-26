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
    final powerManager = context.read<PowerManagerService>();
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
                  onPowerOff: () async => await powerManager.shutdown(),
                  onRestart: () async => await powerManager.reboot(),
                  onSuspend: () async => await powerManager.suspend(),
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

class _GreeterPowerButton extends StatelessWidget {
  final void Function()? onSuspend;
  final void Function()? onRestart;
  final void Function()? onPowerOff;
  final void Function()? onPopoverOpened;
  final void Function()? onPopoverClosed;

  const _GreeterPowerButton({
    this.onSuspend,
    this.onRestart,
    this.onPowerOff,
    this.onPopoverOpened,
    this.onPopoverClosed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.secondary(
      icon: const Icon(Icons.power_settings_new),
      onPressed: () {
        onPopoverOpened?.call();
        showDropdown(
          context: context,
          rootOverlay: false,
          builder: (context) {
            return DropdownMenu(
              children: [
                MenuButton(
                  onPressed: (_) => onSuspend?.call(),
                  child: const Text('Suspend'),
                ),
                MenuButton(
                  onPressed: (_) => onRestart?.call(),
                  child: const Text('Restart'),
                ),
                MenuButton(
                  onPressed: (_) => onPowerOff?.call(),
                  child: const Text('Power Off'),
                ),
              ],
            );
          },
        ).future.then((_) {
          onPopoverClosed?.call();
        });
      },
    );
  }
}