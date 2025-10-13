<?php

require_once __DIR__ . '/BaseController.php';
require_once __DIR__ . '/LogController.php';

class GlobalSearchController extends BaseController {
    
    public function globalSearch($query, $limit = 50) {
        try {
            if (empty(trim($query))) {
                return [
                    'success' => false,
                    'message' => 'Le terme de recherche ne peut pas être vide'
                ];
            }
            
            $searchTerm = '%' . trim($query) . '%';
            $results = [];
            
            // Recherche dans les véhicules
            $vehicleResults = $this->searchVehicles($searchTerm);
            $results = array_merge($results, $vehicleResults);
            
            // Recherche dans les particuliers
            $particulierResults = $this->searchParticuliers($searchTerm);
            $results = array_merge($results, $particulierResults);
            
            // Recherche dans les entreprises
            $entrepriseResults = $this->searchEntreprises($searchTerm);
            $results = array_merge($results, $entrepriseResults);
            
            // Recherche dans les contraventions
            $contraventionResults = $this->searchContraventions($searchTerm);
            $results = array_merge($results, $contraventionResults);
            
            // Recherche dans les accidents
            $accidentResults = $this->searchAccidents($searchTerm);
            $results = array_merge($results, $accidentResults);
            
            // Recherche dans les arrestations
            $arrestationResults = $this->searchArrestations($searchTerm);
            $results = array_merge($results, $arrestationResults);
            
            // Recherche dans les users/agents
            $userResults = $this->searchUsers($searchTerm);
            $results = array_merge($results, $userResults);
            
            // Recherche dans les avis de recherche
            $avisResults = $this->searchAvisRecherche($searchTerm);
            $results = array_merge($results, $avisResults);
            
            // Recherche dans les permis temporaires
            $permisResults = $this->searchPermisTemporaire($searchTerm);
            $results = array_merge($results, $permisResults);
            
            // Recherche dans les témoins
            $temoinResults = $this->searchTemoins($searchTerm);
            $results = array_merge($results, $temoinResults);
            
            // Recherche dans les assurances véhicules
            $assuranceResults = $this->searchAssurances($searchTerm);
            $results = array_merge($results, $assuranceResults);
            
            // Limiter les résultats
            if (count($results) > $limit) {
                $results = array_slice($results, 0, $limit);
            }
            
            return [
                'success' => true,
                'data' => $results,
                'total' => count($results),
                'query' => $query
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ];
        }
    }
    
