import 'dart:developer';
import 'package:flutter/material.dart';
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
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Conectando a la TV...';
    });

    try {
      await tv.connect();
      
      setState(() {
        _connectionStatus = 'Conectado';
        _isConnecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Conectado exitosamente a ${tv.deviceName ?? 'la TV Samsung'}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
              onPressed: _connectToSelectedDevice,
            ),
          ),
        );
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

  Color _getConnectionColor() {
    if (_isConnecting) return Colors.blue;
    if (_connectionStatus == 'Conectado') return Colors.green;
    if (_connectionStatus == 'Error de conexión') return Colors.red;
    return Colors.grey;
  }

  IconData _getConnectionIcon() {
    if (_isConnecting) return Icons.sync;
    if (_connectionStatus == 'Conectado') return Icons.check_circle;
    if (_connectionStatus == 'Error de conexión') return Icons.error;
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