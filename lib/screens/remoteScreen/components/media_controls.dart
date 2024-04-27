import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/models/samsung_tv.dart';
import 'package:remote/screens/remoteScreen/components/controller_button.dart';

class MediaControls extends StatelessWidget {
  final SmartTV tv;
  const MediaControls({
    super.key, required this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ControllerButton(
          child: const Icon(Icons.fast_rewind, size: 20, color: Colors.white54),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_REWIND);
          },
        ),
        ControllerButton(
          child: const Icon(Icons.fiber_manual_record,
              size: 20, color: Colors.red),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_REC);
          },
        ),
        ControllerButton(
          child: const Icon(Icons.play_arrow, size: 20, color: Colors.white54),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_PLAY);
          },
        ),
        ControllerButton(
          child: const Icon(Icons.stop, size: 20, color: Colors.white54),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_STOP);
          },
        ),
        ControllerButton(
          child: const Icon(Icons.pause, size: 20, color: Colors.white54),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_PAUSE);
          },
        ),
        ControllerButton(
          child:
              const Icon(Icons.fast_forward, size: 20, color: Colors.white54),
          onPressed: () async {
             await tv.sendKey(KeyCodes.KEY_FF);
          },
        ),
      ],
    );
  }
}
