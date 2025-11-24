import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cliente.dart';

class ClientsProvider extends ChangeNotifier {
  final List<Cliente> _lista = [];
  List<Cliente> get clientes => List.unmodifiable(_lista);

  /* caminho ≈ business/{uid}/clientes */
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('business')
          .doc(uid)
          .collection('clientes');

  /* ---------------- LEITURA ---------------- */
  Future<void> carregarTodos(String uid) async {
    if (uid.isEmpty) return; // evita path inválido
    final snap = await _col(uid).get();
    _lista
      ..clear()
      ..addAll(snap.docs.map(Cliente.fromDoc));
    notifyListeners();
  }

  /* ---------------- CRIAÇÃO ---------------- */
  Future<void> adicionar(String uid, Cliente c) async {
    // garante que o documento pai business/{uid} exista
    await FirebaseFirestore.instance
        .doc('business/$uid')
        .set({}, SetOptions(merge: true));

    final ref = await _col(uid).add(c.toMap());
    _lista.add(c.copyWith(id: ref.id));
    notifyListeners();
  }

  /* ---------------- ATUALIZAÇÃO ---------------- */
  Future<void> atualizar(String uid, Cliente c) async {
    await _col(uid).doc(c.id).update(c.toMap());
    final idx = _lista.indexWhere((e) => e.id == c.id);
    if (idx != -1) _lista[idx] = c;
    notifyListeners();
  }

  /* ---------------- EXCLUSÃO ---------------- */
  Future<void> excluir(String uid, String id) async {
    await _col(uid).doc(id).delete();
    _lista.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /* ---------------- GET POR ID ---------------- */
  Cliente? porId(String id) {
    try {
      return _lista.firstWhere((e) => e.id == id);
    } catch (_) {
      return null; // não encontrado
    }
  }
}
