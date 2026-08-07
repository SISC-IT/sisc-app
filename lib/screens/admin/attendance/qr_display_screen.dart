import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api_client.dart';
import '../../../core/config.dart';

class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key, required this.roundId, required this.roundName});

  final String roundId;
  final String roundName;

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  StreamSubscription<SSEModel>? _subscription;
  String? _token;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final uri = Uri.parse(apiBaseUrl);
    final cookies = await ApiClient.instance.cookieJar.loadForRequest(uri);
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    final stream = SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '$apiBaseUrl/api/attendance/rounds/${widget.roundId}/qr-stream',
      header: {
        'Cookie': cookieHeader,
        'Accept': 'text/event-stream',
      },
    );
    _subscription = stream.listen(
      (event) {
        if (event.event != 'qrToken') return;
        try {
          final data = jsonDecode((event.data ?? '').trim()) as Map<String, dynamic>;
          setState(() {
            _token = data['qrToken'] as String?;
            _errorMessage = null;
          });
        } catch (_) {
          // 파싱 실패한 이벤트(ping 등)는 무시한다.
        }
      },
      onError: (Object error) {
        setState(() => _errorMessage = 'QR 스트림 연결에 실패했습니다.');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR 코드 · ${widget.roundName}')),
      body: Center(
        child: _errorMessage != null
            ? Text(_errorMessage!)
            : _token == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(data: _token!, size: 280),
                  const SizedBox(height: 16),
                  const Text('약 3분마다 자동으로 갱신됩니다.', style: TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}
