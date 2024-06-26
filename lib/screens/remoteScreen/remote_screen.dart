import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:remote/models/samsung_tv.dart';
import 'components/components.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  SmartTV tv = SmartTV();
  bool _keypadShown = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> connectTV() async {
    try {
      tv = await SmartTV.discover();
      await tv.connect();
      setState(() {});
    } catch (e) {
      log(e.toString());
    }
    log("this is the token to save somewere ${tv.token}");
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
              child: NumPad(tv: tv),
            ),
            Visibility(
              visible: !_keypadShown,
              child: DirectionKeys(
                tv: tv,
              ),
            ),
            const SizedBox(height: 50),
            ColorKeys(
              tv: tv,
            ),
            const SizedBox(height: 50),
            VolumeChannelControls(
              tv: tv,
            ),
            const SizedBox(height: 50),
            MediaControls(
              tv: tv,
            ),
          ],
        ),
      ),
    );
  }
}
