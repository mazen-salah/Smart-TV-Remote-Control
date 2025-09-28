import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/implementations/samsung_tv.dart';
import 'controller_button.dart';

class VolumeChannelControls extends StatelessWidget {
  final SamsungTV tv;
  const VolumeChannelControls({
    super.key, required this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ControllerButton(
          borderRadius: 15,
          child: Column(
            children: [
              MaterialButton(
                height: 50,
                minWidth: 50,
                shape: const CircleBorder(),
                child: const Icon(Icons.keyboard_arrow_up,
                    size: 20, color: Colors.white54),
                onPressed: () async {
                   await tv.sendKey(KeyCodes.KEY_VOLUP);
                },
              ),
              MaterialButton(
                height: 50,
                minWidth: 80,
                shape: const CircleBorder(),
                child: const Icon(Icons.volume_off,
                    size: 20, color: Colors.white70),
                onPressed: () async {
                   await tv.sendKey(KeyCodes.KEY_MUTE);
                },
              ),
              MaterialButton(
                height: 50,
                minWidth: 50,
                shape: const CircleBorder(),
                child: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: Colors.white54),
                onPressed: () async {
                   await tv.sendKey(KeyCodes.KEY_VOLDOWN);
                },
              ),
            ],
          ),
        ),
        Column(
          children: [
            ControllerButton(
              borderRadius: 15,
              child: Text(
                "menu".toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_HOME);
              },
            ),
            const SizedBox(height: 35),
            ControllerButton(
              borderRadius: 15,
              child: Text(
                "more".toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_MORE);
              },
            ),
          ],
        ),
        ControllerButton(
          borderRadius: 15,
          child: Column(
            children: [
              MaterialButton(
                height: 40,
                minWidth: 40,
                shape: const CircleBorder(),
                child: const Icon(Icons.keyboard_arrow_up,
                    size: 20, color: Colors.white54),
                onPressed: () async {
                   await tv.sendKey(KeyCodes.KEY_CHUP);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('P',
                    style: TextStyle(fontSize: 15, color: Colors.white70)),
              ),
              MaterialButton(
                height: 50,
                minWidth: 80,
                shape: const CircleBorder(),
                child: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: Colors.white54),
                onPressed: () async {
                   await tv.sendKey(KeyCodes.KEY_CHDOWN);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
