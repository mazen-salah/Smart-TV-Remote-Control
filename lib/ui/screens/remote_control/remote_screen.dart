import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/components.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _keypadShown = false;

  void _toggleKeypad() => setState(() => _keypadShown = !_keypadShown);

  Future<void> _handlePower(BuildContext context) async {
    context.sendTvKey(KeyCodes.KEY_POWER);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) return;
    context.read<TvConnectionBloc>().add(const TvDisconnectRequested());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TvConnectionBloc, TvConnectionState>(
      listenWhen: (p, n) => p.status != n.status,
      listener: (context, state) {
        final l = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        switch (state.status) {
          case TvConnectionStatus.error:
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? l.connectionError),
                backgroundColor: Colors.red,
              ),
            );
          case TvConnectionStatus.disconnected:
            if (state.disconnectionType != DisconnectionType.userInitiated) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    l.disconnectedReason(
                      state.disconnectionType?.displayName ?? l.unknown,
                    ),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          case _:
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<TvConnectionBloc, TvConnectionState>(
            builder: (context, state) => Text(
              state.device?.displayName ?? AppLocalizations.of(context).remote,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: AppLocalizations.of(context).reconnect,
              onPressed: () {
                final device = context.read<TvConnectionBloc>().state.device;
                if (device != null) {
                  context
                      .read<TvConnectionBloc>()
                      .add(TvConnectRequested(device));
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryKeys(
                  onPower: () => _handlePower(context),
                  onToggleKeypad: _toggleKeypad,
                  keypadShown: _keypadShown,
                ),
                const SizedBox(height: 50),
                if (_keypadShown) const NumPad() else const DirectionKeys(),
                const SizedBox(height: 50),
                const ColorKeys(),
                const SizedBox(height: 50),
                const VolumeChannelControls(),
                const SizedBox(height: 50),
                const MediaControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
