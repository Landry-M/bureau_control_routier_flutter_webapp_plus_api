<?php
require_once __DIR__ . '/BaseController.php';

/**
 * Vehicule Controller
 */
class VehiculeController extends BaseController {
    
    public function __construct() {
        parent::__construct();
        $this->table = 'vehicules';
    }
    
    /**
     * Create new vehicule with full details
     */
    public function create($data) {
        try {
            $query = "INSERT INTO {$this->table} (plaque, marque, modele, couleur, proprietaire_id, statut, created_at) 
                     VALUES (:plaque, :marque, :modele, :couleur, :proprietaire_id, :statut, NOW())";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':plaque', $data['plaque']);
            $stmt->bindParam(':marque', $data['marque']);
            $stmt->bindParam(':modele', $data['modele']);
            $stmt->bindParam(':couleur', $data['couleur']);
            $stmt->bindParam(':proprietaire_id', $data['proprietaire_id']);
            $stmt->bindParam(':statut', $data['statut'] ?? 'actif');
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule créé avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la création du véhicule'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Check if a plaque already exists in the database
     */
    public function plaqueExists($plaque) {
        try {
            $query = "SELECT COUNT(*) as count FROM vehicule_plaque WHERE plaque = :plaque";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':plaque', $plaque);
            $stmt->execute();
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['count'] > 0;
        } catch (Exception $e) {
            // En cas d'erreur, on considère que la plaque existe pour éviter les doublons
            return true;
        }
    }

    /**
     * Create vehicule with full details and optional contravention
     */
    public function createWithDetails($data, $vehicleImages = [], $contraventionImages = []) {
        try {
            // Helper function for safe data access
            $f = function($k, $def = null) use ($data) { 
                return isset($data[$k]) && $data[$k] !== '' ? $data[$k] : $def; 
            };

            // Vérifier l'unicité de la plaque
            $plaque = $f('plaque');
            if (!$plaque || trim($plaque) === '') {
                return [
                    'success' => false,
                    'message' => 'Le numéro de plaque est requis'
                ];
            }

            if ($this->plaqueExists($plaque)) {
                return [
                    'success' => false,
                    'message' => 'Plaque déjà utilisée'
                ];
            }

            $this->db->beginTransaction();

            // Insert into vehicule_plaque
            $stmt = $this->db->prepare("INSERT INTO vehicule_plaque (
                images, marque, modele, annee, couleur, numero_chassis, frontiere_entree, date_importation,
                plaque, plaque_valide_le, plaque_expire_le,
                nume_assurance, societe_assurance, date_valide_assurance, date_expire_assurance,
                genre, `usage`, numero_declaration, num_moteur, origine, source, annee_fab, annee_circ, type_em,
                en_circulation, created_at, updated_at
            ) VALUES (
                :images, :marque, :modele, :annee, :couleur, :numero_chassis, :frontiere_entree, :date_importation,
                :plaque, :plaque_valide_le, :plaque_expire_le,
                :nume_assurance, :societe_assurance, :date_valide_assurance, :date_expire_assurance,
                :genre, :usage, :numero_declaration, :num_moteur, :origine, :source, :annee_fab, :annee_circ, :type_em,
                :en_circulation, NOW(), NOW()
            )");

            $stmt->bindValue(':images', json_encode($vehicleImages));
            $stmt->bindValue(':marque', $f('marque'));
            $stmt->bindValue(':modele', $f('modele'));
            $stmt->bindValue(':annee', $f('annee'));
            $stmt->bindValue(':couleur', $f('couleur'));
            $stmt->bindValue(':numero_chassis', $f('numero_chassis'));
            $stmt->bindValue(':frontiere_entree', $f('frontiere_entree'));
            $stmt->bindValue(':date_importation', $f('date_importation'));
            $stmt->bindValue(':plaque', $f('plaque'));
            $stmt->bindValue(':plaque_valide_le', $f('plaque_valide_le'));
            $stmt->bindValue(':plaque_expire_le', $f('plaque_expire_le'));
            $stmt->bindValue(':nume_assurance', $f('nume_assurance'));
            $stmt->bindValue(':societe_assurance', $f('societe_assurance'));
            $stmt->bindValue(':date_valide_assurance', $f('date_valide_assurance'));
            $stmt->bindValue(':date_expire_assurance', $f('date_expire_assurance'));
            $stmt->bindValue(':genre', $f('genre'));
            $stmt->bindValue(':usage', $f('usage'));
            $stmt->bindValue(':numero_declaration', $f('numero_declaration'));
            $stmt->bindValue(':num_moteur', $f('num_moteur'));
            $stmt->bindValue(':origine', $f('origine'));
            $stmt->bindValue(':source', $f('source'));
            $stmt->bindValue(':annee_fab', $f('annee_fab'));
            $stmt->bindValue(':annee_circ', $f('annee_circ'));
            $stmt->bindValue(':type_em', $f('type_em'));
            $stmt->bindValue(':en_circulation', $f('en_circulation', '1'));

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de l\'insertion du véhicule');
            }

            $vehicleId = $this->db->lastInsertId();

            // Automatically create assurance record if assurance fields are provided
            $this->createAssuranceIfNeeded($vehicleId, $data);

            // Optionally create contravention
            $withCv = $f('with_contravention', '0');
            if ($withCv === '1') {
                require_once __DIR__ . '/ContraventionController.php';
                $contraventionController = new ContraventionController();
                
                // Map contravention fields with cv_ prefix
                $cvDate = $f('cv_date_infraction');
                if (!$cvDate || trim((string)$cvDate) === '') { 
                    $cvDate = date('Y-m-d H:i:s'); 
                }
                
                $contraventionData = [
                    'dossier_id' => $vehicleId,
                    'type_dossier' => 'vehicule_plaque',
                    'date_infraction' => $cvDate,
                    'lieu' => $f('cv_lieu'),
                    'type_infraction' => $f('cv_type_infraction'),
                    'description' => $f('cv_description'),
                    'reference_loi' => $f('cv_reference_loi'),
                    'amende' => $f('cv_amende'),
                    'payed' => $f('cv_payed', '0') === '1' ? 'oui' : 'non',
                    'photos' => implode(',', $contraventionImages)
                ];

                $contraventionResult = $contraventionController->create($contraventionData);
                if (!$contraventionResult['success']) {
                    throw new Exception('Erreur lors de la création de la contravention: ' . $contraventionResult['message']);
                }
            }

            $this->db->commit();

            return [
                'success' => true,
                'message' => 'Véhicule créé avec succès' . ($withCv === '1' ? ' avec contravention' : ''),
                'id' => $vehicleId
            ];

        } catch (Exception $e) {
            $this->db->rollback();
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Create assurance record if assurance fields are provided
     */
    private function createAssuranceIfNeeded($vehicleId, $data) {
        // Helper function for safe data access
        $f = function($k, $def = null) use ($data) { 
            return isset($data[$k]) && $data[$k] !== '' ? $data[$k] : $def; 
        };

        // Check if any assurance field is provided
        $hasAssuranceData = false;
        $assuranceFields = [
            'societe_assurance', 'nume_assurance', 'date_valide_assurance', 
            'date_expire_assurance', 'montant_prime', 'type_couverture'
        ];

        foreach ($assuranceFields as $field) {
            if ($f($field) !== null) {
                $hasAssuranceData = true;
                break;
            }
        }

        if (!$hasAssuranceData) {
            return; // No assurance data provided
        }

        try {
            // Use AssuranceController for better organization
            require_once __DIR__ . '/AssuranceController.php';
            $assuranceController = new AssuranceController();
            
            $assuranceData = [
                'vehicule_plaque_id' => $vehicleId,
                'societe_assurance' => $f('societe_assurance'),
                'nume_assurance' => $f('nume_assurance'),
                'date_valide_assurance' => $f('date_valide_assurance'),
                'date_expire_assurance' => $f('date_expire_assurance'),
                'montant_prime' => $f('montant_prime'),
                'type_couverture' => $f('type_couverture'),
                'notes' => $f('notes_assurance')
            ];

            $assuranceResult = $assuranceController->create($assuranceData);
            if (!$assuranceResult['success']) {
                throw new Exception('Erreur lors de la création de l\'assurance: ' . $assuranceResult['message']);
            }

        } catch (Exception $e) {
            // Log the error but don't fail the vehicle creation
            error_log("Erreur création assurance: " . $e->getMessage());
        }
    }
    
    /**
     * Update vehicule with all fields
     */
    public function update($id, $data, $vehicleImages = []) {
        try {
            // Helper function for safe data access
            $f = function($k, $def = null) use ($data) { 
                return isset($data[$k]) && $data[$k] !== '' ? $data[$k] : $def; 
            };

            // Vérifier que le véhicule existe
            $checkQuery = "SELECT id FROM vehicule_plaque WHERE id = :id";
            $checkStmt = $this->db->prepare($checkQuery);
            $checkStmt->bindParam(':id', $id);
            $checkStmt->execute();
            
            if ($checkStmt->rowCount() === 0) {
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }

            // Vérifier l'unicité de la plaque si elle est modifiée
            $plaque = $f('plaque');
            if ($plaque && trim($plaque) !== '') {
                $plaqueCheckQuery = "SELECT COUNT(*) as count FROM vehicule_plaque WHERE plaque = :plaque AND id != :id";
                $plaqueCheckStmt = $this->db->prepare($plaqueCheckQuery);
                $plaqueCheckStmt->bindParam(':plaque', $plaque);
                $plaqueCheckStmt->bindParam(':id', $id);
                $plaqueCheckStmt->execute();
                
                $result = $plaqueCheckStmt->fetch(PDO::FETCH_ASSOC);
                if ($result['count'] > 0) {
                    return [
                        'success' => false,
                        'message' => 'Plaque déjà utilisée'
                    ];
                }
            }

            // Mise à jour complète avec tous les champs
            $query = "UPDATE vehicule_plaque SET 
                     images = :images,
                     marque = :marque,
                     annee = :annee,
                     couleur = :couleur,
                     modele = :modele,
                     numero_chassis = :numero_chassis,
                     frontiere_entree = :frontiere_entree,
                     date_importation = :date_importation,
                     plaque = :plaque,
                     plaque_valide_le = :plaque_valide_le,
                     plaque_expire_le = :plaque_expire_le,
                     en_circulation = :en_circulation,
                     nume_assurance = :nume_assurance,
                     date_expire_assurance = :date_expire_assurance,
                     date_valide_assurance = :date_valide_assurance,
                     societe_assurance = :societe_assurance,
                     genre = :genre,
                     `usage` = :usage,
                     numero_declaration = :numero_declaration,
                     num_moteur = :num_moteur,
                     origine = :origine,
                     source = :source,
                     annee_fab = :annee_fab,
                     annee_circ = :annee_circ,
                     type_em = :type_em,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            
            // Gestion des images
            $images = !empty($vehicleImages) ? json_encode($vehicleImages) : $f('images', '[]');
            
            $stmt->bindValue(':id', $id);
            $stmt->bindValue(':images', $images);
            $stmt->bindValue(':marque', $f('marque'));
            $stmt->bindValue(':annee', $f('annee'));
            $stmt->bindValue(':couleur', $f('couleur'));
            $stmt->bindValue(':modele', $f('modele'));
            $stmt->bindValue(':numero_chassis', $f('numero_chassis'));
            $stmt->bindValue(':frontiere_entree', $f('frontiere_entree'));
            $stmt->bindValue(':date_importation', $f('date_importation'));
            $stmt->bindValue(':plaque', $f('plaque'));
            $stmt->bindValue(':plaque_valide_le', $f('plaque_valide_le'));
            $stmt->bindValue(':plaque_expire_le', $f('plaque_expire_le'));
            $stmt->bindValue(':en_circulation', $f('en_circulation', '1'));
            $stmt->bindValue(':nume_assurance', $f('nume_assurance'));
            $stmt->bindValue(':date_expire_assurance', $f('date_expire_assurance'));
            $stmt->bindValue(':date_valide_assurance', $f('date_valide_assurance'));
            $stmt->bindValue(':societe_assurance', $f('societe_assurance'));
            $stmt->bindValue(':genre', $f('genre'));
            $stmt->bindValue(':usage', $f('usage'));
            $stmt->bindValue(':numero_declaration', $f('numero_declaration'));
            $stmt->bindValue(':num_moteur', $f('num_moteur'));
            $stmt->bindValue(':origine', $f('origine'));
            $stmt->bindValue(':source', $f('source'));
            $stmt->bindValue(':annee_fab', $f('annee_fab'));
            $stmt->bindValue(':annee_circ', $f('annee_circ'));
            $stmt->bindValue(':type_em', $f('type_em'));
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule mis à jour avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Get vehicule by plaque
     */
    public function getByPlaque($plaque) {
        try {
            $query = "SELECT v.*, p.nom as proprietaire_nom, p.prenom as proprietaire_prenom, p.gsm as proprietaire_gsm 
                     FROM {$this->table} v 
                     LEFT JOIN particuliers p ON v.proprietaire_id = p.id 
                     WHERE v.plaque = :plaque LIMIT 1";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':plaque', $plaque);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                return [
                    'success' => true,
                    'data' => $stmt->fetch(PDO::FETCH_ASSOC)
                ];
            } else {
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Retirer un vehicule (suspend)
     */
    public function retirer($id, $motif = '') {
        try {
            $query = "UPDATE {$this->table} SET statut = 'retiré', motif_retrait = :motif, date_retrait = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->bindParam(':motif', $motif);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule retiré avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait: ' . $e->getMessage()
            ];
        }
    }
    
    /**
     * Remettre un vehicule (reactivate)
     */
    public function remettre($id) {
        try {
            $query = "UPDATE {$this->table} SET statut = 'actif', motif_retrait = NULL, date_retrait = NULL, date_remise = NOW() WHERE id = :id";
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule remis en circulation avec succès'
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors de la remise en circulation'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la remise en circulation: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Retirer la plaque d'un véhicule
     */
    public function retirerPlaque($id, $agentUsername = null, $dateRetrait = null, $motif = null, $observations = null) {
        try {
            $this->db->beginTransaction();
            
            // Vérifier que le véhicule existe
            $checkQuery = "SELECT id, plaque FROM vehicule_plaque WHERE id = :id";
            $checkStmt = $this->db->prepare($checkQuery);
            $checkStmt->bindParam(':id', $id);
            $checkStmt->execute();
            
            if ($checkStmt->rowCount() === 0) {
                $this->db->rollBack();
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }
            
            $vehicule = $checkStmt->fetch(PDO::FETCH_ASSOC);
            $anciennePlaque = $vehicule['plaque'];
            
            // Enregistrer dans l'historique avant de retirer
            if ($anciennePlaque) {
                // Si pas de date fournie, utiliser la date actuelle
                $dateRetraitFinal = $dateRetrait ? $dateRetrait : date('Y-m-d H:i:s');
                
                $historiqueQuery = "INSERT INTO historique_retrait_plaques 
                                  (vehicule_plaque_id, ancienne_plaque, date_retrait, motif, username, observations) 
                                  VALUES (:vehicule_id, :plaque, :date_retrait, :motif, :agent, :observations)";
                $historiqueStmt = $this->db->prepare($historiqueQuery);
                $historiqueStmt->bindParam(':vehicule_id', $id);
                $historiqueStmt->bindParam(':plaque', $anciennePlaque);
                $historiqueStmt->bindParam(':date_retrait', $dateRetraitFinal);
                $historiqueStmt->bindParam(':motif', $motif);
                $historiqueStmt->bindParam(':agent', $agentUsername);
                $historiqueStmt->bindParam(':observations', $observations);
                $historiqueStmt->execute();
            }
            
            // Mettre à jour les champs plaque, plaque_valide_le et plaque_expire_le à NULL
            $query = "UPDATE vehicule_plaque SET 
                     plaque = NULL, 
                     plaque_valide_le = NULL, 
                     plaque_expire_le = NULL,
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            
            if ($stmt->execute()) {
                $this->db->commit();
                return [
                    'success' => true,
                    'message' => 'Plaque retirée avec succès et enregistrée dans l\'historique',
                    'ancienne_plaque' => $anciennePlaque
                ];
            }
            
            $this->db->rollBack();
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait de la plaque'
            ];
            
        } catch (Exception $e) {
            $this->db->rollBack();
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait de la plaque: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer l'historique des retraits de plaques pour un véhicule
     */
    public function getHistoriqueRetraits($vehiculeId) {
        try {
            $query = "SELECT * FROM historique_retraits_plaque 
                     WHERE vehicule_plaque_id = :vehicule_id 
                     ORDER BY date_retrait DESC";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':vehicule_id', $vehiculeId);
            $stmt->execute();
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'historique: ' . $e->getMessage(),
                'data' => []
            ];
        }
    }

    /**
     * Retirer un véhicule de la circulation
     */
    public function retirerDeCirculation($id) {
        try {
            // Vérifier que le véhicule existe
            $checkQuery = "SELECT id, plaque, en_circulation FROM vehicule_plaque WHERE id = :id";
            $checkStmt = $this->db->prepare($checkQuery);
            $checkStmt->bindParam(':id', $id);
            $checkStmt->execute();
            
            if ($checkStmt->rowCount() === 0) {
                return [
                    'success' => false,
                    'message' => 'Véhicule non trouvé'
                ];
            }
            
            $vehicule = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            // Vérifier si le véhicule est déjà retiré de la circulation
            if ($vehicule['en_circulation'] == '0') {
                return [
                    'success' => false,
                    'message' => 'Ce véhicule est déjà retiré de la circulation'
                ];
            }
            
            // Mettre à jour le champ en_circulation à 0
            $query = "UPDATE vehicule_plaque SET 
                     en_circulation = '0',
                     updated_at = NOW()
                     WHERE id = :id";
            
            $stmt = $this->db->prepare($query);
            $stmt->bindParam(':id', $id);
            
            if ($stmt->execute()) {
                return [
                    'success' => true,
                    'message' => 'Véhicule retiré de la circulation avec succès',
                    'plaque' => $vehicule['plaque']
                ];
            }
            
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait du véhicule de la circulation'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Erreur lors du retrait du véhicule: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Création rapide d'un véhicule avec champs minimum (pour les accidents)
     */
    public function quickCreate($data) {
        try {
            require_once __DIR__ . '/LogController.php';
            
            $f = function($key) use ($data) {
                return isset($data[$key]) && $data[$key] !== '' ? $data[$key] : null;
            };

            // Vérifier l'unicité de la plaque
            $plaque = $data['plaque'];
            if (!$plaque || trim($plaque) === '') {
                return [
                    'success' => false,
                    'message' => 'Le numéro de plaque est requis'
                ];
            }

            if ($this->plaqueExists($plaque)) {
                return [
                    'success' => false,
                    'message' => 'Plaque déjà utilisée'
                ];
            }

            $this->db->beginTransaction();

            // Insert into vehicule_plaque avec champs minimum
            $stmt = $this->db->prepare("INSERT INTO vehicule_plaque (
                plaque, marque, modele, couleur, annee, 
                en_circulation, created_at
            ) VALUES (
                :plaque, :marque, :modele, :couleur, :annee,
                '1', NOW()
            )");

            $marque = $f('marque');
            $modele = $f('modele');
            $couleur = $f('couleur');
            $annee = $f('annee');
            
            $stmt->bindParam(':plaque', $plaque);
            $stmt->bindParam(':marque', $marque);
            $stmt->bindParam(':modele', $modele);
            $stmt->bindParam(':couleur', $couleur);
            $stmt->bindParam(':annee', $annee);

            if (!$stmt->execute()) {
                $this->db->rollback();
                return [
                    'success' => false,
                    'message' => 'Erreur lors de la création du véhicule'
                ];
            }

            $vehicleId = $this->db->lastInsertId();

            // Log de la création
            LogController::record(
                $f('username') ?: 'system',
                'Création rapide véhicule',
                [
                    'vehicule_id' => $vehicleId,
                    'plaque' => $data['plaque'],
                    'marque' => $f('marque'),
                    'modele' => $f('modele'),
                    'couleur' => $f('couleur'),
                    'annee' => $f('annee'),
                    'action' => 'quick_create'
                ],
                $_SERVER['REMOTE_ADDR'] ?? null,
                $_SERVER['HTTP_USER_AGENT'] ?? null
            );

            $this->db->commit();

            return [
                'success' => true,
                'message' => 'Véhicule créé avec succès',
                'id' => $vehicleId
            ];

        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollback();
            }
            return [
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ];
        }
    }
}
?>
