import 'dart:convert';

/// Enum pour la gravité de l'accident
enum AccidentGravite {
  leger('leger', 'Léger'),
  grave('grave', 'Grave'),
  mortel('mortel', 'Mortel'),
  materiel('materiel', 'Matériel uniquement');

  final String value;
  final String label;
  const AccidentGravite(this.value, this.label);
}

/// Enum pour le lien du témoin avec l'accident
enum LienAccident {
  temoinDirect('temoin_direct', 'Témoin direct'),
  temoinIndirect('temoin_indirect', 'Témoin indirect'),
  passant('passant', 'Passant'),
  resident('resident', 'Résident du quartier'),
  automobiliste('automobiliste', 'Automobiliste présent'),
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

/// Modèle Accident
class Accident {
  final int? id;
  final DateTime dateAccident;
  final String lieu;
  final AccidentGravite gravite;
  final String description;
  final List<String> imagesPaths;
  final List<Temoin> temoins;
  final List<VehiculeImplique> vehiculesImpliques;

  Accident({
    this.id,
    required this.dateAccident,
    required this.lieu,
    required this.gravite,
    required this.description,
    this.imagesPaths = const [],
    this.temoins = const [],
    this.vehiculesImpliques = const [],
  });

  Map<String, dynamic> toJson() => {
    'date_accident': dateAccident.toIso8601String(),
    'lieu': lieu,
    'gravite': gravite.value,
    'description': description,
    'temoins_data': jsonEncode(temoins.map((t) => t.toJson()).toList()),
    'vehicules_data': jsonEncode(vehiculesImpliques.map((v) => v.toPayload()).toList()),
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
