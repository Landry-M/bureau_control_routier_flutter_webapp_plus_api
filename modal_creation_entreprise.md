# Modal de création d’entreprise — Spécification

## Objectif
Créer un modal Bootstrap pour l’enregistrement d’une entreprise, avec option d’attribution directe d’une contravention (switch), soumission AJAX, validations, et UX cohérente avec le système existant.

## Fichiers concernés
- `app/views/partials/_modal_enregistrement_entreprise.php` (modal HTML)
- `app/index.php` (routes API)
- `app/controllers/EntrepriseController.php` (create/createWithContravention)

## Structure du modal
```html
<!-- Modal: Création Entreprise -->
<div class="modal fade" id="entrepriseCreateModal" tabindex="-1" aria-labelledby="entrepriseCreateLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header bg-primary text-white">
        <h5 class="modal-title" id="entrepriseCreateLabel">
          <i class="ri-building-2-line me-2"></i>Enregistrer une entreprise
        </h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Fermer" id="ent_header_close"></button>
      </div>

      <form id="entrepriseCreateForm" enctype="multipart/form-data">
        <div class="modal-body">
          <!-- Alertes -->
          <div id="ent_alert_container"></div>

          <!-- Informations principales -->
          <div class="card mb-3">
            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Raison sociale</label>
                  <input type="text" class="form-control" name="raison_sociale" required>
                </div>
                <div class="col-md-3">
                  <label class="form-label">RCCM</label>
                  <input type="text" class="form-control" name="rccm">
                </div>
                <div class="col-md-3">
                  <label class="form-label">ID Nat.</label>
                  <input type="text" class="form-control" name="id_nat">
                </div>

                <div class="col-md-4">
                  <label class="form-label">Numéro d’impôt</label>
                  <input type="text" class="form-control" name="num_impot">
                </div>
                <div class="col-md-8">
                  <label class="form-label">Adresse</label>
                  <input type="text" class="form-control" name="adresse" required>
                </div>

                <div class="col-md-4">
                  <label class="form-label">Téléphone</label>
                  <input type="tel" class="form-control" name="telephone">
                </div>
                <div class="col-md-4">
                  <label class="form-label">Email</label>
                  <input type="email" class="form-control" name="email">
                </div>
                <div class="col-md-4">
                  <label class="form-label">Type d’activité</label>
                  <input type="text" class="form-control" name="type_activite">
                </div>
              </div>
            </div>
          </div>

          <!-- Représentant / Contact -->
          <div class="card mb-3">
            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Représentant légal</label>
                  <input type="text" class="form-control" name="representant_legal">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Téléphone représentant</label>
                  <input type="tel" class="form-control" name="telephone_representant">
                </div>

                <div class="col-md-6">
                  <label class="form-label">Personne à contacter</label>
                  <input type="text" class="form-control" name="personne_contact">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Téléphone contact</label>
                  <input type="tel" class="form-control" name="telephone_contact">
                </div>

                <div class="col-12">
                  <label class="form-label">Notes</label>
                  <textarea class="form-control" name="notes" rows="2"></textarea>
                </div>
              </div>
            </div>
          </div>

          <!-- Uploads (optionnels) -->
          <div class="card mb-3">
            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Logo (JPG/PNG, max 5MB)</label>
                  <input type="file" class="form-control" name="logo" accept=".jpg,.jpeg,.png">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Document (PDF, max 10MB)</label>
                  <input type="file" class="form-control" name="document" accept=".pdf">
                </div>
              </div>
            </div>
          </div>

          <!-- Switch: Attribution contravention -->
          <div class="form-check form-switch mb-2">
            <input class="form-check-input" type="checkbox" id="ent_toggle_contrav" />
            <label class="form-check-label" for="ent_toggle_contrav">
              Attribuer une contravention à l’enregistrement
            </label>
          </div>

          <!-- Section contravention (masquée par défaut) -->
          <div id="ent_contrav_section" class="card border-info d-none">
            <div class="card-header bg-info text-white">
              <i class="ri-alert-line me-1"></i>Informations contravention
            </div>
            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-4">
                  <label class="form-label">Date/heure</label>
                  <input type="datetime-local" class="form-control" id="c_date_heure">
                </div>
                <div class="col-md-8">
                  <label class="form-label">Lieu</label>
                  <input type="text" class="form-control" id="c_lieu">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Type d’infraction</label>
                  <input type="text" class="form-control" id="c_type_infraction" required>
                </div>
                <div class="col-md-3">
                  <label class="form-label">Réf. loi</label>
                  <input type="text" class="form-control" id="c_reference_loi">
                </div>
                <div class="col-md-3">
                  <label class="form-label">Montant amende</label>
                  <input type="number" min="0" step="0.01" class="form-control" id="c_montant">
                </div>
                <div class="col-md-12">
                  <label class="form-label">Description</label>
                  <textarea class="form-control" rows="2" id="c_description"></textarea>
                </div>
                <div class="col-md-12">
                  <div class="form-check">
                    <input class="form-check-input" type="checkbox" id="c_payee">
                    <label class="form-check-label" for="c_payee">Amende payée</label>
                  </div>
                </div>
                <div class="col-md-12">
                  <label class="form-label">Photos (JPG/PNG/GIF)</label>
                  <input type="file" class="form-control" id="c_photos" accept=".jpg,.jpeg,.png,.gif" multiple>
                  <div id="c_photos_preview" class="row g-2 mt-2"></div>
                </div>
              </div>
            </div>
          </div>

        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-light" data-bs-dismiss="modal" id="ent_btn_close">Fermer</button>
          <button type="submit" class="btn btn-primary" id="ent_btn_submit">
            <i class="ri-save-3-line me-1"></i>
            Enregistrer
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
```

