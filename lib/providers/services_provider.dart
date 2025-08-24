import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/servico.dart';

class ServicesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Servico> _servicos = [];
  List<Servico> get servicos => List.unmodifiable(_servicos);

  // ✅ CORREÇÃO 1: Adicionar a variável e o getter para o estado de carregamento
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _uid => _auth.currentUser?.uid;

  /// Carrega os serviços da coleção business/{uid}/servicos
  Future<void> carregarServicos() async {
    if (_uid == null) return;

    // ✅ CORREÇÃO 2: Atualizar o estado no início e no fim do carregamento
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('business')
              .doc(_uid)
              .collection('servicos')
              .get();

      // Usando fromDoc que já existe no seu modelo Servico
      _servicos = snapshot.docs.map((doc) => Servico.fromDoc(doc)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar serviços: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona um novo serviço e atualiza a lista localmente
  Future<void> adicionarServico(Servico servico) async {
    if (_uid == null) return;

    try {
      final ref = _firestore
          .collection('business')
          .doc(_uid)
          .collection('servicos');
      final doc = await ref.add(servico.toMap());

      // Cria uma nova instância do serviço com o ID do Firestore
      final novoServicoComId = servico.copyWith(id: doc.id);

      // Otimização: Adiciona na lista local em vez de recarregar tudo
      _servicos.insert(0, novoServicoComId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar serviço: $e');
      rethrow; // Propaga o erro para a UI, se necessário
    }
  }

  /// Atualiza um serviço existente e atualiza a lista localmente
  Future<void> atualizarServico(Servico servico) async {
    if (_uid == null || servico.id.isEmpty) return;

    try {
      await _firestore
          .collection('business')
          .doc(_uid)
          .collection('servicos')
          .doc(servico.id)
          .update(servico.toMap());

      // Otimização: Atualiza na lista local em vez de recarregar tudo
      final index = _servicos.indexWhere((s) => s.id == servico.id);
      if (index != -1) {
        _servicos[index] = servico;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar serviço: $e');
      rethrow;
    }
  }

  /// Exclui um serviço pelo ID e atualiza a lista localmente
  Future<void> excluirServico(String servicoId) async {
    if (_uid == null) return;

    try {
      await _firestore
          .collection('business')
          .doc(_uid)
          .collection('servicos')
          .doc(servicoId)
          .delete();

      // Otimização: Remove da lista local em vez de recarregar tudo
      _servicos.removeWhere((s) => s.id == servicoId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao excluir serviço: $e');
      rethrow;
    }
  }
}
