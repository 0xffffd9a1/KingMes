import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveKeys(String publicKey, String privateKey) async {
    await _storage.write(key: 'public_key', value: publicKey);
    await _storage.write(key: 'private_key', value: privateKey);
  }

  Future<String?> getPublicKey() => _storage.read(key: 'public_key');
  Future<String?> getPrivateKey() => _storage.read(key: 'private_key');
}