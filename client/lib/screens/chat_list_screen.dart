import 'package:flutter/material.dart';
import 'package:client/services/websocket_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    // Подключаемся к серверу при старте
    _wsService.connect('ws://localhost:8080/ws');
    // Слушаем входящие сообщения от сервера
    _wsService.messageStream.listen((msg) {
      setState(() {
        _messages.add('Ответ сервера: ${msg['text'] ?? msg.toString()}');
      });
    });
  }

  @override
  void dispose() {
    _wsService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _wsService.send({'text': text});
      setState(() {
        _messages.add('Я: $text');
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест WebSocket'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  _messages[index],
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}