## JavaScript (init, validations, soumission)
```html
<script>
(() => {
  const modalId = 'entrepriseCreateModal';
  const formId = 'entrepriseCreateForm';
  const toggleId = 'ent_toggle_contrav';
  const contravSectionId = 'ent_contrav_section';
  const alertBoxId = 'ent_alert_container';
  const btnSubmitId = 'ent_btn_submit';

  function setAlert(html, type='danger') {
    const c = document.getElementById(alertBoxId);
    if (!c) return;
    c.innerHTML = html ? `<div class="alert alert-${type}">${html}</div>` : '';
  }

  function toggleContravSection(show) {
    const section = document.getElementById(contravSectionId);
    if (!section) return;
    section.classList.toggle('d-none', !show);
  }

  function gatherContraventionData() {
    return {
      date_heure: document.getElementById('c_date_heure')?.value || '',
      lieu: document.getElementById('c_lieu')?.value || '',
      type_infraction: document.getElementById('c_type_infraction')?.value || '',
      reference_loi: document.getElementById('c_reference_loi')?.value || '',
      montant: document.getElementById('c_montant')?.value || '',
      description: document.getElementById('c_description')?.value || '',
      payee: document.getElementById('c_payee')?.checked || false,
      photos: document.getElementById('c_photos')?.files || null
    };
  }

  function validate(form) {
    const rs = form.querySelector('[name="raison_sociale"]')?.value?.trim();
    const adresse = form.querySelector('[name="adresse"]')?.value?.trim();
    if (!rs) return 'Veuillez saisir la raison sociale';
    if (!adresse) return 'Veuillez saisir l’adresse';
    if (document.getElementById(toggleId)?.checked) {
      const t = document.getElementById('c_type_infraction')?.value?.trim();
      if (!t) return 'Veuillez saisir le type d’infraction';
    }
    return '';
  }

  async function submitForm(e) {
    e.preventDefault();
    const form = e.currentTarget;
    setAlert('');
    const err = validate(form);
    if (err) { setAlert(err, 'danger'); return; }

    const btn = document.getElementById(btnSubmitId);
    const orig = btn.innerHTML;
    btn.disabled = true; btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Enregistrement...';

    const fd = new FormData(form);
    const withContrav = document.getElementById(toggleId)?.checked;

    // Append contravention fields if toggled
    if (withContrav) {
      const c = gatherContraventionData();
      Object.entries(c).forEach(([k,v]) => {
        if (k === 'photos' && v && v.length) {
          [...v].forEach(file => fd.append('contrav_photos[]', file));
        } else {
          fd.append(`contrav_${k}`, (typeof v === 'boolean') ? (v ? '1' : '0') : (v ?? ''));
        }
      });
    }

    const url = withContrav
      ? '/create-entreprise-with-contravention'
      : '/create-entreprise';

    try {
      const resp = await fetch(url, { method: 'POST', body: fd });
      const data = await resp.json();
      if (!resp.ok || data.status === 'error') {
        throw new Error(data.message || 'Erreur lors de la création');
      }
      setAlert('Entreprise créée avec succès.', 'success');
      // Option: ouvrir la prévisualisation contravention si créée
      if (withContrav && data.contravention_id) {
        window.open(`/contravention/${data.contravention_id}/preview`, '_blank');
      }
      // Reset form basique
      form.reset();
      toggleContravSection(false);
    } catch (ex) {
      setAlert(ex.message, 'danger');
    } finally {
      btn.disabled = false; btn.innerHTML = orig;
    }
  }

  function init() {
    document.getElementById(formId)?.addEventListener('submit', submitForm);
    const toggle = document.getElementById(toggleId);
    if (toggle) {
      toggle.checked = false;
      toggleContravSection(false);
      toggle.addEventListener('change', () => toggleContravSection(toggle.checked));
    }
    // (Optionnel) Préviews photos contravention
    const photos = document.getElementById('c_photos');
    const preview = document.getElementById('c_photos_preview');
    photos?.addEventListener('change', () => {
      if (!preview) return;
      preview.innerHTML = '';
      [...photos.files].forEach(f => {
        const url = URL.createObjectURL(f);
        preview.insertAdjacentHTML('beforeend', `<div class="col-3"><img src="${url}" class="img-fluid rounded border" /></div>`);
      });
    });
  }

  document.addEventListener('DOMContentLoaded', init);
})();
</script>
```

