import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:client/models/contact.dart';

class ContactService {
  final _storage = const FlutterSecureStorage();
  static const _contactsKey = 'contacts';

  Future<List<Contact>> getContacts() async {
    final raw = await _storage.read(key: _contactsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Contact(
          publicKey: e['publicKey'],
          nickname: e['nickname'],
        )).toList();
  }

  Future<void> addContact(Contact contact) async {
    final contacts = await getContacts();
    contacts.add(contact);
    await _storage.write(key: _contactsKey, value: jsonEncode(
      contacts.map((c) => {
            'publicKey': c.publicKey,
            'nickname': c.nickname,
          }).toList(),
    ));
  }
}