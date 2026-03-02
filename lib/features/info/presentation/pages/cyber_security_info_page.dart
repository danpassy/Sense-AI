import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_fade_in.dart';

/// Page d'information détaillée sur la Partie C : Cyber‑sécurité (Soft & Hardware)
class CyberSecurityInfoPage extends StatelessWidget {
  const CyberSecurityInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cyber‑sécurité (Soft & Hardware)',
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
            SliverToBoxAdapter(child: _buildSoftwareSection(context)),
            SliverToBoxAdapter(child: _buildHardwareSection(context)),
            SliverToBoxAdapter(child: _buildRoadmap(context)),
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
              AppTheme.warningColor,
              AppTheme.warningColor.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warningColor.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.security_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Cyber‑sécurité logicielle et matérielle',
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
              'Objectif: protéger les données enregistrées et la communication.',
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

  Widget _buildSoftwareSection(BuildContext context) {
    return _Section(
      delayMs: 200,
      title: 'Sécurité logicielle (Soft) — à implémenter par nous',
      icon: Icons.code_rounded,
      iconColor: AppTheme.primaryColor,
      children: const [
        _Bullet(
          title: 'Chiffrement des données sur carte SD',
          items: [
            'Les fichiers CSV enregistrés sur la SD seront chiffrés (confidentialité).',
            'But: si la SD est récupérée, les données restent illisibles sans la clé.',
            'Gestion de clé: clé stockée côté carte (ou provisionnée) + rotation/identifiant de version.',
          ],
        ),
        _Bullet(
          title: 'Chiffrement des communications',
          items: [
            'Chiffrement des échanges entre la carte et l’application (BLE).',
            'But: empêcher l’écoute/lecture des données en transit (sniffing).',
            'Option: utiliser le pairing/bonding BLE + sécurisation applicative (chiffrement applicatif).',
          ],
        ),
        _Bullet(
          title: 'Intégrité & authentification',
          items: [
            'Vérifier que les messages reçus ne sont pas modifiés (intégrité).',
            'Authentifier l’appareil et/ou l’application (éviter un faux périphérique).',
          ],
        ),
      ],
    );
  }

  Widget _buildHardwareSection(BuildContext context) {
    return _Section(
      delayMs: 300,
      title: 'Sécurité matérielle (Hardware) — amélioration (autre groupe)',
      icon: Icons.memory_rounded,
      iconColor: AppTheme.accentColor,
      children: const [
        _Bullet(
          title: 'Ce qui est possible de faire',
          items: [
            'Protection firmware: sécuriser la lecture/écriture de la mémoire (RDP, zones protégées).',
            'Secure boot: démarrer uniquement un firmware signé (empêche firmware modifié).',
            'Stockage clé sécurisé: stockage en zone protégée ou élément sécurisé (si dispo).',
            'Accélération crypto: utiliser les blocs cryptographiques matériels quand disponibles.',
            'Anti‑tamper / debug lock: réduire les risques via verrouillage debug et contrôles.',
          ],
        ),
        _Bullet(
          title: 'Sécurisation physique (robustesse électrique)',
          items: [
            'Filtres EMI/EMC: ferrites, selfs, filtres RC/LC, filtres en entrée d’alimentation, blindage si nécessaire.',
            'Protections ESD: diodes TVS sur les lignes exposées (connecteurs, SPI/I2C/USB, etc.).',
            'Protection d’alimentation: inversion de polarité, surtension, limitation de courant (polyfuse), découplage soigné.',
            'Protection des entrées/sorties: résistances série, clamp, adaptation de niveau, limitation des transitoires.',
            'Protection “usage terrain”: réduction du bruit, meilleure stabilité mesures, et moins de pannes liées aux décharges/parasites.',
          ],
        ),
        _Bullet(
          title: 'Intégration attendue',
          items: [
            'On récupère la solution matérielle (design/paramétrage) du groupe dédié.',
            'Notre partie “soft” s’appuiera dessus pour la gestion sûre des clés.',
          ],
        ),
      ],
    );
  }

  Widget _buildRoadmap(BuildContext context) {
    return _Section(
      delayMs: 400,
      title: 'Roadmap (non implémenté pour le moment)',
      icon: Icons.flag_rounded,
      iconColor: AppTheme.successColor,
      children: const [
        _StepLine('1', 'Définir le format chiffré des fichiers SD (métadonnées + version).'),
        _StepLine('2', 'Ajouter chiffrement/déchiffrement côté STM32 (écriture/lecture).'),
        _StepLine('3', 'Sécuriser la communication (pairing/bonding + option chiffrement applicatif).'),
        _StepLine('4', 'Ajouter intégrité (MAC) et authentification périphérique.'),
        _StepLine('5', 'Brancher la partie hardware (stockage clé/secure boot) quand disponible.'),
      ],
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
          const SizedBox(height: 8),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.25,
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

class _StepLine extends StatelessWidget {
  final String step;
  final String text;
  const _StepLine(this.step, this.text);

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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(
                step,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