    private function searchVehicles($searchTerm) {
        // Recherche dans TOUS les champs de la table vehicule_plaque
        $sql = "SELECT id, plaque, marque, modele, couleur, annee, created_at,
                       'vehicule' as type, 'Véhicule' as type_label
                FROM vehicule_plaque 
                WHERE plaque LIKE ? 
                   OR marque LIKE ? 
                   OR modele LIKE ? 
                   OR couleur LIKE ? 
                   OR annee LIKE ?
                   OR numero_chassis LIKE ?
                   OR frontiere_entree LIKE ?
                   OR nume_assurance LIKE ?
                   OR societe_assurance LIKE ?
                   OR genre LIKE ?
                   OR `usage` LIKE ?
                   OR numero_declaration LIKE ?
                   OR num_moteur LIKE ?
                   OR origine LIKE ?
                   OR source LIKE ?
                   OR annee_fab LIKE ?
                   OR annee_circ LIKE ?
                   OR type_em LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        // Bind le même terme pour chaque placeholder (18 fois)
        for ($i = 1; $i <= 18; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['plaque'] . ' - ' . $row['marque'] . ' ' . $row['modele'],
                'subtitle' => 'Couleur: ' . ($row['couleur'] ?: 'N/A') . ' | Année: ' . ($row['annee'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchParticuliers($searchTerm) {
        // Recherche dans TOUS les champs de la table particuliers
        $sql = "SELECT id, nom, adresse, gsm, email, numero_national, created_at,
                       'particulier' as type, 'Particulier' as type_label
                FROM particuliers 
                WHERE nom LIKE ? 
                   OR adresse LIKE ? 
                   OR gsm LIKE ? 
                   OR email LIKE ? 
                   OR numero_national LIKE ?
                   OR profession LIKE ?
                   OR genre LIKE ?
                   OR lieu_naissance LIKE ?
                   OR nationalite LIKE ?
                   OR etat_civil LIKE ?
                   OR personne_contact LIKE ?
                   OR personne_contact_telephone LIKE ?
                   OR observations LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 13; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['nom'],
                'subtitle' => 'Tél: ' . ($row['gsm'] ?: 'N/A') . ' | Adresse: ' . ($row['adresse'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchEntreprises($searchTerm) {
        // Recherche dans TOUS les champs de la table entreprises
        $sql = "SELECT id, designation, rccm, siege_social, gsm, email, created_at,
                       'entreprise' as type, 'Entreprise' as type_label
                FROM entreprises 
                WHERE designation LIKE ? 
                   OR rccm LIKE ? 
                   OR siege_social LIKE ? 
                   OR gsm LIKE ? 
                   OR email LIKE ?
                   OR personne_contact LIKE ?
                   OR fonction_contact LIKE ?
                   OR telephone_contact LIKE ?
                   OR secteur LIKE ?
                   OR observations LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 10; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['designation'],
                'subtitle' => 'RCCM: ' . ($row['rccm'] ?: 'N/A') . ' | Tél: ' . ($row['gsm'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchContraventions($searchTerm) {
        // Recherche dans TOUS les champs de la table contraventions
        $sql = "SELECT id, type_infraction, lieu, description, amende, date_infraction, created_at,
                       'contravention' as type, 'Contravention' as type_label
                FROM contraventions 
                WHERE type_infraction LIKE ? 
                   OR lieu LIKE ? 
                   OR description LIKE ? 
                   OR reference_loi LIKE ?
                   OR amende LIKE ?
                   OR dossier_id LIKE ?
                   OR type_dossier LIKE ?
                   OR payed LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 8; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['type_infraction'],
                'subtitle' => 'Lieu: ' . ($row['lieu'] ?: 'N/A') . ' | Amende: ' . ($row['amende'] ?: 'N/A') . ' FC',
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchAccidents($searchTerm) {
        // Recherche dans TOUS les champs de la table accidents
        $sql = "SELECT id, lieu, gravite, description, date_accident, created_at,
                       'accident' as type, 'Accident' as type_label
                FROM accidents 
                WHERE lieu LIKE ? 
                   OR description LIKE ? 
                   OR gravite LIKE ?
                   OR images LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 4; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Accident - ' . $row['lieu'],
                'subtitle' => 'Gravité: ' . ($row['gravite'] ?: 'N/A') . ' | Date: ' . date('d/m/Y', strtotime($row['date_accident'])),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchArrestations($searchTerm) {
        // Recherche dans TOUS les champs de la table arrestations
        $sql = "SELECT a.id, a.motif, a.lieu, a.date_arrestation, a.created_at,
                       p.nom as particulier_nom,
                       'arrestation' as type, 'Arrestation' as type_label
                FROM arrestations a
                LEFT JOIN particuliers p ON a.particulier_id = p.id
                WHERE a.motif LIKE ? 
                   OR a.lieu LIKE ? 
                   OR a.created_by LIKE ?
                   OR p.nom LIKE ?
                ORDER BY a.created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 4; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Arrestation - ' . ($row['particulier_nom'] ?: 'N/A'),
                'subtitle' => 'Motif: ' . substr($row['motif'], 0, 50) . ' | Lieu: ' . ($row['lieu'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchUsers($searchTerm) {
        // Recherche dans TOUS les champs de la table users
        $sql = "SELECT id, username, matricule, telephone, role, poste, created_at,
                       'user' as type, 'Utilisateur/Agent' as type_label
                FROM users 
                WHERE username LIKE ? 
                   OR matricule LIKE ? 
                   OR telephone LIKE ? 
                   OR role LIKE ?
                   OR poste LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 5; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['username'],
                'subtitle' => 'Matricule: ' . ($row['matricule'] ?: 'N/A') . ' | Rôle: ' . ($row['role'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchAvisRecherche($searchTerm) {
        // Recherche dans TOUS les champs de la table avis_recherche
        $sql = "SELECT id, cible_type, cible_id, motif, niveau, created_at,
                       'avis_recherche' as type, 'Avis de recherche' as type_label
                FROM avis_recherche 
                WHERE motif LIKE ? 
                   OR cible_type LIKE ? 
                   OR niveau LIKE ?
                   OR created_by LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 4; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Avis de recherche - ' . $row['cible_type'],
                'subtitle' => 'Niveau: ' . ($row['niveau'] ?: 'N/A') . ' | Motif: ' . substr($row['motif'], 0, 30),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchPermisTemporaire($searchTerm) {
        // Recherche dans TOUS les champs de la table permis_temporaire
        $sql = "SELECT id, numero, cible_type, cible_id, motif, created_at,
                       'permis_temporaire' as type, 'Permis temporaire' as type_label
                FROM permis_temporaire 
                WHERE numero LIKE ? 
                   OR motif LIKE ? 
                   OR cible_type LIKE ?
                   OR created_by LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 4; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Permis temporaire - ' . $row['numero'],
                'subtitle' => 'Type: ' . ($row['cible_type'] ?: 'N/A') . ' | Motif: ' . substr($row['motif'], 0, 30),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchTemoins($searchTerm) {
        // Recherche dans TOUS les champs de la table temoins
        $sql = "SELECT id, nom, telephone, age, lien_avec_accident, temoignage, created_at,
                       'temoin' as type, 'Témoin' as type_label
                FROM temoins 
                WHERE nom LIKE ? 
                   OR telephone LIKE ? 
                   OR age LIKE ?
                   OR lien_avec_accident LIKE ?
                   OR temoignage LIKE ?
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 5; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Témoin - ' . $row['nom'],
                'subtitle' => 'Tél: ' . ($row['telephone'] ?: 'N/A') . ' | Lien: ' . substr($row['lien_avec_accident'], 0, 30),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchAssurances($searchTerm) {
        // Recherche dans TOUS les champs de la table assurance_vehicule
        $sql = "SELECT av.id, av.societe_assurance, av.nume_assurance, av.type_couverture, av.created_at,
                       vp.plaque as vehicule_plaque,
                       'assurance' as type, 'Assurance véhicule' as type_label
                FROM assurance_vehicule av
                LEFT JOIN vehicule_plaque vp ON av.vehicule_plaque_id = vp.id
                WHERE av.societe_assurance LIKE ? 
                   OR av.nume_assurance LIKE ? 
                   OR av.type_couverture LIKE ?
                   OR av.notes LIKE ?
                   OR vp.plaque LIKE ?
                ORDER BY av.created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        for ($i = 1; $i <= 5; $i++) {
            $stmt->bindValue($i, $searchTerm);
        }
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => 'Assurance - ' . ($row['societe_assurance'] ?: 'N/A'),
                'subtitle' => 'Police: ' . ($row['nume_assurance'] ?: 'N/A') . ' | Véhicule: ' . ($row['vehicule_plaque'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    public function getDetails($type, $id) {
        try {
            switch ($type) {
                case 'vehicule':
                    return $this->getVehiculeDetails($id);
                case 'particulier':
                    return $this->getParticulierDetails($id);
                case 'entreprise':
                    return $this->getEntrepriseDetails($id);
                case 'contravention':
                    return $this->getContraventionDetails($id);
                case 'accident':
                    return $this->getAccidentDetails($id);
                case 'arrestation':
                    return $this->getArrestationDetails($id);
                case 'user':
                    return $this->getUserDetails($id);
                case 'avis_recherche':
                    return $this->getAvisRechercheDetails($id);
                case 'permis_temporaire':
                    return $this->getPermisTemporaireDetails($id);
                case 'temoin':
                    return $this->getTemoinDetails($id);
                case 'assurance':
                    return $this->getAssuranceDetails($id);
                default:
                    return [
                        'success' => false,
                        'message' => 'Type non supporté: ' . $type
                    ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération des détails: ' . $e->getMessage()
            ];
        }
    }
    
    private function getVehiculeDetails($id) {
        // Données principales du véhicule
        $sql = "SELECT * FROM vehicule_plaque WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $vehicule = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$vehicule) {
            return ['success' => false, 'message' => 'Véhicule non trouvé'];
        }
        
        // Données du conducteur/particulier
        $conducteur = null;
        if ($vehicule['conducteur_id']) {
            $sql = "SELECT * FROM particuliers WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':id', $vehicule['conducteur_id']);
            $stmt->execute();
            $conducteur = $stmt->fetch(PDO::FETCH_ASSOC);
        }
        
        // Contraventions liées
        $sql = "SELECT * FROM contraventions WHERE dossier_id = :id AND type_dossier = 'vehicule_plaque' ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Assurances liées
        $sql = "SELECT * FROM assurance_vehicule WHERE vehicule_plaque_id = :id ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $assurances = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'type' => 'vehicule',
            'main_data' => $vehicule,
            'related_data' => [
                'conducteur' => $conducteur,
                'contraventions' => $contraventions,
                'assurances' => $assurances
            ]
        ];
    }
    
    private function getParticulierDetails($id) {
        // Données principales du particulier
        $sql = "SELECT * FROM particuliers WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $particulier = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$particulier) {
            return ['success' => false, 'message' => 'Particulier non trouvé'];
        }
        
        // Véhicules liés
        $sql = "SELECT * FROM vehicule_plaque WHERE conducteur_id = :id ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $vehicules = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Contraventions liées
        $sql = "SELECT * FROM contraventions WHERE dossier_id = :id AND type_dossier = 'particulier' ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Arrestations liées
        $sql = "SELECT * FROM arrestations WHERE particulier_id = :id ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $arrestations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'type' => 'particulier',
            'main_data' => $particulier,
            'related_data' => [
                'vehicules' => $vehicules,
                'contraventions' => $contraventions,
                'arrestations' => $arrestations
            ]
        ];
    }
    
    private function getEntrepriseDetails($id) {
        // Données principales de l'entreprise
        $sql = "SELECT * FROM entreprises WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $entreprise = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$entreprise) {
            return ['success' => false, 'message' => 'Entreprise non trouvée'];
        }
        
        // Contraventions liées
        $sql = "SELECT * FROM contraventions WHERE dossier_id = :id AND type_dossier = 'entreprise' ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $contraventions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'type' => 'entreprise',
            'main_data' => $entreprise,
            'related_data' => [
                'contraventions' => $contraventions
            ]
        ];
    }
    
    private function getContraventionDetails($id) {
        // Données principales de la contravention
        $sql = "SELECT * FROM contraventions WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $contravention = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$contravention) {
            return ['success' => false, 'message' => 'Contravention non trouvée'];
        }
        
        // Données liées selon le type de dossier
        $relatedData = [];
        if ($contravention['type_dossier'] === 'vehicule_plaque') {
            $sql = "SELECT * FROM vehicule_plaque WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':id', $contravention['dossier_id']);
            $stmt->execute();
            $relatedData['vehicule'] = $stmt->fetch(PDO::FETCH_ASSOC);
        } elseif ($contravention['type_dossier'] === 'particulier') {
            $sql = "SELECT * FROM particuliers WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':id', $contravention['dossier_id']);
            $stmt->execute();
            $relatedData['particulier'] = $stmt->fetch(PDO::FETCH_ASSOC);
        } elseif ($contravention['type_dossier'] === 'entreprise') {
            $sql = "SELECT * FROM entreprises WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':id', $contravention['dossier_id']);
            $stmt->execute();
            $relatedData['entreprise'] = $stmt->fetch(PDO::FETCH_ASSOC);
        }
        
        return [
            'success' => true,
            'type' => 'contravention',
            'main_data' => $contravention,
            'related_data' => $relatedData
        ];
    }
    
    private function getAccidentDetails($id) {
        // Données principales de l'accident
        $sql = "SELECT * FROM accidents WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $accident = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$accident) {
            return ['success' => false, 'message' => 'Accident non trouvé'];
        }
        
        // Témoins liés
        $sql = "SELECT * FROM temoins WHERE id_accident = :id ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $temoins = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'type' => 'accident',
            'main_data' => $accident,
            'related_data' => [
                'temoins' => $temoins
            ]
        ];
    }
    
    private function getArrestationDetails($id) {
        $sql = "SELECT a.*, p.nom as particulier_nom, p.gsm as particulier_gsm 
                FROM arrestations a
                LEFT JOIN particuliers p ON a.particulier_id = p.id
                WHERE a.id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $arrestation = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$arrestation) {
            return ['success' => false, 'message' => 'Arrestation non trouvée'];
        }
        
        return [
            'success' => true,
            'type' => 'arrestation',
            'main_data' => $arrestation,
            'related_data' => []
        ];
    }
    
    private function getUserDetails($id) {
        $sql = "SELECT * FROM users WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            return ['success' => false, 'message' => 'Utilisateur non trouvé'];
        }
        
        // Ne pas retourner le mot de passe
        unset($user['password']);
        
        return [
            'success' => true,
            'type' => 'user',
            'main_data' => $user,
            'related_data' => []
        ];
    }
    
    private function getAvisRechercheDetails($id) {
        $sql = "SELECT * FROM avis_recherche WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $avis = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$avis) {
            return ['success' => false, 'message' => 'Avis de recherche non trouvé'];
        }
        
        return [
            'success' => true,
            'type' => 'avis_recherche',
            'main_data' => $avis,
            'related_data' => []
        ];
    }
    
    private function getPermisTemporaireDetails($id) {
        $sql = "SELECT * FROM permis_temporaire WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $permis = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$permis) {
            return ['success' => false, 'message' => 'Permis temporaire non trouvé'];
        }
        
        return [
            'success' => true,
            'type' => 'permis_temporaire',
            'main_data' => $permis,
            'related_data' => []
        ];
    }
    
    private function getTemoinDetails($id) {
        $sql = "SELECT t.*, a.lieu as accident_lieu, a.date_accident 
                FROM temoins t
                LEFT JOIN accidents a ON t.id_accident = a.id
                WHERE t.id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $temoin = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$temoin) {
            return ['success' => false, 'message' => 'Témoin non trouvé'];
        }
        
        return [
            'success' => true,
            'type' => 'temoin',
            'main_data' => $temoin,
            'related_data' => []
        ];
    }
    
    private function getAssuranceDetails($id) {
        $sql = "SELECT av.*, vp.plaque, vp.marque, vp.modele 
                FROM assurance_vehicule av
                LEFT JOIN vehicule_plaque vp ON av.vehicule_plaque_id = vp.id
                WHERE av.id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $assurance = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$assurance) {
            return ['success' => false, 'message' => 'Assurance non trouvée'];
        }
        
        return [
            'success' => true,
            'type' => 'assurance',
            'main_data' => $assurance,
            'related_data' => []
        ];
    }
}
?>
