import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/controller_button.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class MediaControls extends StatelessWidget {
  const MediaControls({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MediaButton(
          icon: Icons.fast_rewind,
          label: l.rewind,
          keyCode: KeyCodes.KEY_REWIND,
        ),
        _MediaButton(
          icon: Icons.fiber_manual_record,
          color: Colors.red,
          label: l.record,
          keyCode: KeyCodes.KEY_REC,
        ),
        _MediaButton(
          icon: Icons.play_arrow,
          label: l.play,
          keyCode: KeyCodes.KEY_PLAY,
        ),
        _MediaButton(
          icon: Icons.stop,
          label: l.stop,
          keyCode: KeyCodes.KEY_STOP,
        ),
        _MediaButton(
          icon: Icons.pause,
          label: l.pause,
          keyCode: KeyCodes.KEY_PAUSE,
        ),
        _MediaButton(
          icon: Icons.fast_forward,
          label: l.fastForward,
          keyCode: KeyCodes.KEY_FF,
        ),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.keyCode,
    this.color = Colors.white54,
  });

  final IconData icon;
  final String label;
  final KeyCodes keyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: ControllerButton(
        onPressed: () => context.sendTvKey(keyCode),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
