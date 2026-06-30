import 'dart:async';
import 'package:flutter/material.dart';
import 'package:client/services/websocket_service.dart';
import 'package:client/services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerPublicKey;
  final String peerNickname;
  const ChatScreen({super.key, required this.peerPublicKey, required this.peerNickname});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final WebSocketService _ws = WebSocketService();
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _subscription;
  String? _pendingRequestId;

  @override
  void initState() {
    super.initState();
    _subscription = _ws.messageStream.listen(_handleMessage);
    _loadHistory();
  }

  void _handleMessage(Map<String, dynamic> msg) {
    if (msg['action'] == 'new_message') {
      final data = msg['data'];
      if (data['sender'] == widget.peerPublicKey) {
        setState(() {
          _messages.add({
            'content': data['content'],
            'sender': data['sender'],
            'timestamp': data['timestamp']?.toString() ?? '',
          });
        });
      }
    } else if (msg['action'] == 'messages' && msg['request_id'] == _pendingRequestId) {
      final List<dynamic> msgs = msg['data'];
      setState(() {
        _messages = msgs.map((m) => Map<String, dynamic>.from(m)).toList();
      });
      _pendingRequestId = null;
    }
  }

  Future<void> _loadHistory() async {
    _pendingRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    _ws.send({
      'action': 'get_messages',
      'data': {'peer_key': widget.peerPublicKey},
      'request_id': _pendingRequestId,
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final myKey = await _storage.getPublicKey();
    if (myKey == null) return;
    _ws.send({
      'action': 'send_message',
      'data': {
        'receiver': widget.peerPublicKey,
        'content': text,
      },
    });
    setState(() {
      _messages.add({
        'sender': myKey,
        'content': text,
        'timestamp': DateTime.now().toString(),
      });
    });
    _msgController.clear();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerNickname)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] != widget.peerPublicKey;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['content'] ?? '', style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Сообщение',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
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