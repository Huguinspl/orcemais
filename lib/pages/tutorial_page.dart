import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<TutorialSlide> _slides = [
    TutorialSlide(
      icon: Icons.business_center,
      title: 'Gerencie seu Negócio',
      description:
          'Controle completo das suas informações comerciais, clientes e serviços em um só lugar',
      gradient: const LinearGradient(
        colors: [Color(0xFF006d5b), Color(0xFF4db6ac)],
      ),
    ),
    TutorialSlide(
      icon: Icons.receipt_long,
      title: 'Crie Orçamentos',
      description:
          'Elabore orçamentos profissionais com facilidade, personalize e compartilhe com seus clientes',
      gradient: const LinearGradient(
        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
      ),
    ),
    TutorialSlide(
      icon: Icons.calendar_today,
      title: 'Organize Agendamentos',
      description:
          'Mantenha sua agenda organizada, receba notificações e nunca perca um compromisso',
      gradient: const LinearGradient(
        colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
      ),
    ),
    TutorialSlide(
      icon: Icons.groups,
      title: 'Gerencie Clientes',
      description:
          'Cadastre e acompanhe todos os seus clientes, histórico de serviços e contatos',
      gradient: const LinearGradient(
        colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _continuar(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialVisto', true);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.informacoesOrcamento,
        (route) => false,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _continuar(context);
    }
  }

  void _skipTutorial() {
    _continuar(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView com slides
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(gradient: _slides[_currentPage].gradient),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSlide(_slides[index]),
                );
              },
            ),
          ),

          // Botão Skip no topo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipTutorial,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Pular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Indicadores e botão na parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicadores de página
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 32 : 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Próximo/Começar
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              _slides[_currentPage].gradient.colors.first,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Começar Agora'
                                  : 'Próximo',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _slides.length - 1
                                  ? Icons.check_circle
                                  : Icons.arrow_forward,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(TutorialSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone em círculo
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 70,
              color: slide.gradient.colors.first,
            ),
          ),
          const SizedBox(height: 60),

          // Título
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Descrição
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
          const SizedBox(
            height: 100,
          ), // Espaço para os botões na parte inferior
        ],
      ),
    );
  }
}

// Classe auxiliar para os slides do tutorial
class TutorialSlide {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  TutorialSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
