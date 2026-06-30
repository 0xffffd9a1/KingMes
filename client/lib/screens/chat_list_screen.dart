import 'package:flutter/material.dart';
import 'package:client/services/storage_service.dart';
import 'package:client/services/contact_service.dart';
import 'package:client/models/contact.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ContactService _contactService = ContactService();
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactService.getContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              final added = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              if (added == true) _loadContacts();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'show_key') {
                final key = await StorageService().getPublicKey();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Ваш публичный ключ'),
                    content: Text(key ?? 'не найден'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОК'))],
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'show_key', child: Text('Показать ключ')),
            ],
          ),
        ],
      ),
      body: _contacts.isEmpty
          ? const Center(child: Text('Нет контактов', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  title: Text(contact.nickname, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(contact.publicKey.substring(0, 12) + '...', style: const TextStyle(color: Colors.white38)),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      peerPublicKey: contact.publicKey,
                      peerNickname: contact.nickname,
                    )));
                  },
                );
              },
            ),
    );
  }
}