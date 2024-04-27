import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/models/samsung_tv.dart';
import 'package:remote/screens/remoteScreen/components/controller_button.dart';

class DirectionKeys extends StatelessWidget {
  final SmartTV tv;
  const DirectionKeys({
    super.key,
    required this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ControllerButton(
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_HOME);
              },
              child: const Text(
                "SMART",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ControllerButton(
              child: const Text(
                "INPUT",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_SOURCE);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ControllerButton(
              child: const Text(
                "BACK",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_RETURN);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ControllerButton(
              child: const Text(
                "EXIT",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_EXT41);
              },
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ControllerButton(
              child: const Text(
                "OK",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_ENTER);
              },
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.6),
            child: ControllerButton(
              borderRadius: 10,
              child: const Icon(Icons.arrow_drop_up,
                  size: 30, color: Colors.white),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_UP);
              },
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.6),
            child: ControllerButton(
              borderRadius: 10,
              child: const Icon(Icons.arrow_drop_down,
                  size: 30, color: Colors.white),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_DOWN);
              },
            ),
          ),
          Align(
            alignment: const Alignment(0.6, 0),
            child: ControllerButton(
              borderRadius: 10,
              child:
                  const Icon(Icons.arrow_right, size: 30, color: Colors.white),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_RIGHT);
              },
            ),
          ),
          Align(
            alignment: const Alignment(-0.7, 0),
            child: ControllerButton(
              borderRadius: 10,
              child:
                  const Icon(Icons.arrow_left, size: 30, color: Colors.white),
              onPressed: () async {
                 await tv.sendKey(KeyCodes.KEY_LEFT);
              },
            ),
          ),
        ],
      ),
    );
  }
}
