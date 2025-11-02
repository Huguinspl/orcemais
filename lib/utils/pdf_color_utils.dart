import 'package:pdf/pdf.dart';

class PdfColorUtils {
  /// Converte um inteiro ARGB (0xAARRGGBB) em PdfColor.
  static PdfColor fromArgbInt(int? v, PdfColor fallback) {
    if (v == null) return fallback;
    final a = ((v >> 24) & 0xFF) / 255.0;
    final r = ((v >> 16) & 0xFF) / 255.0;
    final g = ((v >> 8) & 0xFF) / 255.0;
    final b = (v & 0xFF) / 255.0;
    return PdfColor(r, g, b, a);
  }
}
