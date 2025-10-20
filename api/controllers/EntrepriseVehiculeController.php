<?php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/BaseController.php';

class EntrepriseVehiculeController extends BaseController
{
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Vérifier si un véhicule a déjà des affectations
     */
    public function checkExistingAssociation($vehiculePlaqueId)
    {
        try {
            if (empty($vehiculePlaqueId) || !is_numeric($vehiculePlaqueId)) {
                return [
                    'success' => false,
                    'message' => 'ID véhicule invalide'
                ];
            }

            // Vérifier dans particulier_vehicule
            $stmtParticulier = $this->db->prepare("
                SELECT COUNT(*) as count FROM particulier_vehicule 
                WHERE vehicule_plaque_id = :vehicule_id
            ");
            $stmtParticulier->execute([':vehicule_id' => $vehiculePlaqueId]);
            $countParticulier = $stmtParticulier->fetch(PDO::FETCH_ASSOC)['count'];

            // Vérifier dans entreprise_vehicule
            $stmtEntreprise = $this->db->prepare("
                SELECT COUNT(*) as count FROM entreprise_vehicule 
                WHERE vehicule_plaque_id = :vehicule_id
            ");
            $stmtEntreprise->execute([':vehicule_id' => $vehiculePlaqueId]);
            $countEntreprise = $stmtEntreprise->fetch(PDO::FETCH_ASSOC)['count'];

            $hasAssociations = ($countParticulier > 0 || $countEntreprise > 0);

            return [
                'success' => true,
                'hasAssociations' => $hasAssociations,
                'countParticulier' => (int)$countParticulier,
                'countEntreprise' => (int)$countEntreprise,
                'totalCount' => (int)($countParticulier + $countEntreprise)
            ];
        } catch (PDOException $e) {
            error_log("Erreur vérification associations: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la vérification: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer le propriétaire actuel (le plus récent)
     */
    public function getCurrentOwner($vehiculePlaqueId)
    {
        try {
            if (empty($vehiculePlaqueId) || !is_numeric($vehiculePlaqueId)) {
                return [
                    'success' => false,
                    'message' => 'ID véhicule invalide'
                ];
            }

            // Récupérer le particulier le plus récent
            $stmtParticulier = $this->db->prepare("
                SELECT 
                    pv.id,
                    pv.role,
                    pv.date_assoc,
                    pv.created_at,
                    p.nom,
                    p.prenom,
                    p.gsm,
                    'particulier' as owner_type,
                    p.id as owner_id
                FROM particulier_vehicule pv
                INNER JOIN particuliers p ON pv.particulier_id = p.id
                WHERE pv.vehicule_plaque_id = :vehicule_id
                ORDER BY pv.date_assoc DESC, pv.created_at DESC
                LIMIT 1
            ");
            $stmtParticulier->execute([':vehicule_id' => $vehiculePlaqueId]);
            $particulier = $stmtParticulier->fetch(PDO::FETCH_ASSOC);

            // Récupérer l'entreprise la plus récente
            $stmtEntreprise = $this->db->prepare("
                SELECT 
                    ev.id,
                    ev.date_assoc,
                    ev.created_at,
                    e.designation,
                    e.rccm,
                    e.gsm,
                    'entreprise' as owner_type,
                    e.id as owner_id
                FROM entreprise_vehicule ev
                INNER JOIN entreprises e ON ev.entreprise_id = e.id
                WHERE ev.vehicule_plaque_id = :vehicule_id
                ORDER BY ev.date_assoc DESC, ev.created_at DESC
                LIMIT 1
            ");
            $stmtEntreprise->execute([':vehicule_id' => $vehiculePlaqueId]);
            $entreprise = $stmtEntreprise->fetch(PDO::FETCH_ASSOC);

            // Comparer les dates pour déterminer le propriétaire le plus récent
            $currentOwner = null;
            if ($particulier && $entreprise) {
                $dateParticulier = strtotime($particulier['date_assoc'] ?? $particulier['created_at']);
                $dateEntreprise = strtotime($entreprise['date_assoc'] ?? $entreprise['created_at']);
                $currentOwner = ($dateParticulier > $dateEntreprise) ? $particulier : $entreprise;
            } elseif ($particulier) {
                $currentOwner = $particulier;
            } elseif ($entreprise) {
                $currentOwner = $entreprise;
            }

            return [
                'success' => true,
                'currentOwner' => $currentOwner
            ];
        } catch (PDOException $e) {
            error_log("Erreur récupération propriétaire actuel: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Associer une entreprise à un véhicule
     */
    public function associer($entrepriseId, $vehiculePlaqueId, $dateAssoc = null, $notes = null, $createdBy = null, $force = false)
    {
        try {
            // Validation
            if (empty($entrepriseId) || empty($vehiculePlaqueId)) {
                return [
                    'success' => false,
                    'message' => 'L\'ID de l\'entreprise et l\'ID du véhicule sont requis'
                ];
            }

            // Vérifier si l'entreprise existe
            $stmtEntreprise = $this->db->prepare("SELECT id FROM entreprises WHERE id = :id");
            $stmtEntreprise->execute([':id' => $entrepriseId]);
            if ($stmtEntreprise->rowCount() === 0) {
                return [
                    'success' => false,
                    'message' => 'Entreprise non trouvée'
                ];
            }

            // Vérifier si le véhicule existe
            $stmtVehicule = $this->db->prepare("SELECT id FROM vehicule_plaque WHERE id = :id");
            $stmtVehicule->execute([':id' => $vehiculePlaqueId]);
            if ($stmtVehicule->rowCount() === 0) {
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }

            // Vérifier les affectations existantes si force n'est pas activé
            if (!$force) {
                $checkResult = $this->checkExistingAssociation($vehiculePlaqueId);
                if ($checkResult['success'] && $checkResult['hasAssociations']) {
                    // Récupérer le propriétaire actuel
                    $ownerResult = $this->getCurrentOwner($vehiculePlaqueId);
                    $currentOwner = $ownerResult['currentOwner'] ?? null;

                    return [
                        'success' => false,
                        'requiresConfirmation' => true,
                        'message' => 'Ce véhicule est déjà affecté à un propriétaire',
                        'existingAssociations' => [
                            'countParticulier' => $checkResult['countParticulier'],
                            'countEntreprise' => $checkResult['countEntreprise'],
                            'totalCount' => $checkResult['totalCount']
                        ],
                        'currentOwner' => $currentOwner
                    ];
                }
            }

            // Insertion (toujours créer un nouvel enregistrement pour l'historique)
            $stmt = $this->db->prepare("
                INSERT INTO entreprise_vehicule 
                (entreprise_id, vehicule_plaque_id, date_assoc, notes, created_at, created_by)
                VALUES 
                (:entreprise_id, :vehicule_plaque_id, :date_assoc, :notes, NOW(), :created_by)
            ");

            $stmt->execute([
                ':entreprise_id' => $entrepriseId,
                ':vehicule_plaque_id' => $vehiculePlaqueId,
                ':date_assoc' => $dateAssoc ?? date('Y-m-d H:i:s'),
                ':notes' => $notes,
                ':created_by' => $createdBy
            ]);

            $associationId = $this->db->lastInsertId();

            return [
                'success' => true,
                'message' => 'Association créée avec succès',
                'id' => $associationId
            ];
        } catch (PDOException $e) {
            error_log("Erreur association entreprise-véhicule: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'association: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer tous les véhicules d'une entreprise
     */
    public function getVehiculesByEntreprise($entrepriseId)
    {
        try {
            if (empty($entrepriseId) || !is_numeric($entrepriseId)) {
                return [
                    'success' => false,
                    'message' => 'ID entreprise invalide'
                ];
            }

            $stmt = $this->db->prepare("
                SELECT 
                    ev.*,
                    vp.plaque,
                    vp.marque,
                    vp.modele,
                    vp.couleur,
                    vp.numero_chassis
                FROM entreprise_vehicule ev
                INNER JOIN vehicule_plaque vp ON ev.vehicule_plaque_id = vp.id
                WHERE ev.entreprise_id = :entreprise_id
                ORDER BY ev.date_assoc DESC, ev.created_at DESC
            ");

            $stmt->execute([':entreprise_id' => $entrepriseId]);
            $vehicules = $stmt->fetchAll(PDO::FETCH_ASSOC);

            return [
                'success' => true,
                'data' => $vehicules
            ];
        } catch (PDOException $e) {
            error_log("Erreur récupération véhicules entreprise: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer toutes les entreprises d'un véhicule
     */
    public function getEntreprisesByVehicule($vehiculePlaqueId)
    {
        try {
            if (empty($vehiculePlaqueId) || !is_numeric($vehiculePlaqueId)) {
                return [
                    'success' => false,
                    'message' => 'ID véhicule invalide'
                ];
            }

            $stmt = $this->db->prepare("
                SELECT 
                    ev.*,
                    e.designation,
                    e.rccm,
                    COALESCE(e.telephone_contact, e.gsm) as telephone,
                    e.email,
                    e.siege_social
                FROM entreprise_vehicule ev
                INNER JOIN entreprises e ON ev.entreprise_id = e.id
                WHERE ev.vehicule_plaque_id = :vehicule_plaque_id
                ORDER BY ev.date_assoc DESC, ev.created_at DESC
            ");

            $stmt->execute([':vehicule_plaque_id' => $vehiculePlaqueId]);
            $entreprises = $stmt->fetchAll(PDO::FETCH_ASSOC);

            return [
                'success' => true,
                'data' => $entreprises
            ];
        } catch (PDOException $e) {
            error_log("Erreur récupération entreprises véhicule: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Supprimer une association
     */
    public function dissocier($associationId)
    {
        try {
            if (empty($associationId) || !is_numeric($associationId)) {
                return [
                    'success' => false,
                    'message' => 'ID association invalide'
                ];
            }

            $stmt = $this->db->prepare("DELETE FROM entreprise_vehicule WHERE id = :id");
            $stmt->execute([':id' => $associationId]);

            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'message' => 'Association supprimée avec succès'
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Association non trouvée'
                ];
            }
        } catch (PDOException $e) {
            error_log("Erreur suppression association: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ];
        }
    }
}
