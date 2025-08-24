import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/slide_widget.dart';
import '../routes/app_routes.dart';

class ApresentacaoPage extends StatefulWidget {
  const ApresentacaoPage({super.key});

  @override
  State<ApresentacaoPage> createState() => _ApresentacaoPageState();
}

class _ApresentacaoPageState extends State<ApresentacaoPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/gestorfy_logo_principal.png',
      'text': 'Organize tudo em um só lugar',
    },
    {
      'image': 'assets/imagem_gestorfy_logo.png',
      'text': 'Controle seu orçamento com facilidade',
    },
    {
      'image': 'assets/imagem_gestorfy.png',
      'text': 'Veja gráficos e relatórios claros',
    },
    {'image': 'assets/img-rodape.jpg', 'text': 'Seu guia financeiro pessoal'},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_controller.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Logo
            Center(
              child: Image.asset(
                'assets/gestorfy_logo_principal.png',
                width: 100,
                height: 100,
              ),
            ),

            const SizedBox(height: 8),
            // Texto de boas-vindas
            const Text(
              'Bem-vindo ao Gestorfy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),
            // Slide de imagens
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return SlideWidget(
                    imagePath: _slides[index]['image']!,
                    title: '',
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            // Texto de cada slide sincronizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _slides[_currentPage]['text']!,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
            // Botão fixo na parte inferior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
