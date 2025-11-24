import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/despesa.dart';

class DespesasProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Despesa> _despesas = [];
  List<Despesa> get despesas => _despesas;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Usuário não autenticado.');
    return u.uid;
  }

  DocumentReference get _businessDoc =>
      _firestore.collection('business').doc(_uid);
  CollectionReference get _despesasRef => _businessDoc.collection('despesas');

  Future<void> carregarDespesas() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _despesasRef.orderBy('numero', descending: true).get();
      _despesas = snap.docs.map((d) => Despesa.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Erro carregar despesas: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Despesa> adicionarDespesa(Despesa base) async {
    return await _firestore.runTransaction((tx) async {
      final business = await tx.get(_businessDoc);
      final data = business.data() as Map<String, dynamic>?;
      final novoNumero = (data?['ultimoDespesaNum'] as int? ?? 0) + 1;
      final docRef = _despesasRef.doc();
      final despesa = base.copyWith(
        id: docRef.id,
        numero: novoNumero,
        criadoEm: Timestamp.now(),
        atualizadoEm: Timestamp.now(),
      );
      tx.set(docRef, despesa.toMap());
      tx.update(_businessDoc, {'ultimoDespesaNum': novoNumero});
      _despesas.insert(0, despesa);
      notifyListeners();
      return despesa;
    });
  }

  Future<void> atualizarDespesa(Despesa despesa) async {
    await _despesasRef
        .doc(despesa.id)
        .update(despesa.copyWith(atualizadoEm: Timestamp.now()).toMap());
    final idx = _despesas.indexWhere((d) => d.id == despesa.id);
    if (idx != -1) {
      _despesas[idx] = despesa.copyWith(atualizadoEm: Timestamp.now());
      notifyListeners();
    }
  }

  Future<void> excluirDespesa(String id) async {
    await _despesasRef.doc(id).delete();
    _despesas.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
