// lib/conditional_desktop.dart
import 'dart:io';
import 'dart:ui'; // Rect & Size
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:window_size/window_size.dart';

/// Ajustes de janela – só é compilado em desktop/mobile.
/// Chame **apenas** depois de WidgetsFlutterBinding.ensureInitialized().
void configureDesktopWindow() {
  if (!Platform.isWindows) {
    return;
  }
  try {
    setWindowTitle('Gestorfy');

    // posição (x,y) e tamanho inicial
    setWindowFrame(const Rect.fromLTWH(100, 100, 1200, 800));

    // limites de resize (opcional)
    setWindowMinSize(const Size(800, 600));
    setWindowMaxSize(const Size(1600, 1000));
  } catch (e) {
    if (kDebugMode) debugPrint('Erro ao configurar janela: $e');
  }
}
