import 'package:flutter/material.dart';
import 'package:remote/models/samsung_tv.dart';
import 'package:remote/screens/remoteScreen/remote_screen.dart';
import 'dart:async';
import 'dart:io';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  List<SmartTV> _availableDevices = [];
  bool _isScanning = false;
  String _scanStatus = '';
  Timer? _wifiCheckTimer;
  bool _wifiConnected = true;

  @override
  void initState() {
    super.initState();
    _startScanning();
    _startWifiMonitoring();
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }

  void _startWifiMonitoring() {
    _wifiCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkWifiConnection();
    });
  }

  Future<void> _checkWifiConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!_wifiConnected) {
          setState(() {
            _wifiConnected = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WiFi reconectado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _startScanning(); // Reiniciar escaneo
        }
      }
    } catch (e) {
      if (_wifiConnected) {
        setState(() {
          _wifiConnected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WiFi desconectado - Verifica tu conexión'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Buscando dispositivos Samsung...';
      _availableDevices.clear();
    });

    try {
      final devices = await SmartTV.discoverAll();
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
        _scanStatus = devices.isEmpty 
            ? 'No se encontraron dispositivos' 
            : 'Se encontraron ${devices.length} dispositivo(s)';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Error al buscar dispositivos';
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
              onPressed: _startScanning,
            ),
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(SmartTV device) async {
    try {
      await device.connect();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RemoteScreen(selectedDevice: device),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Seleccionar Dispositivo',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _isScanning ? Icons.search : Icons.tv,
                    color: _isScanning ? Colors.blue : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isScanning ? 'Escaneando red...' : 'Dispositivos encontrados',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scanStatus,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isScanning)
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
            ),
            
            const SizedBox(height: 24),
            
            // Device list
            Expanded(
              child: !_wifiConnected
                  ? _buildWifiOffState()
                  : _isScanning
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Buscando dispositivos Samsung...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      : _availableDevices.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: _availableDevices.length,
                              itemBuilder: (context, index) {
                                final device = _availableDevices[index];
                                return DeviceListItem(
                                  device: device,
                                  onTap: () => _connectToDevice(device),
                                );
                              },
                            ),
            ),
            
            const SizedBox(height: 16),
            
            // Refresh button
            ElevatedButton.icon(
              onPressed: (!_wifiConnected || _isScanning) ? null : _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('Buscar de nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiOffState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 80,
            color: Colors.red,
          ),
          SizedBox(height: 24),
          Text(
            'WiFi Desconectado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Por favor, conecta tu dispositivo a una red WiFi para buscar televisores Samsung',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          Icon(
            Icons.wifi,
            size: 48,
            color: Colors.white38,
          ),
          SizedBox(height: 8),
          Text(
            'Activa WiFi y vuelve a intentar',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron dispositivos',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica que tu TV Samsung esté encendida\n'
            'y conectada a la misma red WiFi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceListItem extends StatelessWidget {
  final SmartTV device;
  final VoidCallback onTap;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue..withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.tv,
            color: Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          device.deviceName ?? 'TV Samsung',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IP: ${device.host ?? 'Desconocida'}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            if (device.mac != null)
              Text(
                'MAC: ${device.mac}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
