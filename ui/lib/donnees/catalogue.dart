import 'package:flutter/painting.dart';

/// Où s'ouvre un usage (ADR 0014).
enum Lanceur {
  /// Dans notre OS, écran natif Flutter.
  natif,

  /// Dans notre OS, Chromium en mode kiosque.
  navigateur,

  /// Sous l'Android d'origine : la box redémarre sur l'eMMC.
  android,
}

class Usage {
  const Usage({
    required this.id,
    required this.nom,
    required this.description,
    required this.lanceur,
    required this.teinte,
  });

  final String id;
  final String nom;
  final String description;
  final Lanceur lanceur;

  /// Teinte discrète de la tuile, pour reconnaître l'usage d'un coup d'œil.
  final Color teinte;
}

/// Une ambiance de la maison. Sa couleur pilote le halo de l'écran.
class Scene {
  const Scene({
    required this.id,
    required this.nom,
    required this.description,
    required this.couleur,
    this.eteint = false,
  });

  final String id;
  final String nom;
  final String description;
  final Color couleur;
  final bool eteint;
}

class Lumiere {
  const Lumiere({
    required this.id,
    required this.piece,
    required this.nom,
    required this.couleur,
    required this.allumee,
    required this.intensite,
  });

  final String id;
  final String piece;
  final String nom;
  final Color couleur;
  final bool allumee;

  /// De 0 à 100.
  final int intensite;

  Lumiere copieAvec({bool? allumee}) => Lumiere(
    id: id,
    piece: piece,
    nom: nom,
    couleur: couleur,
    allumee: allumee ?? this.allumee,
    intensite: intensite,
  );
}

/// Données de démonstration, en attendant le hub domotique (phase 5).
abstract final class Catalogue {
  static const usages = <Usage>[
    Usage(
      id: 'youtube',
      nom: 'YouTube',
      description:
          "S'ouvre dans le navigateur TV, l'envoi depuis le téléphone marche.",
      lanceur: Lanceur.navigateur,
      teinte: Color(0xFFE5484D),
    ),
    Usage(
      id: 'twitch',
      nom: 'Twitch',
      description: 'Lecteur natif : chaînes suivies et directs en 1080p.',
      lanceur: Lanceur.natif,
      teinte: Color(0xFF9B6BFF),
    ),
    Usage(
      id: 'netflix',
      nom: 'Netflix',
      description: 'Redémarre la box sous Android, environ 40 secondes.',
      lanceur: Lanceur.android,
      teinte: Color(0xFFD9383F),
    ),
    Usage(
      id: 'canal',
      nom: 'Canal+',
      description: 'Redémarre la box sous Android, environ 40 secondes.',
      lanceur: Lanceur.android,
      teinte: Color(0xFFCBD2E0),
    ),
    Usage(
      id: 'medias',
      nom: 'Médias',
      description: 'Films et photos du disque réseau.',
      lanceur: Lanceur.natif,
      teinte: Color(0xFF4CC38A),
    ),
  ];

  static const scenes = <Scene>[
    Scene(
      id: 'soiree',
      nom: 'Soirée',
      description: 'Salon tamisé à 40 %, lumière chaude.',
      couleur: Color(0xFFFFA25C),
    ),
    Scene(
      id: 'cinema',
      nom: 'Cinéma',
      description: 'Tout éteint sauf un bandeau bleu derrière la télé.',
      couleur: Color(0xFF4F7BFF),
    ),
    Scene(
      id: 'lecture',
      nom: 'Lecture',
      description: 'Lampe du fauteuil à 80 %, blanc neutre.',
      couleur: Color(0xFFF3EEDD),
    ),
    Scene(
      id: 'nuit',
      nom: 'Nuit',
      description: 'Éteint toutes les lumières de la maison.',
      couleur: Color(0xFF2B3350),
      eteint: true,
    ),
  ];

  static const lumieres = <Lumiere>[
    Lumiere(
      id: 'l1',
      piece: 'Salon',
      nom: 'Plafonnier',
      couleur: Color(0xFFFFB46B),
      allumee: true,
      intensite: 40,
    ),
    Lumiere(
      id: 'l2',
      piece: 'Salon',
      nom: 'Bandeau télé',
      couleur: Color(0xFFFF8A4C),
      allumee: true,
      intensite: 60,
    ),
    Lumiere(
      id: 'l3',
      piece: 'Salon',
      nom: 'Lampe fauteuil',
      couleur: Color(0xFFF3EEDD),
      allumee: false,
      intensite: 80,
    ),
    Lumiere(
      id: 'l4',
      piece: 'Cuisine',
      nom: 'Spots',
      couleur: Color(0xFFFFF1D6),
      allumee: false,
      intensite: 100,
    ),
    Lumiere(
      id: 'l5',
      piece: 'Chambre',
      nom: 'Chevet',
      couleur: Color(0xFFFF9E7A),
      allumee: false,
      intensite: 25,
    ),
    Lumiere(
      id: 'l6',
      piece: 'Entrée',
      nom: 'Applique',
      couleur: Color(0xFFFFD08A),
      allumee: true,
      intensite: 30,
    ),
  ];
}
