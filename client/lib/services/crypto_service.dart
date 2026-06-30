import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class CryptoService {
  /// Генерирует случайные 32-байтовые ключи (временная замена Ed25519)
  static Map<String, String> generateEd25519KeyPair() {
    final random = Random.secure();
    final pubKey = Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
    final privKey = Uint8List.fromList(List.generate(64, (_) => random.nextInt(256)));
    return {
      'publicKey': base64Encode(pubKey),
      'privateKey': base64Encode(privKey),
    };
  }
}