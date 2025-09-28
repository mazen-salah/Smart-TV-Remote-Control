import 'package:flutter/material.dart';
import 'package:remote/models/samsung_tv.dart';

class PrimaryKeys extends StatelessWidget {
  
  final void Function() connectTV;
  final void Function() toggleKeypad;
  final Future<void> Function() handlePowerButton;
  final bool keypadShown;
  final bool isConnecting;
  final String connectionStatus;
  final SmartTV tv;
  const PrimaryKeys({super.key,
    required this.connectTV,
    required this.toggleKeypad,
    required this.handlePowerButton,
    required this.keypadShown,
    required this.isConnecting,
    required this.connectionStatus,
    required this.tv
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConnecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              else
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: _getStatusColor(),
                ),
              const SizedBox(width: 8),
              Text(
                connectionStatus,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.cast,
                size: 30,
                color: isConnecting ? Colors.grey : Colors.cyan,
              ),
              onPressed: isConnecting ? null : connectTV,
              tooltip: 'Conectar TV',
            ),
            IconButton(
              icon: Icon(Icons.dialpad,
                  size: 30, color: keypadShown ? Colors.blue : Colors.white70),
              onPressed: toggleKeypad,
              tooltip: 'Teclado numérico',
            ),
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 30),
              onPressed: handlePowerButton,
              tooltip: 'Encender/Apagar TV',
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (isConnecting) return Colors.blue;
    if (connectionStatus == 'Conectado') return Colors.green;
    if (connectionStatus == 'Error de conexión') return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (connectionStatus == 'Conectado') return Icons.check_circle;
    if (connectionStatus == 'Error de conexión') return Icons.error;
    return Icons.cast_connected;
  }
}
