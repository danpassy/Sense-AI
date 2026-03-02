import 'package:flutter/material.dart';

/// Modèle représentant une activité pour l'acquisition de données
class ActivityModel {
  final String id;
  final String name;
  final String blePrefix;  // Préfixe fichier STM32: ACQ_COURSE_001, ACQ_MARCHE_001, etc.
  final IconData icon;
  final Color color;

  const ActivityModel({
    required this.id,
    required this.name,
    required this.blePrefix,
    required this.icon,
    required this.color,
  });
}

/// Liste des activités disponibles pour l'acquisition (ordre = index BLE 0..5)
class ActivityList {
  static const List<ActivityModel> items = [
    ActivityModel(
      id: 'running',
      name: 'Course à pied',
      blePrefix: 'COURSE',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF6366F1),
    ),
    ActivityModel(
      id: 'walking',
      name: 'Marche',
      blePrefix: 'MARCHE',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF10B981),
    ),
    ActivityModel(
      id: 'cycling',
      name: 'Vélo',
      blePrefix: 'VELO',
      icon: Icons.directions_bike_rounded,
      color: Color(0xFF06B6D4),
    ),
    ActivityModel(
      id: 'fitness',
      name: 'Fitness',
      blePrefix: 'FITNESS',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFF59E0B),
    ),
    ActivityModel(
      id: 'yoga',
      name: 'Yoga',
      blePrefix: 'YOGA',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF8B5CF6),
    ),
    ActivityModel(
      id: 'other',
      name: 'Autre',
      blePrefix: 'AUTRE',
      icon: Icons.sports_rounded,
      color: Color(0xFF757575),
    ),
  ];

  static int indexOf(ActivityModel a) {
    final i = items.indexWhere((x) => x.id == a.id);
    return i >= 0 ? i : 0;
  }
}
