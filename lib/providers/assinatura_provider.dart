import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/assinatura_info.dart';

class AssinaturaProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  AssinaturaInfo? _assinatura;
  AssinaturaInfo? get assinatura => _assinatura;

  String get _uid => _auth.currentUser?.uid ?? '';

  Future<void> carregar() async {
    if (_uid.isEmpty) return;
    final doc = await _db.doc('users/$_uid/meta/assinatura').get();
    if (doc.exists) {
      _assinatura = AssinaturaInfo.fromMap(doc.data()!);
    } else {
      _assinatura = null;
    }
    notifyListeners();
  }

  Future<void> salvar(Uint8List bytes) async {
    if (_uid.isEmpty) return;
    final ref = FirebaseStorage.instance.ref().child(
      'users/$_uid/assinatura.png',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    final info = AssinaturaInfo(url: url, data: DateTime.now());
    await _db.doc('users/$_uid/meta/assinatura').set(info.toMap());
    _assinatura = info;
    notifyListeners();
  }

  Future<void> remover() async {
    if (_uid.isEmpty) return;
    await _db.doc('users/$_uid/meta/assinatura').delete();
    _assinatura = null;
    notifyListeners();
  }
}
