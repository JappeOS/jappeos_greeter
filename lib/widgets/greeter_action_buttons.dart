import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shade_ui/shade_ui.dart';

class GreeterActionButtons extends StatefulWidget {
  final void Function()? onPopoverOpened;
  final void Function()? onPopoverClosed;
  final Widget child;

  const GreeterActionButtons({super.key, required this.child, this.onPopoverOpened, this.onPopoverClosed});

  @override
  State<GreeterActionButtons> createState() => _GreeterActionButtonsState();
}

class _GreeterActionButtonsState extends State<GreeterActionButtons> {
  int _openPopovers = 0;
  int _openPopoversPrev = 0;

  void _openPopover(bool open) {
    if (open) _openPopovers++;
    else _openPopovers--;

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
                  value: 0.5,
                  onPopoverOpened: () => _openPopover(true),
                  onPopoverClosed: () => _openPopover(false),
                ), // TODO: Implement audio
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

  const _GreeterVolumeButton({super.key, required this.value, this.onChanged, this.onPopoverOpened, this.onPopoverClosed});

  @override
  Widget build(BuildContext context) {
    final scaling = Theme.of(context).scaling;
    return IconButton.secondary(
      icon: Icon(Icons.volume_up),
      onPressed: () {
        onPopoverOpened?.call();
        showPopover(
          context: context,
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
                    SizedBox(width: 250, child: Slider(
                      value: SliderValue.single(value),
                      onChanged: (v) => onChanged != null ? onChanged!(v.value) : null,
                    ),),
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

  const _GreeterPowerButton({super.key, this.onSuspend, this.onRestart, this.onPowerOff, this.onPopoverOpened, this.onPopoverClosed});

  @override
  Widget build(BuildContext context) {
    return IconButton.secondary(
      icon: Icon(Icons.power_settings_new),
      onPressed: () {
        onPopoverOpened?.call();
        showDropdown(
          context: context,
          builder: (context) {
            return DropdownMenu(
              children: [
                MenuButton(
                  onPressed: (_) => onSuspend?.call(),
                  child: Text('Suspend'),
                ),
                MenuButton(
                  onPressed: (_) => onRestart?.call(),
                  child: Text('Restart'),
                ),
                MenuButton(
                  onPressed: (_) => onPowerOff?.call(),
                  child: Text('Power Off'),
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