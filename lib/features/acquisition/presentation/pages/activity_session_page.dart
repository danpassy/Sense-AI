import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_fade_in.dart';
import '../../../ble/services/ble_service.dart';
import '../models/activity_model.dart';

/// Page de session d'acquisition : Start/Stop, Timer, Retour.
/// Démarre / arrête l'enregistrement sur le STM32 (fichiers ACQ_COURSE_001, ACQ_MARCHE_001, etc.).
class ActivitySessionPage extends StatefulWidget {
  final ActivityModel activity;

  const ActivitySessionPage({super.key, required this.activity});

  @override
  State<ActivitySessionPage> createState() => _ActivitySessionPageState();
}

class _ActivitySessionPageState extends State<ActivitySessionPage> {
  final BleService _bleService = BleService();
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;
  bool _bleBusy = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleStartStop() async {
    if (_bleBusy) return;
    setState(() => _bleBusy = true);
    try {
      if (_isRunning) {
        await _bleService.stopRecording();
        if (!mounted) return;
        setState(() {
          _timer?.cancel();
          _timer = null;
          _isRunning = false;
          _bleBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement arrêté sur le STM32'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final activityIndex = ActivityList.indexOf(widget.activity);
        await _bleService.startRecording(activityIndex);
        if (!mounted) return;
        setState(() {
          _isRunning = true;
          _bleBusy = false;
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) {
              setState(() {
                _elapsed += const Duration(seconds: 1);
              });
            }
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enregistrement démarré sur le STM32 (fichier ACQ_${widget.activity.blePrefix}_XXX.csv)',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _bleBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRunning ? 'Erreur arrêt enregistrement: $e' : 'Erreur démarrage enregistrement: $e',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _onBack() async {
    if (_isRunning) {
      try {
        await _bleService.stopRecording();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _timer?.cancel();
          _timer = null;
          _isRunning = false;
        });
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardBackground = isDark ? AppTheme.darkSurfaceColor : AppTheme.cardBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.activity.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _bleBusy ? null : _onBack,
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              // Icône et nom de l'activité
              AnimatedFadeIn(
                delay: Duration.zero,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    decoration: BoxDecoration(
                      color: widget.activity.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.activity.color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.activity.icon,
                      size: 64,
                      color: widget.activity.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              AnimatedFadeIn(
                delay: const Duration(milliseconds: 100),
                child: Center(
                  child: Text(
                    widget.activity.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              // Timer
              AnimatedFadeIn(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingXL,
                    horizontal: AppTheme.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(
                      color: widget.activity.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Temps écoulé',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        _formatDuration(_elapsed),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.activity.color,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Bouton Start / Stop
              AnimatedFadeIn(
                delay: const Duration(milliseconds: 300),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _bleBusy ? null : _toggleStartStop,
                    icon: Icon(
                      _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 28,
                    ),
                    label: Text(
                      _isRunning ? 'Arrêter' : 'Démarrer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? AppTheme.errorColor : AppTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}
