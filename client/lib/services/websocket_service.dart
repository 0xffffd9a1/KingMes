import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    await _channel!.ready;
    _channel!.stream.listen(
      (data) {
        if (data is String) {
          final msg = jsonDecode(data) as Map<String, dynamic>;
          _messageController.add(msg);
        }
      },
      onDone: () {
        _channel = null;
      },
      onError: (error) => print('WebSocket error: $error'),
    );
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
  }
}