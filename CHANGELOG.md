# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-09-13

### Changed
- **LG webOS client rewritten against the current protocol.** Connects to
  `wss://<ip>:3001` first (required by firmware since January 2023) and
  falls back to `ws://<ip>:3000` for older sets; registers with LG's signed
  sample manifest and retries unsigned if rejected; drives navigation,
  colour, digit, mute, volume and channel keys through the pointer input
  socket and transport keys through `media.controls`. Mute now toggles.
  The TV's self-signed certificate is pinned on first pairing and the saved
  client key is only ever sent over that pinned TLS connection; the
  plaintext fallback for pre-2018 sets asks the TV to pair again instead.
  Still untested on hardware (#9).
- **Discovery rebuilt on the platform service browsers.** mDNS now uses
  `bonsoir` (Bonjour on iOS, NSD on Android) instead of raw multicast
  sockets, which never worked on a real iPhone without Apple's restricted
  multicast entitlement. SSDP moved out of the Samsung service into
  `SsdpDiscoveryService`, recognises LG webOS responders, skips non-TV
  devices before fetching their description, and holds an Android
  `MulticastLock` (new method channel in `MainActivity`) so replies are
  actually delivered. AirPlay and Cast TXT records are used to identify
  Samsung and LG sets; other devices are no longer listed.
- Dart SDK floor raised to 3.8 (required by `bonsoir`); sources reformatted
  for the 3.8 formatter style.

### Added
- Per-ABI release APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`, ~15-19 MB)
  next to the universal build, produced by a tag-triggered release
  workflow that signs from repository secrets.
- CI builds iOS (no code signing) on every push.
- `PRIVACY.md` and `docs/protocols.md` (Samsung WSS v2, LG webOS, SSDP,
  Bonjour, Wake-on-LAN).

## [0.3.0] - 2026-09-13

### Added
- **LG WebOS is now wired into the app.** The repository picks the LG client
  for devices tagged `LG` by mDNS, and the manual-IP dialog has a brand
  selector so an LG set can be added by address. The LG client key is
  persisted like the Samsung token. Not yet verified on real hardware —
  testers wanted.
- **Localized UI.** Every string in the picker, dialog and remote now comes
  from the ARB files (English, Spanish, Arabic) instead of hardcoded text.
- **Screenshots** in the README, plus `tool/screenshots/` to regenerate them.
- Community files: `CODE_OF_CONDUCT.md`, `SECURITY.md`, Dependabot config.
- First signed Android APK published on the GitHub Releases page.

### Changed
- Application id is now `com.summationworks.smarttvremote` on every platform
  (was the Flutter template default `com.example.remote`).
- `analysis_options.yaml` and `pubspec.lock` are committed; CI now fails on
  test failures instead of ignoring them, and runs on Flutter 3.47.
- Discovery copy no longer says "Samsung TVs" when scanning for all brands.

### Fixed
- Source formatting, which had failed the CI format check since 0.2.0.

## [0.2.0] - 2026-05-25

Major rewrite. The app moves from a single-screen prototype to a layered
Flutter architecture with real protocol support for two TV brands.

### Added
- **State management & DI**: introduced `flutter_bloc` + `get_it` with a
  repository pattern. New blocs under `lib/blocs/`:
  - `TvConnectionBloc` — owns the active TV session
  - `DeviceDiscoveryBloc` — drives the network scan
  - `ConnectivityCubit` — exposes real network state
- **Samsung Tizen WebSocket v2** client in
  `lib/services/samsung/samsung_tv_service.dart` with `wss://` transport
  and native `pingInterval`-based heartbeat.
- **LG WebOS** client in `lib/services/lg/lg_tv_service.dart` (replaces
  the prior stub) with client-key pairing.
- **mDNS discovery** (`lib/services/mdns/mdns_discovery_service.dart`)
  running in parallel with UPnP.
- **Samsung token persistence** via `TvTokenStorage` — the on-TV
  "Allow" popup now appears only on the first connect.
- **Known-TV memory** via `KnownTvsStorage` with auto-connect to the
  last used set on launch.
- **Wake-on-LAN** fallback: refused connections trigger a magic packet
  and one retry.
- **Manual IP entry** dialog as a discovery fallback.
- **Real connectivity** via `connectivity_plus` (replaces DNS polling).
- **i18n scaffold** with ARB files in `lib/l10n/` for English, Spanish,
  and Arabic.
- **Accessibility**: haptic feedback and `Semantics` labels on every
  remote button.
- **Material 3 dark theme**.

### Changed
- Discovery is no longer Samsung-only; UPnP and mDNS run in parallel
  and feed a unified device list.
- TV control is now brand-agnostic at the repository layer; UI does
  not know whether it is talking to Samsung or LG.

### Removed
- Manual 5 s / 500 ms polling timers used for the previous heartbeat.
- DNS-poll-based "is the internet up" check.
- Hard-coded Samsung-only assumptions in the UI layer.

### Fixed
- Reconnect loops after the TV slept (now handled by WoL + retry).
- "Allow" popup re-appearing on every connect (token is now persisted).

## [0.1.0] - 2025-11-01

### Added
- Initial release.
- Samsung TV discovery via UPnP.
- Basic on-screen remote (power, volume, channel, D-pad).
- Single-screen Flutter UI.

[Unreleased]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/releases/tag/v0.1.0
