import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote/screens/remoteScreen/remote_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  return runApp(const RemoteController());
}

class RemoteController extends StatelessWidget {
  const RemoteController({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remote',
      home: Scaffold(
        backgroundColor: Color(0XFF2e2e2e),
        body: RemoteScreen(),
      ),
    );
  }
}
