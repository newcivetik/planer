import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF4A90D9);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF5F5F5),
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFFBBBBBB),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
                begin: 0.15,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
