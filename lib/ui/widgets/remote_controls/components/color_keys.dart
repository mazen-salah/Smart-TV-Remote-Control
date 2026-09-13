import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/controller_button.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class ColorKeys extends StatelessWidget {
  const ColorKeys({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ColorButton(
          color: Colors.red,
          label: l.redButton,
          keyCode: KeyCodes.KEY_RED,
        ),
        _ColorButton(
          color: Colors.green,
          label: l.greenButton,
          keyCode: KeyCodes.KEY_GREEN,
        ),
        _ColorButton(
          color: Colors.yellow,
          label: l.yellowButton,
          keyCode: KeyCodes.KEY_YELLOW,
        ),
        _ColorButton(
          color: Colors.blue,
          label: l.blueButton,
          keyCode: KeyCodes.KEY_CYAN,
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.label,
    required this.keyCode,
  });

  final Color color;
  final String label;
  final KeyCodes keyCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Semantics(
        label: label,
        button: true,
        child: ControllerButton(
          color: color,
          onPressed: () => context.sendTvKey(keyCode),
        ),
      ),
    );
  }
}
