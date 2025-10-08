<!-- Template de contravention pour prévisualisation et génération PDF -->
<div class="container" style="max-width: 800px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif; line-height: 1.4;">
    
    <!-- En-tête officiel -->
    <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #000; padding-bottom: 15px;">
        <h1 style="margin: 0; font-size: 24px; font-weight: bold; color: #000;">RÉPUBLIQUE DÉMOCRATIQUE DU CONGO</h1>
        <h2 style="margin: 5px 0; font-size: 18px; color: #000;">BUREAU DE CONTRÔLE ROUTIER</h2>
        <h3 style="margin: 5px 0; font-size: 16px; color: #000;">PROCÈS-VERBAL DE CONTRAVENTION</h3>
    </div>

    <!-- Numéro de contravention -->
    <div style="text-align: center; margin-bottom: 20px;">
        <strong style="font-size: 16px;">N° <input type="text" name="numero_contravention" style="border: none; border-bottom: 1px solid #000; text-align: center; font-weight: bold; background: transparent;" readonly /></strong>
    </div>

    <!-- Section Contrevenant -->
    <div id="section-contrevenant" style="margin-bottom: 25px;">
        <h4 style="background: #f0f0f0; padding: 8px; margin: 0 0 15px 0; font-size: 14px; border-left: 4px solid #000;">INFORMATIONS DU CONTREVENANT</h4>
        
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Nom et Prénom :</label>
                <input type="text" name="nom_prenom" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Sexe :</label>
                <div style="margin-top: 5px;">
                    <label style="font-weight: normal; margin-right: 15px;">
                        <input type="radio" name="sexe" value="masculin" style="margin-right: 5px;" /> Masculin
                    </label>
                    <label style="font-weight: normal;">
                        <input type="radio" name="sexe" value="feminin" style="margin-right: 5px;" /> Féminin
                    </label>
                </div>
            </div>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Date de naissance :</label>
                <input type="text" name="date_naissance" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">N° Pièce d'identité :</label>
                <input type="text" name="numero_identite" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
        </div>

        <div style="margin-bottom: 15px;">
            <label style="font-weight: bold; display: block; margin-bottom: 3px;">Adresse :</label>
            <input type="text" name="adresse" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Téléphone :</label>
                <input type="text" name="telephone" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Email :</label>
                <input type="text" name="email" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
        </div>
    </div>

    <!-- Section Véhicule -->
    <div style="margin-bottom: 25px;">
        <h4 style="background: #f0f0f0; padding: 8px; margin: 0 0 15px 0; font-size: 14px; border-left: 4px solid #000;">INFORMATIONS DU VÉHICULE</h4>
        
        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Marque :</label>
                <input type="text" name="marque_vehicule" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Immatriculation :</label>
                <input type="text" name="immatriculation" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Couleur :</label>
                <input type="text" name="couleur_vehicule" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
        </div>
    </div>

    <!-- Section Infraction -->
    <div style="margin-bottom: 25px;">
        <h4 style="background: #f0f0f0; padding: 8px; margin: 0 0 15px 0; font-size: 14px; border-left: 4px solid #000;">DÉTAILS DE L'INFRACTION</h4>
        
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Date :</label>
                <input type="text" name="date_infraction" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Heure :</label>
                <input type="text" name="heure_infraction" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
        </div>

        <div style="margin-bottom: 15px;">
            <label style="font-weight: bold; display: block; margin-bottom: 3px;">Lieu de l'infraction :</label>
            <input type="text" name="lieu_infraction" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
        </div>

        <div style="margin-bottom: 15px;">
            <label style="font-weight: bold; display: block; margin-bottom: 3px;">Description de l'infraction :</label>
            <textarea name="description_infraction" style="width: 100%; height: 60px; border: 1px solid #000; padding: 5px; background: transparent; resize: vertical;"></textarea>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Montant de l'amende (FC) :</label>
                <input type="text" name="montant_amende" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
            <div>
                <label style="font-weight: bold; display: block; margin-bottom: 3px;">Référence légale :</label>
                <input type="text" name="reference_legale" style="width: 100%; border: none; border-bottom: 1px solid #000; background: transparent;" />
            </div>
        </div>
    </div>

    <!-- Section Photos -->
    <div class="photo-section" style="margin-bottom: 25px;">
        <h4 style="background: #f0f0f0; padding: 8px; margin: 0 0 15px 0; font-size: 14px; border-left: 4px solid #000;">PHOTOS DE L'INFRACTION</h4>
        <div style="min-height: 100px; border: 1px dashed #ccc; padding: 10px; text-align: center; color: #666;">
            Photos de l'infraction (si disponibles)
        </div>
    </div>

    <!-- Section Observations -->
    <div style="margin-bottom: 30px;">
        <label style="font-weight: bold; display: block; margin-bottom: 3px;">Observations :</label>
        <textarea name="observations" style="width: 100%; height: 80px; border: 1px solid #000; padding: 5px; background: transparent; resize: vertical;"></textarea>
    </div>

    <!-- Section Signatures -->
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 50px; margin-top: 40px;">
        <div style="text-align: center;">
            <div style="height: 60px; border-bottom: 1px solid #000; margin-bottom: 5px;"></div>
            <strong>Signature de l'Agent</strong><br>
            <small>Date : _______________</small>
        </div>
        <div style="text-align: center;">
            <div style="height: 60px; border-bottom: 1px solid #000; margin-bottom: 5px;"></div>
            <strong>Signature du Contrevenant</strong><br>
            <small>(ou mention "Refus de signer")</small>
        </div>
    </div>

    <!-- Pied de page -->
    <div style="margin-top: 30px; text-align: center; font-size: 12px; color: #666; border-top: 1px solid #ccc; padding-top: 15px;">
        <p>Ce procès-verbal fait foi jusqu'à preuve du contraire</p>
        <p>Bureau de Contrôle Routier - République Démocratique du Congo</p>
    </div>
</div>
