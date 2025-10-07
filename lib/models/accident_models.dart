import 'dart:convert';

/// Enum pour la gravité de l'accident
enum AccidentGravite {
  materiel('Matériel'),
  corporel('Corporel'),
  mortel('Mortel');

  final String label;
  const AccidentGravite(this.label);

  static AccidentGravite fromString(String value) {
    return AccidentGravite.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccidentGravite.materiel,
    );
  }
}

/// Enum pour le lien avec l'accident (Témoin)
enum LienAccident {
  passant('passant', 'Passant'),
  resident('resident', 'Résident'),
  automobiliste('automobiliste', 'Automobiliste'),
  autre('autre', 'Autre');

  final String value;
  final String label;
  const LienAccident(this.value, this.label);
}

/// Enum pour le rôle du véhicule dans l'accident
enum RoleVehicule {
  responsable('responsable', 'Responsable'),
  victime('victime', 'Victime'),
  indetermine('indetermine', 'Indéterminé');

  final String value;
  final String label;
  const RoleVehicule(this.value, this.label);
}

/// Enum pour le rôle d'une partie impliquée
enum RolePartie {
  responsable('responsable', 'Responsable'),
  victime('victime', 'Victime'),
  temoinMateriel('temoin_materiel', 'Témoin matériel'),
  autre('autre', 'Autre');

  final String value;
  final String label;
  const RolePartie(this.value, this.label);

  static RolePartie fromString(String value) {
    return RolePartie.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RolePartie.autre,
    );
  }
}

/// Enum pour l'état d'une personne
enum EtatPersonne {
  indemne('indemne', 'Indemne'),
  blesseLeger('blesse_leger', 'Blessé léger'),
  blesseGrave('blesse_grave', 'Blessé grave'),
  decede('decede', 'Décédé');

  final String value;
  final String label;
  const EtatPersonne(this.value, this.label);

  static EtatPersonne fromString(String value) {
    return EtatPersonne.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EtatPersonne.indemne,
    );
  }
}

/// Modèle pour un passager
class Passager {
  final String nom;
  final EtatPersonne etat;

  Passager({
    required this.nom,
    required this.etat,
  });

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'etat': etat.value,
      };

  factory Passager.fromJson(Map<String, dynamic> json) => Passager(
        nom: json['nom'],
        etat: EtatPersonne.fromString(json['etat']),
      );
}

/// Modèle pour une partie impliquée
class PartieImpliquee {
  final int? id;
  final int? vehiculePlaqueId;
  final String? plaque;
  final String? marque;
  final String? modele;
  final RolePartie role;
  final String? conducteurNom;
  final EtatPersonne conducteurEtat;
  final List<Passager> passagers;
  final String? dommagesVehicule;
  final List<String> photosLocales; // Chemins locaux des photos
  final String? notes;

  PartieImpliquee({
    this.id,
    this.vehiculePlaqueId,
    this.plaque,
    this.marque,
    this.modele,
    required this.role,
    this.conducteurNom,
    this.conducteurEtat = EtatPersonne.indemne,
    this.passagers = const [],
    this.dommagesVehicule,
    this.photosLocales = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'vehicule_plaque_id': vehiculePlaqueId,
        'role': role.value,
        'conducteur_nom': conducteurNom ?? '',
        'conducteur_etat': conducteurEtat.value,
        'passagers': jsonEncode(passagers.map((p) => p.toJson()).toList()),
        'dommages_vehicule': dommagesVehicule ?? '',
        'notes': notes ?? '',
      };
}

/// Modèle Accident
class Accident {
  final int? id;
  final DateTime dateAccident;
  final String lieu;
  final AccidentGravite gravite;
  final String description;
  final List<String> imagesPaths;
  final List<Temoin> temoins;
  final List<PartieImpliquee> partiesImpliquees;
  final List<String> servicesEtatPresent;
  final int? partieFautiveId;
  final String? raisonFaute;

  Accident({
    this.id,
    required this.dateAccident,
    required this.lieu,
    required this.gravite,
    required this.description,
    this.imagesPaths = const [],
    this.temoins = const [],
    this.partiesImpliquees = const [],
    this.servicesEtatPresent = const [],
    this.partieFautiveId,
    this.raisonFaute,
  });

  Map<String, dynamic> toJson() => {
        'date_accident': dateAccident.toIso8601String(),
        'lieu': lieu,
        'gravite': gravite.name,
        'description': description,
        'temoins_data': jsonEncode(temoins.map((t) => t.toJson()).toList()),
        'parties_data':
            jsonEncode(partiesImpliquees.map((p) => p.toJson()).toList()),
        'services_etat_present': jsonEncode(servicesEtatPresent),
        'partie_fautive_id': partieFautiveId,
        'raison_faute': raisonFaute ?? '',
      };
}

/// Modèle Témoin
class Temoin {
  final String nom;
  final String telephone;
  final int age;
  final LienAccident lienAvecAccident;
  final String? temoignage;

  Temoin({
    required this.nom,
    required this.telephone,
    required this.age,
    required this.lienAvecAccident,
    this.temoignage,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'telephone': telephone,
    'age': age,
    'lien_avec_accident': lienAvecAccident.value,
    'temoignage': temoignage ?? '',
  };
}

/// Modèle Véhicule Impliqué
class VehiculeImplique {
  final int vehiculePlaqueId;
  final String? plaque;
  final String? marque;
  final String? modele;
  final String? couleur;
  final String? annee;
  final RoleVehicule? role;
  final String? dommages;
  final String? notes;

  VehiculeImplique({
    required this.vehiculePlaqueId,
    this.plaque,
    this.marque,
    this.modele,
    this.couleur,
    this.annee,
    this.role,
    this.dommages,
    this.notes,
  });

  Map<String, dynamic> toPayload() => {
    'vehicule_id': vehiculePlaqueId,
    'role': role?.value ?? 'indetermine',
    'dommages': dommages ?? '',
    'notes': notes ?? '',
  };

  factory VehiculeImplique.fromJson(Map<String, dynamic> json) {
    return VehiculeImplique(
      vehiculePlaqueId: json['id'] ?? 0,
      plaque: json['plaque'],
      marque: json['marque'],
      modele: json['modele'],
      couleur: json['couleur'],
      annee: json['annee']?.toString(),
    );
  }
}
