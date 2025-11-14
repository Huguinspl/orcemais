import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/checklist.dart';

class ChecklistsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Checklist> _checklists = [];
  bool _carregando = false;

  List<Checklist> get checklists => [..._checklists];
  bool get carregando => _carregando;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> carregarChecklists() async {
    if (_userId.isEmpty) return;

    _carregando = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('usuarios')
              .doc(_userId)
              .collection('checklists')
              .orderBy('criadoEm', descending: true)
              .get();

      _checklists =
          snapshot.docs
              .map((doc) => Checklist.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
    } catch (e) {
      debugPrint('Erro ao carregar checklists: $e');
      _checklists = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<String?> criarChecklist(Checklist checklist) async {
    if (_userId.isEmpty) return null;

    try {
      final docRef = await _firestore
          .collection('usuarios')
          .doc(_userId)
          .collection('checklists')
          .add(checklist.toMap());

      final novoChecklist = checklist.copyWith(id: docRef.id);
      _checklists.insert(0, novoChecklist);
      notifyListeners();

      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao criar checklist: $e');
      return null;
    }
  }

  Future<bool> atualizarChecklist(Checklist checklist) async {
    if (_userId.isEmpty) return false;

    try {
      await _firestore
          .collection('usuarios')
          .doc(_userId)
          .collection('checklists')
          .doc(checklist.id)
          .update({...checklist.toMap(), 'atualizadoEm': Timestamp.now()});

      final index = _checklists.indexWhere((c) => c.id == checklist.id);
      if (index != -1) {
        _checklists[index] = checklist.copyWith(atualizadoEm: Timestamp.now());
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar checklist: $e');
      return false;
    }
  }

  Future<bool> excluirChecklist(String checklistId) async {
    if (_userId.isEmpty) return false;

    try {
      await _firestore
          .collection('usuarios')
          .doc(_userId)
          .collection('checklists')
          .doc(checklistId)
          .delete();

      _checklists.removeWhere((c) => c.id == checklistId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erro ao excluir checklist: $e');
      return false;
    }
  }

  Checklist? buscarPorId(String id) {
    try {
      return _checklists.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
