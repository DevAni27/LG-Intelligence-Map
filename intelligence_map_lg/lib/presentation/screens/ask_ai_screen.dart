import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AskAIScreen extends StatelessWidget {
  const AskAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask AI', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Natural language global intelligence',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Coming in Phase 4',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask questions like "What\'s happening in Asia?"\nand get AI-powered summaries.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Placeholder input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ask anything about global events...',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ),
                  Icon(Icons.send_rounded, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
