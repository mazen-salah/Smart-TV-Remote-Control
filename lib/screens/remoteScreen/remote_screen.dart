import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/models/samsung_tv.dart';
import 'package:remote/screens/device_selection_screen.dart';
import 'components/components.dart';

class RemoteScreen extends StatefulWidget {
  final SmartTV? selectedDevice;
  
  const RemoteScreen({super.key, this.selectedDevice});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  SmartTV tv = SmartTV();
  bool _keypadShown = false;
  bool _isConnecting = false;
  String _connectionStatus = 'No conectado';

  @override
  void initState() {
    super.initState();
    if (widget.selectedDevice != null) {
      tv = widget.selectedDevice!;
      // Configurar callback de desconexión
      tv.setOnDisconnectedCallback(_handleDisconnection);
      
      // Si el dispositivo ya está conectado, actualizar el estado
      if (tv.isConnected) {
        setState(() {
          _connectionStatus = 'Conectado';
          _isConnecting = false;
        });
      } else {
        _connectToSelectedDevice();
      }
    }
  }


  Future<void> _connectToSelectedDevice() async {
    log('_connectToSelectedDevice called - attempting reconnection...');
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Conectando a la TV...';
    });

    try {
      // Configurar callback de desconexión antes de conectar
      tv.setOnDisconnectedCallback(_handleDisconnection);
      
      // Try to connect directly
      await tv.connect();
      
      setState(() {
        _connectionStatus = 'Conectado';
        _isConnecting = false;
      });
      
      log('Reconnection successful - TV is now connected');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Reconectado exitosamente a ${tv.deviceName ?? 'la TV Samsung'}! El TV se ha encendido automáticamente.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      log('Reconnection failed: $e');
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Error de conexión';
      });
      
      if (mounted) {
        // Check if it's a connection refused error (TV is off)
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('errno = 111')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('El TV está apagado. Por favor, enciéndelo manualmente y vuelve a intentar.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _connectToSelectedDevice,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al reconectar: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _connectToSelectedDevice,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> connectTV() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Buscando TVs Samsung...';
    });

    try {
      tv = await SmartTV.discover();
      setState(() {
        _connectionStatus = 'Conectando a la TV...';
      });
      
      await tv.connect();
      
      setState(() {
        _connectionStatus = 'Conectado';
        _isConnecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Conectado exitosamente a la TV Samsung!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Error de conexión';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: connectTV,
            ),
          ),
        );
      }
    }
    
    log("this is the token to save somewere ${tv.token}");
  }

  void toggleKeypad() => setState(() => _keypadShown = ! _keypadShown);

  Future<void> _handlePowerButton() async {
    log('Power button pressed - turning off TV and redirecting...');
    
    try {
      // Send the power command
      await tv.sendKey(KeyCodes.KEY_POWER);
      log('Power command sent successfully');
      
      // Wait a moment for the command to be sent
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close connection immediately
      tv.disconnect();
      log('Connection closed after power command');
      
      // Redirect immediately
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSelectionScreen(),
          ),
        );
      }
      
    } catch (e) {
      log('Error sending power command: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar comando: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleDisconnection(DisconnectionType disconnectionType) {
    log('_handleDisconnection called in UI with type: $disconnectionType');
    log('Widget mounted: $mounted');
    log('Currently connecting: $_isConnecting');
    
    if (mounted) {
      // Si estamos en proceso de reconexión, no mostrar alertas
      if (_isConnecting) {
        log('Currently reconnecting, ignoring disconnection event');
        return;
      }
      
      log('Handling disconnection in UI: $disconnectionType');
      setState(() {
        _connectionStatus = 'Desconectado';
        _isConnecting = false;
      });
      
      if (disconnectionType == DisconnectionType.wifiDisconnected) {
        // WiFi desconectado - mostrar alerta inmediata
        log('Showing WiFi disconnection alert');
        _showWifiDisconnectionAlert();
      } else {
        // Otras desconexiones - redirigir directamente
        log('Redirecting to device selection screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSelectionScreen(),
          ),
        );
      }
    } else {
      log('Widget not mounted, cannot handle disconnection');
    }
  }

  void _showWifiDisconnectionAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('WiFi desconectado - Verifica tu conexión a internet'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Reconectar',
          textColor: Colors.white,
          onPressed: _connectToSelectedDevice,
        ),
      ),
    );
    
    // Navegar inmediatamente a selección de dispositivos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceSelectionScreen(),
          ),
        );
      }
    });
  }

  Color _getConnectionColor() {
    if (_isConnecting) return Colors.blue;
    if (_connectionStatus == 'Conectado') return Colors.green;
    if (_connectionStatus == 'Error de conexión') return Colors.red;
    if (_connectionStatus == 'Desconectado') return Colors.orange;
    return Colors.grey;
  }

  IconData _getConnectionIcon() {
    if (_isConnecting) return Icons.sync;
    if (_connectionStatus == 'Conectado') return Icons.check_circle;
    if (_connectionStatus == 'Error de conexión') return Icons.error;
    if (_connectionStatus == 'Desconectado') return Icons.wifi_off;
    return Icons.cast_connected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF2e2e2e),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Expanded(
              child: Text(
                tv.deviceName ?? 'Control Remoto',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConnectionColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getConnectionColor(), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConnectionIcon(),
                    size: 12,
                    color: _getConnectionColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _getConnectionColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DeviceSelectionScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _connectToSelectedDevice,
            tooltip: 'Reconectar',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryKeys(
                connectTV: connectTV,
                toggleKeypad: toggleKeypad,
                handlePowerButton: _handlePowerButton,
                keypadShown: _keypadShown,
                isConnecting: _isConnecting,
                connectionStatus: _connectionStatus,
                tv: tv,
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
      ),
    );
  }
}