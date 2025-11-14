import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  }) : count = null;

  const FeatureCard.withCount({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int? count; // se nulo, usa layout simples
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 144, // 160 * 0.9 = 144
          padding: const EdgeInsets.all(14), // 16 * 0.9 = 14.4
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: count == null ? _simple() : _withCount(),
        ),
      ),
    );
  }

  Widget _simple() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(13), // 14 * 0.9 = 12.6
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 29, color: color), // 32 * 0.9 = 28.8
      ),
      const SizedBox(height: 13), // 14 * 0.9 = 12.6
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13, // 14 * 0.9 = 12.6
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          height: 1.3,
        ),
      ),
    ],
  );

  Widget _withCount() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(11), // 12 * 0.9 = 10.8
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 25, color: color), // 28 * 0.9 = 25.2
      ),
      const Spacer(),
      Text(
        title,
        style: TextStyle(
          fontSize: 13, // 14 * 0.9 = 12.6
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 5), // 6 * 0.9 = 5.4
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 4,
        ), // 10 * 0.9 = 9
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 14, // 16 * 0.9 = 14.4
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    ],
  );
}
