import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_fade_in.dart';

/// Page d'information sur la Partie B : Données & Intelligence Artificielle
class DataAiInfoPage extends StatelessWidget {
  const DataAiInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Données et IA',
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildInputsSection(context)),
            SliverToBoxAdapter(child: _buildLowLevelFeaturesSection(context)),
            SliverToBoxAdapter(child: _buildFutureAiSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AnimatedFadeIn(
      delay: const Duration(milliseconds: 100),
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingL),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentColor,
              AppTheme.accentColor.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.psychology_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Données & Intelligence Artificielle',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Entrées capteurs → caractéristiques bas niveau → modèles IA',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputsSection(BuildContext context) {
    return _Section(
      delayMs: 200,
      title: 'Données d’entrée (utilisables par l’IA)',
      icon: Icons.input_rounded,
      iconColor: AppTheme.primaryColor,
      children: [
        _Bullet(
          title: 'Biométrie',
          items: const [
            'Fréquence cardiaque (FC, bpm)',
            'SpO₂ (%, saturation)',
            'Confiance (%) et Status (qualité/état du signal)',
          ],
        ),
        _Bullet(
          title: 'Mouvement (LSM6DSOX)',
          items: const [
            'Gyroscope: \(Gx, Gy, Gz\) (dps)',
            'Angles: Pitch / Roll (°)',
          ],
        ),
        _Bullet(
          title: 'Système',
          items: const [
            'Température interne (°C)',
            'Horodatage / fenêtre temporelle (pour calculer des features)',
          ],
        ),
      ],
    );
  }

  Widget _buildLowLevelFeaturesSection(BuildContext context) {
    return _Section(
      delayMs: 300,
      title: 'Caractéristiques bas niveau (extraits du PDF)',
      icon: Icons.functions_rounded,
      iconColor: AppTheme.successColor,
      children: const [
        _FeatureLine('FC moyenne', 'moyenne(FC)'),
        _FeatureLine('Variation FC (ΔFC)', 'FC(t) − FC(t−1)'),
        _FeatureLine('SpO₂ moyenne', 'moyenne(SpO₂)'),
        _FeatureLine('Temps sous seuil', 'somme(SpO₂ < 92%)'),
        _FeatureLine('Taux de données fiables', 'pourcentage(Confiance > 70)'),
        _FeatureLine('Nombre de transitions', 'compte(Status(t) ≠ Status(t−1))'),
        _FeatureLine('Norme du gyroscope', '√(Gx² + Gy² + Gz²)'),
        _FeatureLine('Énergie du mouvement', 'somme(Gx² + Gy² + Gz²)'),
        _FeatureLine('Distance angulaire', '√(ΔPitch² + ΔRoll²)'),
        _FeatureLine('Vitesse angulaire', '(ΔPitch + ΔRoll) / Δt'),
      ],
    );
  }

  Widget _buildFutureAiSection(BuildContext context) {
    return _Section(
      delayMs: 400,
      title: 'Fonctionnalités IA possibles (pas encore implémentées)',
      icon: Icons.auto_awesome_rounded,
      iconColor: AppTheme.warningColor,
      children: [
        _IntroNote(
          text:
              'Ces fonctionnalités seront basées sur les entrées capteurs et les features bas niveau (fenêtres temporelles) : classification, scoring et détection d’anomalies.',
        ),
        const SizedBox(height: AppTheme.spacingM),
        _TodoChip(
          title: 'Déduire l’activité en cours',
          desc: 'Reconnaissance d’activité (marche/course/vélo/etc.) à partir du mouvement + biométrie.',
        ),
        _TodoChip(
          title: 'Déterminer l’état de santé',
          desc: 'Score de forme/état physiologique (repos, stress, fatigue) et tendances.',
        ),
        _TodoChip(
          title: 'Détecter une situation à risque / danger',
          desc: 'Anomalies (SpO₂ basse, chute, mouvements anormaux) + alertes.',
        ),
        _TodoChip(
          title: 'Reconnaître l’utilisateur',
          desc: 'Identification via “signature” biométrique et/ou patterns de mouvement (personnalisation).',
        ),
        _TodoChip(
          title: 'Détection d’anomalies',
          desc: 'Détection d’événements rares (outliers) et dérives capteur / qualité.',
        ),
        _TodoChip(
          title: 'Segmentation & scoring de session',
          desc: 'Découper une session en phases (échauffement/effort/récupération) + indicateurs.',
        ),
      ],
    );
  }
}

class _IntroNote extends StatelessWidget {
  final String text;
  const _IntroNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: textSecondary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final int delayMs;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _Section({
    required this.delayMs,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return AnimatedFadeIn(
      delay: Duration(milliseconds: delayMs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingM,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String title;
  final List<String> items;

  const _Bullet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String name;
  final String formula;

  const _FeatureLine(this.name, this.formula);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.successColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  formula,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoChip extends StatelessWidget {
  final String title;
  final String desc;

  const _TodoChip({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkBackgroundColor : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textLight = isDark ? AppTheme.darkTextLight : AppTheme.textLight;
    final chipBg = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: textLight.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: textLight.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Bientôt',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniTag(context, 'IA'),
                    _miniTag(context, 'Détection'),
                    _miniTag(context, 'Modèle'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textSecondary.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}
