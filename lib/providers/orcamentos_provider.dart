import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/orcamento.dart';

class OrcamentosProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Orcamento> _orcamentos = [];
  List<Orcamento> get orcamentos => _orcamentos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    return user.uid;
  }

  // Referências do Firestore para simplificar o código
  DocumentReference get _businessDocRef =>
      _firestore.collection('business').doc(_uid);
  CollectionReference get _orcamentosRef =>
      _businessDocRef.collection('orcamentos');

  // ✅ IMPLEMENTAÇÃO 1: Lógica de numeração automática com transação
  Future<Orcamento> adicionarOrcamento(Orcamento orcamento) async {
    // Uma transação garante que a leitura do contador e a gravação do novo número
    // aconteçam de forma atômica, evitando números duplicados.
    return await _firestore.runTransaction((transaction) async {
      // 1. Pega os dados do negócio para ler o contador atual
      final businessDoc = await transaction.get(_businessDocRef);
      final ultimoNumero = businessDoc.data() as Map<String, dynamic>?;
      final novoNumero = (ultimoNumero?['ultimoOrcamentoNum'] as int? ?? 0) + 1;

      // 2. Cria a referência para o novo orçamento
      final docRef = _orcamentosRef.doc();

      final novoOrcamento = Orcamento(
        id: docRef.id,
        numero: novoNumero, // Atribui o novo número sequencial
        cliente: orcamento.cliente,
        itens: orcamento.itens,
        subtotal: orcamento.subtotal,
        desconto: orcamento.desconto,
        valorTotal: orcamento.valorTotal,
        status: orcamento.status,
        dataCriacao: orcamento.dataCriacao,
        metodoPagamento: orcamento.metodoPagamento,
        parcelas: orcamento.parcelas,
        laudoTecnico: orcamento.laudoTecnico,
        condicoesContratuais: orcamento.condicoesContratuais,
        garantia: orcamento.garantia,
        informacoesAdicionais: orcamento.informacoesAdicionais,
        fotos: orcamento.fotos, // ✅ ADICIONADO: Inclui as fotos
      );

      // 3. Dentro da mesma transação, salva o novo orçamento e atualiza o contador
      transaction.set(docRef, novoOrcamento.toMap());
      transaction.update(_businessDocRef, {'ultimoOrcamentoNum': novoNumero});

      // Adiciona na lista local para atualização instantânea da UI
      _orcamentos.insert(0, novoOrcamento);
      notifyListeners();

      return novoOrcamento;
    });
  }

  // ✅ IMPLEMENTAÇÃO 2: Novo método para atualizar apenas o status
  Future<void> atualizarStatus(String orcamentoId, String novoStatus) async {
    await _orcamentosRef.doc(orcamentoId).update({'status': novoStatus});

    // Atualiza o item na lista local para a UI refletir a mudança instantaneamente
    final index = _orcamentos.indexWhere((o) => o.id == orcamentoId);
    if (index != -1) {
      final orcamentoAntigo = _orcamentos[index];
      // Cria uma nova instância com o status atualizado
      _orcamentos[index] = Orcamento(
        id: orcamentoAntigo.id,
        numero: orcamentoAntigo.numero,
        cliente: orcamentoAntigo.cliente,
        itens: orcamentoAntigo.itens,
        subtotal: orcamentoAntigo.subtotal,
        desconto: orcamentoAntigo.desconto,
        valorTotal: orcamentoAntigo.valorTotal,
        status: novoStatus, // <-- novo status
        dataCriacao: orcamentoAntigo.dataCriacao,
        metodoPagamento: orcamentoAntigo.metodoPagamento,
        parcelas: orcamentoAntigo.parcelas,
        laudoTecnico: orcamentoAntigo.laudoTecnico,
        condicoesContratuais: orcamentoAntigo.condicoesContratuais,
        garantia: orcamentoAntigo.garantia,
        informacoesAdicionais: orcamentoAntigo.informacoesAdicionais,
        fotos: orcamentoAntigo.fotos, // ✅ ADICIONADO: Mantém as fotos
      );
      notifyListeners();
    }
  }

  Future<void> atualizarOrcamento(Orcamento orcamento) async {
    await _orcamentosRef.doc(orcamento.id).update(orcamento.toMap());
    final index = _orcamentos.indexWhere((o) => o.id == orcamento.id);
    if (index != -1) {
      _orcamentos[index] = orcamento;
      notifyListeners();
    }
  }

  Future<void> excluirOrcamento(String orcamentoId) async {
    await _orcamentosRef.doc(orcamentoId).delete();
    _orcamentos.removeWhere((o) => o.id == orcamentoId);
    notifyListeners();
  }

  Future<void> carregarOrcamentos() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ordena por dataCriacao do mais recente para o mais antigo
      final snapshot =
          await _orcamentosRef.orderBy('dataCriacao', descending: true).get();
      _orcamentos =
          snapshot.docs.map((doc) => Orcamento.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Erro ao carregar orçamentos: $e");
    }
    _isLoading = false;
    notifyListeners();
  }
}
