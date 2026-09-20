import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/attendance_api.dart';
import '../core/api_client.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _attendanceApi = AttendanceApi(ApiClient.instance);
  late MobileScannerController _controller;
  bool _processing = false;
  double _zoomLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null) return;

    setState(() => _processing = true);
    String message;
    try {
      await _attendanceApi.checkIn(token);
      message = '출석이 완료되었습니다!';
    } catch (e) {
      message = e.toString();
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 체크'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleTorch() {
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 스캔')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '카메라 줌',
                            style: TextStyle(color: Colors.white),
                          ),
                          Slider(
                            value: _zoomLevel,
                            onChanged: (value) async {
                              setState(() => _zoomLevel = value);
                              await _controller.setZoomScale(value);
                            },
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(_zoomLevel * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _toggleTorch,
                  icon: const Icon(Icons.flashlight_on),
                  label: const Text('손전등'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
