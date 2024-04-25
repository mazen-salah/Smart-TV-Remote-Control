import 'dart:developer';
import 'package:flutter/material.dart';
import 'components/components.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  //TODO: implement SmartTV class
  // late SmartTV tv;
  bool _keypadShown = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> connectTV() async {
    try {
        // tv = await SmartTV.discover();
        // await tv.connect();
      setState(() {});
    } catch (e) {
      log(e.toString());
    }
    // log("this is the token to save somewere ${tv.token}");
  }

  void toggleKeypad() {
    setState(() {
      _keypadShown = !_keypadShown;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryKeys(
              connectTV: connectTV,
              toggleKeypad: toggleKeypad,
              keypadShown: _keypadShown,
            ),
            const SizedBox(height: 50),
            Visibility(
              visible: _keypadShown,
              child: NumPad(),
            ),
            Visibility(
              visible: !_keypadShown,
              child: DirectionKeys(),
            ),
            const SizedBox(height: 50),
            ColorKeys(),
            const SizedBox(height: 50),
            VolumeChannelControls(),
            const SizedBox(height: 50),
            MediaControls(),
          ],
        ),
      ),
    );
  }
}
