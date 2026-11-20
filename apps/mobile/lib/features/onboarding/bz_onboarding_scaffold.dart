import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';

/// Shared onboarding scaffolding: brand header, calm progress dots,
/// glass card body, consistent next/cancel buttons.
class BzOnboardingScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback onNext;
  final String nextLabel;
  final VoidCallback? onBack;
  final bool nextEnabled;

  const BzOnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onNext,
    required this.nextLabel,
    this.onBack,
    this.nextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < totalSteps; i++)
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: BzMotion.fastMs),
                    curve: const Cubic(0.22, 1, 0.36, 1),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i <= step ? 20 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step ? theme.bzText1 : theme.bzSeparator,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(title, style: theme.textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    fontSize: BzType.body, color: theme.bzText2)),
            const SizedBox(height: 28),
            Expanded(child: body),
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                child: Text('Back',
                    style: TextStyle(color: theme.bzText2)),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: nextEnabled ? onNext : null,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: nextEnabled
                      ? theme.bzText1
                      : theme.bzSeparator,
                  borderRadius: BorderRadius.circular(BzRadius.button),
                ),
                child: Center(
                  child: Text(
                    nextLabel,
                    style: TextStyle(
                      fontSize: BzType.subheadline,
                      fontWeight: FontWeight.w600,
                      color: nextEnabled
                          ? theme.bzBackground
                          : theme.bzText2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
