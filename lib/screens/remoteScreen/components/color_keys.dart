import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/models/samsung_tv.dart';
import 'package:remote/screens/remoteScreen/components/controller_button.dart';

class ColorKeys extends StatelessWidget {
  final SmartTV tv;

  const ColorKeys({
    super.key,
    required this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: ControllerButton(
            color: Colors.red,
            onPressed: () async {
              await tv.sendKey(KeyCodes.KEY_RED);
            },
          ),
        ),
        SizedBox(
          width: 30,
          height: 30,
          child: ControllerButton(
            color: Colors.green,
            onPressed: () async {
              await tv.sendKey(KeyCodes.KEY_GREEN);
            },
          ),
        ),
        SizedBox(
          width: 30,
          height: 30,
          child: ControllerButton(
            color: Colors.yellow,
            onPressed: () async {
              await tv.sendKey(KeyCodes.KEY_YELLOW);
            },
          ),
        ),
        SizedBox(
          height: 30,
          width: 30,
          child: ControllerButton(
            color: Colors.blue,
            onPressed: () async {
              await tv.sendKey(KeyCodes.KEY_CYAN);
            },
          ),
        ),
      ],
    );
  }
}
