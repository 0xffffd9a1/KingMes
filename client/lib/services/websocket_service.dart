import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _channel!.stream.listen(
        (data) {
          if (data is String) {
            final message = jsonDecode(data) as Map<String, dynamic>;
            _messageController.add(message);
          }
        },
        onDone: () => print('WebSocket closed'),
        onError: (error) => print('WebSocket error: $error'),
      );
      print('Connected to $url');
    } catch (e) {
      print('Connection error: $e');
    }
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}