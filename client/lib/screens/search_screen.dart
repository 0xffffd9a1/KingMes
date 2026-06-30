import 'package:flutter/material.dart';
import 'package:client/services/auth_service.dart';
import 'package:client/services/contact_service.dart';
import 'package:client/models/contact.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _auth = AuthService();
  final _contactService = ContactService();
  String? _foundKey;
  String? _foundNick;

  void _search() async {
    final nickname = _controller.text.trim();
    if (nickname.isEmpty) return;
    final result = await _auth.searchUser(nickname);
    if (result != null) {
      setState(() {
        _foundKey = result['public_key'];
        _foundNick = result['nickname'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь не найден')));
    }
  }

  void _addContact() async {
    if (_foundKey == null || _foundNick == null) return;
    await _contactService.addContact(Contact(
      publicKey: _foundKey!,
      nickname: _foundNick!,
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск пользователя')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Введите никнейм',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _search, child: const Text('Найти')),
            if (_foundKey != null) ...[
              const SizedBox(height: 16),
              Text('Найден: $_foundNick', style: const TextStyle(color: Colors.white)),
              Text(_foundKey!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _addContact, child: const Text('Добавить в контакты')),
            ]
          ],
        ),
      ),
    );
  }
}