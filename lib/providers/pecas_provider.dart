import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/peca_material.dart';

class PecasProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PecaMaterial> _itens = [];
  List<PecaMaterial> get itens => List.unmodifiable(_itens);

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    if (_uid == null)
      throw Exception('Usuário não autenticado para acessar a coleção.');
    return _firestore
        .collection('business')
        .doc(_uid)
        .collection('pecas_materiais');
  }

  Future<void> fetchPecas() async {
    if (_uid == null) return;
    final snapshot = await _collection.get();
    _itens =
        snapshot.docs
            .map((doc) => PecaMaterial.fromFirestore(doc.data(), doc.id))
            .toList();
    notifyListeners();
  }

  Future<void> addPeca(PecaMaterial peca) async {
    if (_uid == null) return;

    // Adiciona o UID do usuário ao objeto antes de salvar
    final pecaComUid = peca.copyWith(uid: _uid);
    final docRef = await _collection.add(pecaComUid.toMap());

    // ✅ CORREÇÃO: Usando copyWith para garantir que todos os campos sejam mantidos
    // e o novo ID seja adicionado.
    final novaPecaComId = pecaComUid.copyWith(id: docRef.id);

    _itens.insert(0, novaPecaComId);
    notifyListeners();
  }

  Future<void> atualizarPeca(String id, PecaMaterial dados) async {
    if (_uid == null) return;

    // Garante que o UID esteja nos dados a serem atualizados
    final pecaComUid = dados.copyWith(uid: _uid);
    await _collection.doc(id).update(pecaComUid.toMap());

    final index = _itens.indexWhere((p) => p.id == id);
    if (index != -1) {
      // ✅ CORREÇÃO: Substitui o item antigo pelo novo, garantindo que todos
      // os campos (incluindo os novos) sejam atualizados na lista local.
      _itens[index] = pecaComUid.copyWith(id: id);
      notifyListeners();
    }
  }

  Future<void> deletePeca(String id) async {
    if (_uid == null) return;
    await _collection.doc(id).delete();
    _itens.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
