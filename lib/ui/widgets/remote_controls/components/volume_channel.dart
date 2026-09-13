import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/controller_button.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class VolumeChannelControls extends StatelessWidget {
  const VolumeChannelControls({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ControllerButton(
          borderRadius: 15,
          child: Column(
            children: [
              _CircleAction(
                icon: Icons.keyboard_arrow_up,
                label: l.volumeUp,
                keyCode: KeyCodes.KEY_VOLUP,
              ),
              _CircleAction(
                icon: Icons.volume_off,
                label: l.mute,
                keyCode: KeyCodes.KEY_MUTE,
                width: 80,
              ),
              _CircleAction(
                icon: Icons.keyboard_arrow_down,
                label: l.volumeDown,
                keyCode: KeyCodes.KEY_VOLDOWN,
              ),
            ],
          ),
        ),
        Column(
          children: [
            ControllerButton(
              borderRadius: 15,
              onPressed: () => context.sendTvKey(KeyCodes.KEY_HOME),
              child: const Text(
                'MENU',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 35),
            ControllerButton(
              borderRadius: 15,
              onPressed: () => context.sendTvKey(KeyCodes.KEY_MORE),
              child: const Text(
                'MORE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
        ControllerButton(
          borderRadius: 15,
          child: Column(
            children: [
              _CircleAction(
                icon: Icons.keyboard_arrow_up,
                label: l.channelUp,
                keyCode: KeyCodes.KEY_CHUP,
                height: 40,
                width: 40,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'P',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ),
              _CircleAction(
                icon: Icons.keyboard_arrow_down,
                label: l.channelDown,
                keyCode: KeyCodes.KEY_CHDOWN,
                width: 80,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.keyCode,
    this.width = 50,
    this.height = 50,
  });

  final IconData icon;
  final String label;
  final KeyCodes keyCode;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: MaterialButton(
        height: height,
        minWidth: width,
        shape: const CircleBorder(),
        onPressed: () => context.sendTvKey(keyCode),
        child: Icon(icon, size: 20, color: Colors.white54),
      ),
    );
  }
}
