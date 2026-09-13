import 'package:get_it/get_it.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:remote/core/services/multicast_lock.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:remote/core/services/wake_on_lan_service.dart';
import 'package:remote/services/mdns/bonjour_discovery_service.dart';
import 'package:remote/services/upnp/ssdp_discovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<TvTokenStorage>(() => TvTokenStorage(sl()))
    ..registerLazySingleton<KnownTvsStorage>(() => KnownTvsStorage(sl()))
    ..registerLazySingleton<WakeOnLanService>(WakeOnLanService.new)
    ..registerLazySingleton<MulticastLock>(MulticastLock.new)
    ..registerLazySingleton<SsdpDiscoveryService>(
      () => SsdpDiscoveryService(multicastLock: sl()),
    )
    ..registerLazySingleton<BonjourDiscoveryService>(
      BonjourDiscoveryService.new,
    )
    ..registerLazySingleton<TvRepository>(
      () => TvRepository(
        tokenStorage: sl(),
        knownTvsStorage: sl(),
        wakeOnLanService: sl(),
        ssdpDiscoveryService: sl(),
        bonjourDiscoveryService: sl(),
      ),
    );
}
