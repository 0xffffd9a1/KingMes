import 'dart:async';
import 'package:client/services/crypto_service.dart';
import 'package:client/services/storage_service.dart';
import 'package:client/services/websocket_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final WebSocketService _ws = WebSocketService();

  Future<bool> isRegistered() async {
    final key = await _storage.getPublicKey();
    return key != null;
  }

  Future<String?> getPublicKey() => _storage.getPublicKey();

  Future<void> register(String nickname) async {
    final keys = CryptoService.generateEd25519KeyPair();
    final pubKey = keys['publicKey']!;
    final privKey = keys['privateKey']!;
    await _storage.saveKeys(pubKey, privKey);

    _ws.send({
      'action': 'register',
      'data': {
        'public_key': pubKey,
        'nickname': nickname,
      },
    });
  }

  Future<void> authenticate() async {
    final pubKey = await _storage.getPublicKey();
    if (pubKey != null) {
      _ws.send({
        'action': 'auth',
        'data': {'public_key': pubKey},
      });
    }
  }

  Future<Map<String, String>?> searchUser(String nickname) async {
    final completer = Completer<Map<String, String>?>();
    final sub = _ws.messageStream.listen((msg) {
      if (msg['action'] == 'search_result') {
        final data = msg['data'];
        completer.complete(Map<String, String>.from(data));
      } else if (msg['status'] == 'error') {
        completer.complete(null);
      }
    });
    _ws.send({
      'action': 'search_user',
      'data': {'nickname': nickname},
    });
    try {
      return await completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    } finally {
      sub.cancel();
    }
  }
}