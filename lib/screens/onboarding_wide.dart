// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/app_logo.dart';

/// A feature of the app shown in the grid of [OnboardingWide].
class OnboardingFeature {
  const OnboardingFeature(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

/// The introduction on wide screens (the web on a desktop), laid out as a
/// landing page instead of the phone carousel: top bar, hero with the
/// welcome text and an illustration, then the [features] in a grid.
class OnboardingWide extends StatelessWidget {
  const OnboardingWide({
    super.key,
    required this.features,
    required this.onStart,
  });

  final List<OnboardingFeature> features;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.55],
            colors: [cs.primary.withValues(alpha: 0.07), cs.surface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(onStart: onStart),
                      const SizedBox(height: 64),
                      _Hero(onStart: onStart),
                      const SizedBox(height: 96),
                      _FeatureGrid(features: features),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const AppLogo(size: 36),
          const SizedBox(width: 12),
          Text(
            'Taskenda',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.l10n.onboardingStart),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            l10n.onboardingTagline,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingWelcomeTitle,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.1,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.onboardingWelcomeBody,
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 36),
        FilledButton.icon(
          onPressed: onStart,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward, size: 20),
          label: Text(l10n.onboardingStart),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 6, child: text),
        const SizedBox(width: 64),
        const Expanded(flex: 5, child: _HeroArt()),
      ],
    );
  }
}

// ─── Illustration ─────────────────────────────────────────────────────────────

/// Abstract picture of the app: a calendar, a task list and a note as
/// floating cards, with placeholder bars instead of text.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.05,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withValues(alpha: 0.18),
                          AppColors.violet.withValues(alpha: 0.12),
                          AppColors.teal.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.08,
                  top: h * 0.09,
                  width: w * 0.62,
                  child: const _MockCard(child: _MockCalendar()),
                ),
                Positioned(
                  right: w * 0.06,
                  top: h * 0.38,
                  width: w * 0.5,
                  child: const _MockCard(child: _MockTasks()),
                ),
                Positioned(
                  left: w * 0.14,
                  bottom: h * 0.07,
                  width: w * 0.42,
                  child: _MockCard(
                    color: Color.alphaBlend(
                      AppColors.amber.withValues(alpha: 0.16),
                      cs.surface,
                    ),
                    child: const _MockNote(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Rounded placeholder bar standing for a line of text.
class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, this.height = 8, this.color});
  final double widthFactor;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color:
              color ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class _MockCalendar extends StatelessWidget {
  const _MockCalendar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget event(Color color, double width) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: _Bar(widthFactor: width, color: color.withValues(alpha: 0.45)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            const Expanded(child: _Bar(widthFactor: 0.4, height: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      i == 3
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.06),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        event(AppColors.blue, 0.6),
        event(AppColors.violet, 0.45),
        event(AppColors.coral, 0.7),
      ],
    );
  }
}

class _MockTasks extends StatelessWidget {
  const _MockTasks();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget task(bool done, double width) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.teal : cs.outline,
          ),
          const SizedBox(width: 10),
          Expanded(child: _Bar(widthFactor: width)),
        ],
      ),
    );
    return Column(
      children: [
        task(true, 0.7),
        task(true, 0.5),
        task(false, 0.85),
        task(false, 0.6),
      ],
    );
  }
}

class _MockNote extends StatelessWidget {
  const _MockNote();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: AppColors.amber),
            SizedBox(width: 8),
            Expanded(child: _Bar(widthFactor: 0.6, height: 10)),
          ],
        ),
        SizedBox(height: 12),
        _Bar(widthFactor: 1),
        SizedBox(height: 8),
        _Bar(widthFactor: 0.9),
        SizedBox(height: 8),
        _Bar(widthFactor: 0.55),
      ],
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});
  final List<OnboardingFeature> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          context.l10n.onboardingFeaturesTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 40),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1000 ? 4 : 2;
            const gap = 20.0;
            final cellW = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in features)
                  SizedBox(width: cellW, child: _FeatureCard(f)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.feature);
  final OnboardingFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color),
          ),
          const SizedBox(height: 20),
          Text(
            feature.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
