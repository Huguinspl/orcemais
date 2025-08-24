import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/recibo.dart';
import '../models/valor_recebido.dart';

class RecibosProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Recibo> _recibos = [];
  List<Recibo> get recibos => _recibos;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Usuário não autenticado.');
    return u.uid;
  }

  DocumentReference get _businessDoc =>
      _firestore.collection('business').doc(_uid);
  CollectionReference get _recibosRef => _businessDoc.collection('recibos');

  Future<void> carregarRecibos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _recibosRef.orderBy('numero', descending: true).get();
      _recibos = snap.docs.map((d) => Recibo.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Erro carregar recibos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Recibo> adicionarRecibo(Recibo base) async {
    return await _firestore.runTransaction((tx) async {
      final business = await tx.get(_businessDoc);
      final data = business.data() as Map<String, dynamic>?;
      final novoNumero = (data?['ultimoReciboNum'] as int? ?? 0) + 1;
      final docRef = _recibosRef.doc();
      final recibo = base.copyWith(
        id: docRef.id,
        numero: novoNumero,
        criadoEm: Timestamp.now(),
        atualizadoEm: Timestamp.now(),
      );
      tx.set(docRef, recibo.toMap());
      tx.update(_businessDoc, {'ultimoReciboNum': novoNumero});
      _recibos.insert(0, recibo);
      notifyListeners();
      return recibo;
    });
  }

  Future<void> atualizarRecibo(Recibo recibo) async {
    await _recibosRef
        .doc(recibo.id)
        .update(recibo.copyWith(atualizadoEm: Timestamp.now()).toMap());
    final idx = _recibos.indexWhere((r) => r.id == recibo.id);
    if (idx != -1) {
      _recibos[idx] = recibo.copyWith(atualizadoEm: Timestamp.now());
      notifyListeners();
    }
  }

  Future<void> excluirRecibo(String id) async {
    await _recibosRef.doc(id).delete();
    _recibos.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> atualizarStatus(String reciboId, String novoStatus) async {
    await _recibosRef.doc(reciboId).update({'status': novoStatus});
    final idx = _recibos.indexWhere((r) => r.id == reciboId);
    if (idx != -1) {
      final r = _recibos[idx];
      _recibos[idx] = r.copyWith(
        status: novoStatus,
        atualizadoEm: Timestamp.now(),
      );
      notifyListeners();
    }
  }

  // Helpers para (re)calcular valores
  Recibo recalcular(Recibo recibo) {
    final subtotalItens = recibo.itens.fold<double>(0, (acc, item) {
      final preco = (item['preco'] ?? 0).toDouble();
      final qtd = (item['quantidade'] ?? 1).toDouble();
      return acc + preco * qtd;
    });
    final totalValoresRecebidos = recibo.valoresRecebidos.fold<double>(
      0,
      (a, v) => a + v.valor,
    );
    final valorTotal =
        subtotalItens > 0 ? subtotalItens : totalValoresRecebidos;
    return recibo.copyWith(
      subtotalItens: subtotalItens,
      totalValoresRecebidos: totalValoresRecebidos,
      valorTotal: valorTotal,
    );
  }

  Future<void> adicionarValorRecebido(String reciboId, ValorRecebido vr) async {
    final idx = _recibos.indexWhere((r) => r.id == reciboId);
    if (idx == -1) return;
    final r = _recibos[idx];
    final atualizado = recalcular(
      r.copyWith(valoresRecebidos: [...r.valoresRecebidos, vr]),
    );
    await _recibosRef.doc(reciboId).update(atualizado.toMap());
    _recibos[idx] = atualizado;
    notifyListeners();
  }

  Future<void> substituirItens(
    String reciboId,
    List<Map<String, dynamic>> itens,
  ) async {
    final idx = _recibos.indexWhere((r) => r.id == reciboId);
    if (idx == -1) return;
    final r = _recibos[idx];
    final atualizado = recalcular(r.copyWith(itens: itens));
    await _recibosRef.doc(reciboId).update(atualizado.toMap());
    _recibos[idx] = atualizado;
    notifyListeners();
  }
}
