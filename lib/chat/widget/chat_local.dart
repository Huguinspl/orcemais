import 'package:chat_global/chat.dart';
import 'package:chat_global/controller/controller_chat.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:gestorfy/chat/constants_chat.dart';
import 'package:gestorfy/chat/controller/controller_chat_local.dart';

class ChatLocal extends StatefulWidget {
  const ChatLocal({super.key});

  @override
  State<ChatLocal> createState() => _ChatLocalState();
}

class _ChatLocalState extends State<ChatLocal> {
  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        try {
          final controllerChat = Get.find<ControllerChat>();
          if (!controllerChat.editarMensagem) {
            controllerChat.enviarMensagem();
          }
        } catch (_) {}
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    super.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    Get.delete<ControllerChatLocal>();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerChatLocal());
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      child: Chat(
        isAdm: false,
        limitDurationRecord: const Duration(minutes: 3),
        enviarEnter: kIsWeb,
        textInicial: textChat,
        onInitChat: () {
          isOnline = true;
        },
        onCloseChat: (textController) {
          isOnline = false;
          textChat = textController;
        },
        onSendChat: (dateTime, admChat) {
          admChat?.nome =
              controller.nome.isNotEmpty ? controller.nome : admChat.nome;
          controller.adicionarNome();
          return admChat;
        },
        onUpdateChatAdm: (dateTime, admChat) async {
          admChat.useridAdm = FirebaseAuth.instance.currentUser!.uid;
          admChat.nome = controller.nome.isNotEmpty ? controller.nome : '';
          return admChat;
        },
      ),
    );
  }
}
