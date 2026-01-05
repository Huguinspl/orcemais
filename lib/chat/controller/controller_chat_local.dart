import 'package:chat_global/controller/controller_chat.dart';
import 'package:chat_global/model/adm_chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgets_global/common/buttons/button_actions_dialog.dart';
import 'package:widgets_global/common/dialog/dialog_custom.dart';

class ControllerChatLocal extends GetxController {
  static ControllerChatLocal get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    _getName();
  }

  bool _perguntarNome = true;
  String nome = '';

  _getName() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('lojas')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
    if (doc.exists) {
      final dados = doc.data()!;
      nome = dados['nomeDono'] ?? "Não informado";
    }
  }

  Future<void> adicionarNome() async {
    if (!_perguntarNome || nome.isNotEmpty) {
      return;
    }
    _perguntarNome = false;
    TextEditingController editingController = TextEditingController();
    bool obrigatorioEditarNome = false;
    bool? setIconEditarNome;
    await Get.dialog(
      DialogCustom(
        title: 'Pode dizer seu nome?',
        actions: [
          ButtonNegativeDialog(
            text: 'Agora não',
            onPressed: () {
              Get.back();
            },
          ),
          ButtonConfirmDialog(
            text: 'Salvar',
            onPressed: () async {
              if (editingController.text.isEmpty) {
                obrigatorioEditarNome = true;
                setIconEditarNome = true;
                update();
                Get.closeAllSnackbars();
                Get.snackbar(
                  'Atenção!',
                  'Primeiro digite o nome.',
                  duration: const Duration(seconds: 2),
                );
                return;
              }

              nome = editingController.text;

              Get.back();
              try {
                Get.find<ControllerChat>().focus.requestFocus();
              } catch (_) {}
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 15,
                right: 15,
                bottom: 5,
              ),
              child: Text(
                'Será melhor te atender sabendo seu nome!',
                style: GoogleFonts.inter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 5,
                left: 15,
                right: 15,
                bottom: 15,
              ),
              child: Text(
                'Você também pode alterar seu nome no perfil.',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
            GetBuilder(
              init: this,
              builder: (_) {
                return TextField(
                  maxLines: 1,
                  controller: editingController,
                  /* decoration: InputDecoration(
                        fillColor: 
                      ),
                      color: Get.theme.cardColor,
                      labelText: 'Nome',
                      obrigatorio: obrigatorioEditarNome,
                      textCapitalization: TextCapitalization.words,
                      sufixIcon: setIconEditarNome, */
                  onChanged: (String value) {
                    if (value.isNotEmpty) {
                      obrigatorioEditarNome = false;
                      setIconEditarNome = null;
                    } else {
                      setIconEditarNome = false;
                    }
                    update();
                  },
                );
              },
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
