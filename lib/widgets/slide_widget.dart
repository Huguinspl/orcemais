import 'package:flutter/material.dart';

class SlideWidget extends StatelessWidget {
  final String imagePath;
  final String title;

  const SlideWidget({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
