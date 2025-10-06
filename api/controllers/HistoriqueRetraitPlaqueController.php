<?php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/BaseController.php';

class HistoriqueRetraitPlaqueController extends BaseController
{
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Créer un enregistrement d'historique de retrait de plaque
     */
    public function create($vehiculePlaqueId, $anciennePlaque, $dateRetrait, $motif = null, $observations = null, $username = null)
    {
        try {
            // Validation des données
            if (empty($vehiculePlaqueId) || empty($anciennePlaque)) {
                return [
                    'success' => false,
                    'message' => 'L\'ID du véhicule et l\'ancienne plaque sont requis'
                ];
            }

            // Insertion dans la table historique_retrait_plaques
            $stmt = $this->db->prepare("
                INSERT INTO historique_retrait_plaques 
                (vehicule_plaque_id, ancienne_plaque, date_retrait, motif, observations, username, created_at)
                VALUES 
                (:vehicule_plaque_id, :ancienne_plaque, :date_retrait, :motif, :observations, :username, NOW())
            ");

            $stmt->execute([
                ':vehicule_plaque_id' => $vehiculePlaqueId,
                ':ancienne_plaque' => $anciennePlaque,
                ':date_retrait' => $dateRetrait ?? date('Y-m-d H:i:s'),
                ':motif' => $motif,
                ':observations' => $observations,
                ':username' => $username
            ]);

            $historiqueId = $this->db->lastInsertId();

            return [
                'success' => true,
                'message' => 'Historique de retrait de plaque enregistré avec succès',
                'id' => $historiqueId
            ];
        } catch (PDOException $e) {
            error_log("Erreur création historique retrait plaque: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de l\'historique: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer l'historique des retraits de plaques pour un véhicule
     */
    public function getByVehiculeId($vehiculePlaqueId)
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
                    id,
                    vehicule_plaque_id,
                    ancienne_plaque,
                    date_retrait,
                    motif,
                    observations,
                    username,
                    created_at
                FROM historique_retrait_plaques
                WHERE vehicule_plaque_id = :vehicule_plaque_id
                ORDER BY date_retrait DESC, created_at DESC
            ");

            $stmt->execute([':vehicule_plaque_id' => $vehiculePlaqueId]);
            $historique = $stmt->fetchAll(PDO::FETCH_ASSOC);

            return [
                'success' => true,
                'data' => $historique
            ];
        } catch (PDOException $e) {
            error_log("Erreur récupération historique retrait plaque: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'historique: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Récupérer tous les historiques avec pagination
     */
    public function getAll($limit = 20, $offset = 0)
    {
        try {
            // Récupérer le total
            $stmtCount = $this->db->query("SELECT COUNT(*) as total FROM historique_retrait_plaques");
            $total = $stmtCount->fetch(PDO::FETCH_ASSOC)['total'];

            // Récupérer les données avec pagination
            $stmt = $this->db->prepare("
                SELECT 
                    hrp.*,
                    vp.plaque as plaque_actuelle,
                    vp.marque,
                    vp.modele
                FROM historique_retrait_plaques hrp
                LEFT JOIN vehicule_plaque vp ON hrp.vehicule_plaque_id = vp.id
                ORDER BY hrp.date_retrait DESC, hrp.created_at DESC
                LIMIT :limit OFFSET :offset
            ");

            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
            $stmt->execute();

            $historique = $stmt->fetchAll(PDO::FETCH_ASSOC);

            return [
                'success' => true,
                'data' => $historique,
                'pagination' => [
                    'total' => (int)$total,
                    'limit' => (int)$limit,
                    'offset' => (int)$offset
                ]
            ];
        } catch (PDOException $e) {
            error_log("Erreur récupération historique: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'historique: ' . $e->getMessage()
            ];
        }
    }
}
