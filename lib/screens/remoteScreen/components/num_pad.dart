import 'package:flutter/material.dart';

import 'controller_button.dart';

class NumPad extends StatelessWidget {
  const NumPad({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ControllerButton(
                child: const Text(
                  "1",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_1);
                },
              ),
              ControllerButton(
                child: const Text(
                  "2",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_2);
                },
              ),
              ControllerButton(
                child: const Text(
                  "3",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // // await tv.sendKey(KeyCodes.KEY_3);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ControllerButton(
                child: const Text(
                  "4",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_4);
                },
              ),
              ControllerButton(
                child: const Text(
                  "5",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_5);
                },
              ),
              ControllerButton(
                child: const Text(
                  "6",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_6);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ControllerButton(
                child: const Text(
                  "7",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_7);
                },
              ),
              ControllerButton(
                child: const Text(
                  "8",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_8);
                },
              ),
              ControllerButton(
                child: const Text(
                  "9",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_9);
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ControllerButton(
                child: Text(
                  "Tools".toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_TOOLS);
                },
              ),
              ControllerButton(
                child: const Text(
                  "0",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_0);
                },
              ),
              ControllerButton(
                child: Text(
                  "guide".toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
                onPressed: () async {
                  // await tv.sendKey(KeyCodes.KEY_GUIDE);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
