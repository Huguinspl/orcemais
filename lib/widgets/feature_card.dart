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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha((255 * 0.3).round())),
        ),
        padding: const EdgeInsets.all(16),
        child: count == null ? _simple() : _withCount(),
      ),
    );
  }

  Widget _simple() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 40, color: color),
      const SizedBox(height: 12),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );

  Widget _withCount() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}
