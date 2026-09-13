// Screenshot harness for the README images. Not part of the shipped app.
//
// Run tool/screenshots/capture.sh with a booted iOS simulator. The screen is
// chosen at compile time with --dart-define=SCREEN=picker|remote|dialog.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:remote/blocs/connectivity/connectivity_bloc.dart';
import 'package:remote/blocs/device_discovery/device_discovery_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/di/service_locator.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/device_selection_screen.dart';
import 'package:remote/ui/screens/device_selection/widgets/manual_ip_dialog.dart';
import 'package:remote/ui/theme/app_theme.dart';

const _screen = String.fromEnvironment('SCREEN', defaultValue: 'picker');

final _livingRoom = TVDevice(
  host: '192.168.1.42',
  mac: 'A4:5E:60:1B:9C:2F',
  deviceName: 'Living Room TV',
  modelName: 'QN65Q80C',
  manufacturer: 'Samsung',
);

final _bedroom = TVDevice(
  host: '192.168.1.57',
  mac: '58:FD:B1:7A:03:E4',
  deviceName: 'Bedroom LG',
  modelName: 'OLED55C3',
  manufacturer: 'LG',
);

class _ScreenshotRepository extends TvRepository {
  _ScreenshotRepository({required this.autoConnect})
    : super(
        tokenStorage: sl(),
        knownTvsStorage: sl(),
        wakeOnLanService: sl(),
        mdnsDiscoveryService: sl(),
      );

  final bool autoConnect;

  @override
  Future<List<TVDevice>> discoverAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [_livingRoom, _bedroom];
  }

  @override
  Future<void> connect(
    TVDevice device, {
    void Function(DisconnectionType)? onDisconnected,
  }) async {}

  @override
  Future<void> sendKey(KeyCodes key) async {}

  @override
  Future<void> disconnect() async {}

  @override
  List<TVDevice> knownTvs() => const [];

  @override
  TVDevice? lastUsed() => autoConnect ? _livingRoom : null;
}

class _ScreenshotConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await configureDependencies();

  const screen = _screen;
  debugPrint('screenshot harness: SCREEN=$screen');
  final repository = _ScreenshotRepository(autoConnect: screen == 'remote');

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ConnectivityCubit(connectivity: _ScreenshotConnectivity()),
        ),
        BlocProvider(create: (_) => TvConnectionBloc(repository: repository)),
        BlocProvider(
          create: (_) =>
              DeviceDiscoveryBloc(repository: repository)
                ..add(const DiscoveryStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'Smart TV Remote',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceSelectionScreen(),
      ),
    ),
  );

  if (screen == 'dialog') {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final context = _navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await ManualIpDialog.show(context);
    }
  }
}
