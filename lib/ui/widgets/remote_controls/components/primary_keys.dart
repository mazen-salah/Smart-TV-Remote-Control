import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/l10n/app_localizations.dart';

class PrimaryKeys extends StatelessWidget {
  const PrimaryKeys({
    required this.onPower,
    required this.onToggleKeypad,
    required this.keypadShown,
    super.key,
  });

  final VoidCallback onPower;
  final VoidCallback onToggleKeypad;
  final bool keypadShown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<TvConnectionBloc>().state;
    final color = _statusColor(state);
    final icon = _statusIcon(state);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isConnecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                _statusLabel(l, state),
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.dialpad,
                size: 30,
                color: keypadShown ? Colors.blue : Colors.white70,
              ),
              onPressed: onToggleKeypad,
              tooltip: l.numericKeypad,
            ),
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.red,
                size: 30,
              ),
              onPressed: onPower,
              tooltip: l.power,
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(TvConnectionState state) {
    switch (state.status) {
      case TvConnectionStatus.connecting:
      case TvConnectionStatus.reconnecting:
        return Colors.blue;
      case TvConnectionStatus.connected:
        return Colors.green;
      case TvConnectionStatus.error:
        return Colors.red;
      case TvConnectionStatus.disconnected:
        return Colors.orange;
      case TvConnectionStatus.idle:
        return Colors.grey;
    }
  }

  IconData _statusIcon(TvConnectionState state) {
    switch (state.status) {
      case TvConnectionStatus.connecting:
      case TvConnectionStatus.reconnecting:
        return Icons.sync;
      case TvConnectionStatus.connected:
        return Icons.check_circle;
      case TvConnectionStatus.error:
        return Icons.error;
      case TvConnectionStatus.disconnected:
        return Icons.wifi_off;
      case TvConnectionStatus.idle:
        return Icons.cast_connected;
    }
  }

  String _statusLabel(AppLocalizations l, TvConnectionState state) {
    switch (state.status) {
      case TvConnectionStatus.connecting:
        return l.connecting;
      case TvConnectionStatus.reconnecting:
        return l.reconnecting;
      case TvConnectionStatus.connected:
        return l.connected;
      case TvConnectionStatus.error:
        return l.connectionError;
      case TvConnectionStatus.disconnected:
        return l.disconnected;
      case TvConnectionStatus.idle:
        return l.idle;
    }
  }
}
