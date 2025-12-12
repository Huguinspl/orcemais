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

  // Controle de paginação - carrega apenas os 15 mais recentes inicialmente
  static const int _limitePorPagina = 15;
  bool _temMaisAntigos = false;
  bool get temMaisAntigos => _temMaisAntigos;

  // Flag para indicar se está buscando mais antigos
  bool _buscandoMais = false;
  bool get buscandoMais => _buscandoMais;

  // Total real de recibos no banco de dados
  int _totalRecibos = 0;
  int get totalRecibos => _totalRecibos;

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
      // Busca o total de recibos no banco de dados
      final totalSnapshot = await _recibosRef.count().get();
      _totalRecibos = totalSnapshot.count ?? 0;

      // Carrega apenas os 15 mais recentes + 1 para verificar se há mais
      final snap =
          await _recibosRef
              .orderBy('numero', descending: true)
              .limit(_limitePorPagina + 1)
              .get();

      final docs = snap.docs;

      // Verifica se há mais recibos além dos 15
      if (docs.length > _limitePorPagina) {
        _temMaisAntigos = true;
        _recibos =
            docs
                .take(_limitePorPagina)
                .map((d) => Recibo.fromFirestore(d))
                .toList();
      } else {
        _temMaisAntigos = false;
        _recibos = docs.map((d) => Recibo.fromFirestore(d)).toList();
      }
    } catch (e) {
      debugPrint('Erro carregar recibos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Busca recibos por termo (cliente nome ou número)
  Future<List<Recibo>> buscarRecibos(String termo) async {
    if (termo.isEmpty) return [];

    _buscandoMais = true;
    notifyListeners();

    try {
      // Busca todos os recibos para filtrar localmente
      final snap = await _recibosRef.orderBy('numero', descending: true).get();

      final todosRecibos =
          snap.docs.map((d) => Recibo.fromFirestore(d)).toList();

      // Filtra por nome do cliente ou número do recibo
      final termoLower = termo.toLowerCase();
      final resultados =
          todosRecibos.where((r) {
            final nomeMatch = r.cliente.nome.toLowerCase().contains(termoLower);
            final numeroMatch = r.numero.toString().contains(termo);
            return nomeMatch || numeroMatch;
          }).toList();

      _buscandoMais = false;
      notifyListeners();

      return resultados;
    } catch (e) {
      debugPrint('Erro ao buscar recibos: $e');
      _buscandoMais = false;
      notifyListeners();
      return [];
    }
  }

  /// Carrega todos os recibos (antigos)
  Future<void> carregarTodosRecibos() async {
    _buscandoMais = true;
    notifyListeners();

    try {
      final snap = await _recibosRef.orderBy('numero', descending: true).get();

      _recibos = snap.docs.map((d) => Recibo.fromFirestore(d)).toList();
      _temMaisAntigos = false;
    } catch (e) {
      debugPrint('Erro ao carregar todos recibos: $e');
    }

    _buscandoMais = false;
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
      _totalRecibos++;
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
    _totalRecibos = _totalRecibos > 0 ? _totalRecibos - 1 : 0;
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

  Future<void> atualizarLink(String reciboId, String link) async {
    await _recibosRef.doc(reciboId).update({
      'link': link,
      'atualizadoEm': Timestamp.now(),
    });
    final idx = _recibos.indexWhere((r) => r.id == reciboId);
    if (idx != -1) {
      final r = _recibos[idx];
      _recibos[idx] = r.copyWith(link: link, atualizadoEm: Timestamp.now());
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
