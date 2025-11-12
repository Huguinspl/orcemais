import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialOrcamentoKey = 'tutorialOrcamentoConcluido';

  // Verifica se o tutorial já foi concluído
  static Future<bool> isTutorialConcluido() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialOrcamentoKey) ?? false;
  }

  // Marca o tutorial como concluído
  static Future<void> marcarTutorialConcluido() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialOrcamentoKey, true);
  }

  // Reseta o tutorial (útil para testes)
  static Future<void> resetarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialOrcamentoKey);
  }
}

// Widget de destaque (spotlight) para o tutorial
class TutorialSpotlight extends StatelessWidget {
  final Widget child;
  final String message;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final int currentStep;
  final int totalSteps;

  const TutorialSpotlight({
    super.key,
    required this.child,
    required this.message,
    required this.onNext,
    this.onSkip,
    this.showSkip = true,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay escuro
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Bloqueia interação com o fundo
            child: Container(color: Colors.black.withOpacity(0.8)),
          ),
        ),

        // Área destacada
        child,

        // Tooltip com mensagem
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de progresso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalSteps,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              index == currentStep - 1
                                  ? const Color(0xFF006d5b)
                                  : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Número do passo
                  Text(
                    'Passo $currentStep de $totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mensagem
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botões
                  Row(
                    children: [
                      if (showSkip && onSkip != null)
                        Expanded(
                          child: TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Pular Tutorial',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      if (showSkip && onSkip != null) const SizedBox(width: 12),
                      Expanded(
                        flex: showSkip ? 1 : 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006d5b), Color(0xFF4db6ac)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentStep == totalSteps
                                      ? 'Concluir'
                                      : 'Próximo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  currentStep == totalSteps
                                      ? Icons.check_circle
                                      : Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