## Routes côté serveur
- Sans contravention: `POST /create-entreprise` → `EntrepriseController::create($data, $files)`
- Avec contravention: `POST /create-entreprise-with-contravention` → `EntrepriseController::createWithContravention($data, $files)`
  - Utilise une transaction: création entreprise puis contravention liée
  - Gère upload des photos contravention via le système existant

## Payload attendu (principaux champs)
- Entreprise:
  - `raison_sociale` (required), `rccm`, `id_nat`, `num_impot`
  - `adresse` (required), `telephone`, `email`, `type_activite`
  - `representant_legal`, `telephone_representant`, `personne_contact`, `telephone_contact`, `notes`
  - Fichiers: `logo`, `document` (optionnels)
- Contravention (si switch ON; préfixe `contrav_`):
  - `contrav_date_heure`, `contrav_lieu`, `contrav_type_infraction` (required)
  - `contrav_reference_loi`, `contrav_montant`, `contrav_description`, `contrav_payee`
  - Fichiers: `contrav_photos[]` (multiples)

## Réponses JSON (exemples)
```json
{ "status": "success", "entreprise_id": 123 }
```
```json
{ "status": "success", "entreprise_id": 123, "contravention_id": 456 }
```
```json
{ "status": "error", "message": "Un agent avec ce matricule existe déjà" }
```

## UX/Validation
- **Requis**: `raison_sociale`, `adresse`, et `contrav_type_infraction` si switch activé
- **Soumission**: bouton désactivé + spinner pendant la requête
- **Feedback**: alertes dans `#ent_alert_container`
- **Section contravention**: masquée par défaut; contrôlée par le switch

## Sécurité
- Requêtes préparées côté serveur
- Validation server-side des champs requis
- Validation des fichiers (types/tailles) pour `logo`, `document`, `contrav_photos[]`
- Journalisation des actions (ActivityLogger)
- Routes protégées par authentification

## Checklist QA
- Ouverture/fermeture du modal et reset des champs
- Soumission OK/KO (erreurs remontées)
- Switch contravention: ON/OFF bascule la section
- Uploads: prévisualisation et envoi
- Transaction lors de la création avec contravention
- Ouverture de la prévisualisation contravention si applicable

## Améliorations futures
- Détection de doublons par raison sociale + RCCM/ID Nat
- Autocomplete d’adresse
- Historique/notes internes
- Champs personnalisables par secteur d’activité
