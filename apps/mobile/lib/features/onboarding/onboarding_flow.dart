import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/outbox_sync_service.dart';
import '../../widgets/bz_brand_icons.dart';
import 'bz_onboarding_scaffold.dart';
import 'onboarding_controller.dart';

/// Onboarding flow — Welcome → Country → Genres (min 3) → Done.
/// Completes via [onComplete] (no Navigator.pop — the flow runs in
/// an overlay above the live shell, so popping would kill the page).
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step = _step.clamp(0, 2) - 1);

  Future<void> _finish() async {
    final controller = ref.read(onboardingProvider.notifier);
    final ok = await controller.save(authenticatedApi(ref));
    if (!mounted) return;
    if (ok) {
      // Plays/favorites sync with the right availability region.
      final country = ref.read(onboardingProvider).country;
      ref.read(outboxTerritoryProvider.notifier).state = country;
      widget.onComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save preferences. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      body: switch (_step) {
        0 => BzOnboardingScaffold(
            step: 0,
            totalSteps: 3,
            title: 'Welcome to Breezze',
            subtitle: 'Free. Every platform. One line.',
            nextLabel: 'Get started',
            onNext: _next,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BzRibbonLogo(width: 140, color: theme.bzText1),
                  const SizedBox(height: 24),
                  Text(
                    'Pick a few things you love and\nBreezze tunes itself to you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: BzType.body, color: theme.bzText2),
                  ),
                ],
              ),
            ),
          ),
        1 => BzOnboardingScaffold(
            step: 1,
            totalSteps: 3,
            title: 'Where are you?',
            subtitle: 'Used for music availability in your region.',
            nextLabel: 'Next',
            nextEnabled: state.country.isNotEmpty,
            onBack: _back,
            onNext: _next,
            body: ListView(
              children: [
                for (final code in kOnboardingCountries)
                  _ChoiceRow(
                    label: countryName(code),
                    selected: state.country == code,
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .setCountry(code),
                  ),
              ],
            ),
          ),
        2 => BzOnboardingScaffold(
            step: 2,
            totalSteps: 3,
            title: 'Pick your genres',
            subtitle: 'Choose at least three.',
            nextLabel: state.saving ? 'Saving…' : 'Finish',
            nextEnabled: state.genres.length >= 3 && !state.saving,
            onBack: _back,
            onNext: _finish,
            body: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
              children: [
                for (final genre in kOnboardingGenres)
                  _GenreChip(
                    label: genre,
                    selected: state.genres.contains(genre),
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleGenre(genre),
                  ),
              ],
            ),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: BzMotion.fastMs),
          curve: const Cubic(0.22, 1, 0.36, 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.bzText1 : theme.bzSurface1,
            borderRadius: BorderRadius.circular(BzRadius.input),
            border: Border.all(color: theme.bzSeparator),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: BzType.body,
              fontWeight: FontWeight.w500,
              color: selected ? theme.bzBackground : theme.bzText1,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: BzMotion.fastMs),
        curve: const Cubic(0.22, 1, 0.36, 1),
        decoration: BoxDecoration(
          color: selected ? theme.bzText1 : theme.bzSurface1,
          borderRadius: BorderRadius.circular(BzRadius.button),
          border: Border.all(color: theme.bzSeparator),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: BzType.subheadline,
              fontWeight: FontWeight.w600,
              color: selected ? theme.bzBackground : theme.bzText1,
            ),
          ),
        ),
      ),
    );
  }
}
