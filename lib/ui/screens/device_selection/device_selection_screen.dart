import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/connectivity/connectivity_bloc.dart';
import 'package:remote/blocs/device_discovery/device_discovery_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/widgets/device_list_item.dart';
import 'package:remote/ui/screens/device_selection/widgets/manual_ip_dialog.dart';
import 'package:remote/ui/screens/remote_control/remote_screen.dart';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  bool _autoConnectTried = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TvConnectionBloc, TvConnectionState>(
          listenWhen: (prev, next) =>
              prev.status != next.status && next.isConnected,
          listener: (context, _) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
            );
          },
        ),
        BlocListener<DeviceDiscoveryBloc, DeviceDiscoveryState>(
          listenWhen: (prev, next) =>
              !_autoConnectTried &&
              next.lastUsed != null &&
              (next.status == DiscoveryStatus.success ||
                  next.status == DiscoveryStatus.empty),
          listener: (context, state) {
            _autoConnectTried = true;
            final last = state.lastUsed;
            if (last == null) return;
            final conn = context.read<TvConnectionBloc>();
            if (conn.state.status == TvConnectionStatus.idle) {
              conn.add(TvConnectRequested(last));
            }
          },
        ),
      ],
      child: const _DeviceSelectionView(),
    );
  }
}

class _DeviceSelectionView extends StatelessWidget {
  const _DeviceSelectionView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.selectDevice),
        actions: [
          IconButton(
            tooltip: l.addManually,
            icon: const Icon(Icons.add),
            onPressed: () => _onAddManually(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<ConnectivityCubit, ConnectivityStateView>(
            builder: (context, conn) {
              if (!conn.hasLan) {
                return const _WifiOffState();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StatusHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child:
                        BlocBuilder<DeviceDiscoveryBloc, DeviceDiscoveryState>(
                      builder: (_, state) => _DeviceList(state: state),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<DeviceDiscoveryBloc, DeviceDiscoveryState>(
                    builder: (context, state) {
                      final scanning = state.status == DiscoveryStatus.scanning;
                      return ElevatedButton.icon(
                        onPressed: scanning
                            ? null
                            : () => context
                                .read<DeviceDiscoveryBloc>()
                                .add(const DiscoveryRefreshRequested()),
                        icon: const Icon(Icons.refresh),
                        label: Text(l.scanAgain),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onAddManually(BuildContext context) async {
    final result = await ManualIpDialog.show(context);
    if (result == null) return;
    if (!context.mounted) return;
    context.read<DeviceDiscoveryBloc>().add(
          ManualDeviceAdded(
            host: result.host,
            name: result.name,
            brand: result.brand,
          ),
        );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<DeviceDiscoveryBloc>().state;
    final scanning = state.status == DiscoveryStatus.scanning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Icon(
            scanning ? Icons.search : Icons.tv,
            color: scanning ? Colors.blue : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanning ? l.scanning : l.devicesFound,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(l, state),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          if (scanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(AppLocalizations l, DeviceDiscoveryState state) {
    switch (state.status) {
      case DiscoveryStatus.scanning:
        return l.lookingForTvs;
      case DiscoveryStatus.success:
        return l.foundCount(state.devices.length);
      case DiscoveryStatus.empty:
        return l.noDevicesFound;
      case DiscoveryStatus.error:
        return state.errorMessage ?? l.discoveryFailed;
      case DiscoveryStatus.idle:
        return '';
    }
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.state});
  final DeviceDiscoveryState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == DiscoveryStatus.scanning && state.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).lookingForTvs,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (state.devices.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: state.devices.length,
      itemBuilder: (context, index) {
        final device = state.devices[index];
        return DeviceListItem(
          device: device,
          onTap: () => _onTapDevice(context, device),
        );
      },
    );
  }

  void _onTapDevice(BuildContext context, TVDevice device) {
    context.read<TvConnectionBloc>().add(TvConnectRequested(device));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tv_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            l.noDevicesFound,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.noDevicesHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _WifiOffState extends StatelessWidget {
  const _WifiOffState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            l.noWifi,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l.noWifiHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
