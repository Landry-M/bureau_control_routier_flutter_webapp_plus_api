## 📂 Base de données (SQL Schema)

### Table `users` (Gestion des agents)
Champs principaux :
- `id` (bigint, PK)
- `username` (varchar)
- `password` (hashé)
- `matricule` (varchar)
- `role` (varchar) → opj, admin, superadmin, etc.
- `first_connexion` (yes/no)
- `login_schedule` (text JSON : jours/heures autorisés)

📌 Formulaires côté Flutter :
- Login (matricule, mot de passe)
- Gestion compte agent (superadmin) → horaires, rôle, statut

📌 Endpoints API :
- `POST /auth/login`
- `POST /auth/change-password`
- `POST /auth/reset-password`
- `GET /users` (list)
- `POST /users/{id}/update`

---

### Table `vehicule_plaque` (Véhicules)
Champs :
- `id`, `plaque`, `marque`, `modele`, `annee`, `couleur`
- `numero_chassis`, `num_moteur`
- `societe_assurance`, `date_valide_assurance`, `date_expire_assurance`
- `en_circulation` (bool)
- `images` (longtext, liste chemins)

📌 Formulaires :
- Création véhicule (marque, modèle, plaque, etc.)
- Upload images
- Assurance (dates + société)

📌 Endpoints API :
- `POST /vehicule/create`
- `POST /vehicule/{id}/update`
- `POST /vehicule/{id}/retirer`
- `POST /vehicule/{id}/remettre`
- `GET /vehicule/{plaque}`

---

### Table `particuliers`
Champs :
- `id`, `nom`, `adresse`, `gsm`, `email`
- `numero_national`, `date_naissance`, `etat_civil`
- `permis_recto`, `permis_verso`, `permis_date_emission`, `permis_date_expiration`

📌 Formulaires :
- Création particulier
- Upload permis (recto/verso)
- Gestion infos personnelles

📌 Endpoints API :
- `POST /particulier/create`
- `POST /particulier/{id}/update`
- `GET /particulier/{id}`

---

### Table `entreprises`
Champs :
- `id`, `designation`, `siege_social`, `gsm`, `email`
- `rccm`, `secteur`, `personne_contact`, `telephone_contact`

📌 Formulaires :
- Création entreprise
- Assignation véhicule ou contravention

📌 Endpoints API :
- `POST /entreprise/create`
- `POST /entreprise/{id}/update`
- `GET /entreprise/{id}`

---

### Table `contraventions`
Champs :
- `id`, `dossier_id`, `date_infraction`, `lieu`
- `type_infraction`, `reference_loi`, `amende`, `payed`
- `photos` (liste chemins)

📌 Formulaires :
- Création contravention (date, lieu, type, montant, upload photos)

📌 Endpoints API :
- `POST /contravention/create`
- `GET /contravention/{id}`
- `GET /contravention/{id}/pdf`

---

### Table `accidents`
Champs :
- `id`, `date_accident`, `lieu`, `gravite`, `description`
- `images`

📌 Formulaires :
- Création rapport accident
- Upload photos
- Association véhicules (`accident_vehicules`)
- Association témoins (`temoins`)

📌 Endpoints API :
- `POST /accident/create`
- `POST /accident/{id}/update` (superadmin)
- `GET /accident/{id}`

---

### Table `avis_recherche`
Champs :
- `id`, `cible_type` (particulier/vehicule), `cible_id`
- `motif`, `niveau`, `statut`

📌 Formulaires :
- Création avis
- Clôture avis

📌 Endpoints API :
- `POST /avis-recherche/create`
- `POST /avis-recherche/{id}/close`
- `GET /avis-recherche/{id}`

---

### Table `permis_temporaire`
Champs :
- `id`, `cible_type`, `cible_id`, `numero`
- `motif`, `date_debut`, `date_fin`, `statut`
- `pdf_path`

📌 Formulaires :
- Création permis/plaque temporaire
- Prévisualisation PDF

📌 Endpoints API :
- `POST /permis-temporaire/create`
- `GET /permis-temporaire/{id}/pdf`

---

### Table `arrestations`
Champs :
- `id`, `particulier_id`, `motif`, `lieu`
- `date_arrestation`, `date_sortie_prison`

📌 Formulaires :
- Enregistrer arrestation
- Libérer particulier

📌 Endpoints API :
- `POST /arrestation/create`
- `POST /arrestation/{id}/release`
- `GET /particulier/{id}/arrestations`

---

### Table `activites` (Logs système)
Champs :
- `id`, `username`, `action`, `details_operation`
- `ip_address`, `user_agent`, `date_creation`

📌 Visible uniquement **superadmin**  
📌 Alimenté automatiquement lors des actions  

📌 Endpoints API :
- `GET /logs`  
- `POST /logs/add`
