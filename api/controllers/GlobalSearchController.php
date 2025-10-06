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
        $sql = "SELECT id, plaque, marque, modele, couleur, proprietaire, annee, created_at,
                       'vehicule' as type, 'Véhicule' as type_label
                FROM vehicule_plaque 
                WHERE plaque LIKE :search 
                   OR marque LIKE :search 
                   OR modele LIKE :search 
                   OR couleur LIKE :search 
                   OR proprietaire LIKE :search 
                   OR annee LIKE :search
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':search', $searchTerm);
        $stmt->execute();
        
        $results = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $results[] = [
                'id' => $row['id'],
                'type' => $row['type'],
                'type_label' => $row['type_label'],
                'title' => $row['plaque'] . ' - ' . $row['marque'] . ' ' . $row['modele'],
                'subtitle' => 'Propriétaire: ' . ($row['proprietaire'] ?: 'N/A') . ' | Couleur: ' . ($row['couleur'] ?: 'N/A'),
                'created_at' => $row['created_at'],
                'data' => $row
            ];
        }
        
        return $results;
    }
    
    private function searchParticuliers($searchTerm) {
        $sql = "SELECT id, nom, adresse, gsm, email, numero_national, created_at,
                       'particulier' as type, 'Particulier' as type_label
                FROM particuliers 
                WHERE nom LIKE :search 
                   OR adresse LIKE :search 
                   OR gsm LIKE :search 
                   OR email LIKE :search 
                   OR numero_national LIKE :search
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':search', $searchTerm);
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
        $sql = "SELECT id, designation, rccm, siege_social, gsm, email, created_at,
                       'entreprise' as type, 'Entreprise' as type_label
                FROM entreprises 
                WHERE designation LIKE :search 
                   OR rccm LIKE :search 
                   OR siege_social LIKE :search 
                   OR gsm LIKE :search 
                   OR email LIKE :search
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':search', $searchTerm);
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
        $sql = "SELECT id, type_infraction, lieu, description, amende, date_infraction, created_at,
                       'contravention' as type, 'Contravention' as type_label
                FROM contraventions 
                WHERE type_infraction LIKE :search 
                   OR lieu LIKE :search 
                   OR description LIKE :search 
                   OR reference_loi LIKE :search
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':search', $searchTerm);
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
        $sql = "SELECT id, lieu, gravite, description, date_accident, created_at,
                       'accident' as type, 'Accident' as type_label
                FROM accidents 
                WHERE lieu LIKE :search 
                   OR description LIKE :search 
                   OR gravite LIKE :search
                ORDER BY created_at DESC
                LIMIT 20";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':search', $searchTerm);
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
                default:
                    return [
                        'success' => false,
                        'message' => 'Type non supporté'
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
}
?>
