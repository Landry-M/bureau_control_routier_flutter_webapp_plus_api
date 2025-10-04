# API Routes Reference

Base URL (single entrypoint):
- http://localhost/api/routes/index.php?route=

Example: POST http://localhost/api/routes/index.php?route=/auth/login

Note: All routes below are relative to the `route` query parameter shown above.

## Auth
- POST /auth/login
  - Body (JSON): { "matricule": string, "password": string }
  - Returns: token, role, username, first_connection, user
- POST /auth/first-connection
  - Body (JSON): { "user_id": string|number, "new_password": string, "confirm_password": string }
- POST /auth/change-password
- POST /auth/reset-password

## Users
- GET /users
- POST /users/create
  - Body (JSON): { "nom", "matricule", "poste", "role", "password", "telephone"?, "schedules"? }
- POST /users/{id}/update

## Véhicule
- POST /vehicule/create
  - Multipart form fields: véhicule + assurance + DGI + plaque
  - Files: vehicle_images[] (images), contravention_images[] (si contravention)
- POST /create-vehicule-with-contravention
  - Multipart similaire à /vehicule/create (inclut directement la contravention)
- POST /vehicule/{id}/update
- POST /vehicule/{id}/retirer
- POST /vehicule/{id}/remettre
- GET  /vehicule/{plaque}

## Particulier
- POST /particulier/create
- POST /particulier/{id}/update
- GET  /particulier/{id}

## Entreprise
- POST /entreprise/create
- POST /entreprise/{id}/update
- GET  /entreprise/{id}

## Contravention
- POST /contravention/create
- GET  /contravention/{id}
- GET  /contravention/{id}/pdf

## Accident
- POST /accident/create
- POST /accident/{id}/update
- GET  /accident/{id}

## Avis de recherche
- POST /avis-recherche/create
- POST /avis-recherche/{id}/close
- GET  /avis-recherche/{id}

## Permis temporaire
- POST /permis-temporaire/create
- GET  /permis-temporaire/{id}/pdf

## Arrestation
- POST /arrestation/create
- POST /arrestation/{id}/release
- GET  /particulier/{id}/arrestations

## Logs
- GET  /logs
  - Query: limit (int, default 100), offset (int, default 0), username (string?), action (string?)
- GET  /logs/stats
  - Query: days (int, default 30)
- POST /logs/add

## Base de données
- GET  /schema

---

## Exemples rapides

Authentification (login):

```bash
curl -X POST \
  'http://localhost/api/routes/index.php?route=/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"matricule":"admin","password":"password123"}'
```

Récupération logs:

```bash
curl 'http://localhost/api/routes/index.php?route=/logs&limit=50&offset=0'
```

---

## Processus de mise à jour de cette documentation
- À chaque ajout/modification de route dans `api/routes/index.php`, ajouter la route ici dans la section correspondante.
- Garder descriptions concises (méthode, chemin, paramètres principaux).
- Optionnel: ajouter un exemple `curl` pour les nouvelles routes importantes.
