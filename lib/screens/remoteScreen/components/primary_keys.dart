import 'package:flutter/material.dart';

class PrimaryKeys extends StatelessWidget {
  final void Function() connectTV;
  final void Function() toggleKeypad;
  final bool keypadShown;
  const PrimaryKeys(
      {super.key,
      required this.connectTV,
      required this.toggleKeypad,
      required this.keypadShown});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: const Icon(Icons.cast, size: 30, color: Colors.cyan),
          onPressed: connectTV,
        ),
        IconButton(
          icon: Icon(Icons.dialpad,
              size: 30, color: keypadShown ? Colors.blue : Colors.white70),
          onPressed: toggleKeypad,
        ),
        IconButton(
          icon:
              const Icon(Icons.power_settings_new, color: Colors.red, size: 30),
          onPressed: () async {
            // await tv.sendKey(KeyCodes.KEY_POWER);
          },
        ),
      ],
    );
  }
}
