import 'package:flutter/material.dart';
import 'package:client/services/auth_service.dart';
import 'package:client/services/websocket_service.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nickController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _needRegistration = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Подключаем WebSocket
    await WebSocketService().connect('ws://localhost:8080/ws');
    final registered = await _auth.isRegistered();
    if (registered) {
      // Пробуем аутентифицироваться
      await _auth.authenticate();
      // Ждём ответ auth
      final sub = WebSocketService().messageStream.listen((msg) {
        if (msg['status'] == 'ok' && msg['message'] == 'authenticated') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
        }
      });
      // Таймаут? Пока для простоты
    } else {
      setState(() {
        _loading = false;
        _needRegistration = true;
      });
    }
  }

  Future<void> _register() async {
    final nick = _nickController.text.trim();
    if (nick.isEmpty) return;
    await _auth.register(nick);
    // После регистрации сразу авторизуемся
    await _auth.authenticate();
    // Слушаем подтверждение
    final sub = WebSocketService().messageStream.listen((msg) {
      if (msg['status'] == 'ok' && msg['message'] == 'authenticated') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
      } else if (msg['status'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${msg['message']}')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF121220),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('AnonyMessenger', style: TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 32),
              if (_needRegistration) ...[
                TextField(
                  controller: _nickController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Придумайте никнейм',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Зарегистрироваться'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}