# Tests manuels UI — MAS de Fès

## Prérequis

1. **MySQL** (XAMPP) démarré, base `clubdb` accessible.
2. **Backend** sur le port **8084** :
   ```powershell
   cd backend
   java -jar target\clubbackend-0.0.1-SNAPSHOT.jar
   ```
   Vérification : `http://localhost:8084/api/auth/login` répond (POST avec email/mot de passe).
3. **Application mobile** :
   ```powershell
   cd mobile
   flutter run
   ```
   - **Windows / Web** : `localhost:8084` (déjà configuré).
   - **Émulateur Android** : `10.0.2.2:8084` (déjà configuré).
   - **Téléphone physique** : modifier `mobile/lib/config/api_config.dart` → IP LAN du PC (ex. `192.168.1.x`).

## Comptes de test

| Rôle       | Email                      | Mot de passe |
|------------|----------------------------|--------------|
| Admin      | admin@gmail.com            | password     |
| Encadrant  | coach.gamondi@gmail.com    | password     |
| Adhérent   | member@gmail.com           | password     |
| Joueur     | joueur1@gmail.com          | password     |

Cocher **OK** ou **KO** pour chaque test. Noter les anomalies (message d’erreur, écran blanc, crash).

---

## 1. Authentification (tous rôles)

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 1.1 | Ouvrir l’app | Écran **MAS DE FÈS**, champs Email / Mot de passe, bouton **SE CONNECTER** | |
| 1.2 | Connexion sans email | Message de validation « Veuillez entrer votre email » | |
| 1.3 | Email invalide (sans @) | Message « Email invalide » | |
| 1.4 | Mot de passe vide | Message « Veuillez entrer votre mot de passe » | |
| 1.5 | Mauvais identifiants | Snackbar rouge, reste sur l’écran de connexion | |
| 1.6 | Bon identifiants Admin | Redirection vers **Accueil** (titre avec rôle ADMIN) | |
| 1.7 | Bouton **Pas encore de compte ?** | Écran d’inscription | |
| 1.8 | Inscription (email nouveau) | Message succès, retour connexion ; en base rôle **ADHERENT** (pas INSCRIT) | |
| 1.9 | Icône thème clair/sombre | Le thème change visuellement | |
| 1.10 | Déconnexion (icône logout) | Retour écran de connexion | |

---

## 2. Admin (`admin@gmail.com`)

### Navigation basse
| # | Onglet | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 2.1 | Accueil | Grille d’actions (Stats, Utilisateurs, Équipes, …) | |
| 2.2 | Équipes | Liste des équipes sans erreur | |
| 2.3 | Joueurs | Liste des joueurs | |
| 2.4 | Messages | Écran messagerie **admin** (broadcast / privé) | |
| 2.5 | Utilisateurs | Liste des utilisateurs (pas de rôle INSCRIT) | |

### Actions accueil
| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 2.6 | Stats Dashboard | Statistiques / graphiques chargés | |
| 2.7 | Utilisateurs | Liste + bouton ajouter utilisateur | |
| 2.8 | Ajouter utilisateur | Choix rôle : Joueur, Encadrant, Adhérent (**pas Inscrit**) | |
| 2.9 | Créer un Adhérent (étape 1→2) | Utilisateur créé, upload documents si demandé | |
| 2.10 | Équipes / Joueurs / Entraînements / Matchs | Listes affichées, pas de crash | |
| 2.11 | Cotisations | Liste des cotisations | |
| 2.12 | Messages → Broadcast | Envoi message à tous, pas d’erreur | |
| 2.13 | Messages → Message privé | Envoi à un utilisateur choisi | |
| 2.14 | Badge notifications | Compteur visible, ouverture liste notifications | |
| 2.15 | Modifier rôle d’un utilisateur | Liste déroulante : ADMIN, ENCADRANT, ADHERENT, JOUEUR | |

---

## 3. Encadrant (`coach.gamondi@gmail.com`)

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 3.1 | Accueil | Dashboard encadrant (Bonjour, stats, gestion d’équipe) | |
| 3.2 | Mes Équipes | Équipes liées à l’encadrant | |
| 3.3 | Joueurs | Liste joueurs | |
| 3.4 | Entraînements | Liste / gestion séances | |
| 3.5 | Matchs | Liste des matchs | |
| 3.6 | Messages | Messagerie équipe (pas écran admin) | |
| 3.7 | Onglets bas : Équipes, Joueurs, Messages, Profil | Navigation fluide | |
| 3.8 | Pas d’accès Utilisateurs admin | Pas de menu admin complet si on teste URL manuelle | |

---

## 4. Adhérent (`member@gmail.com`)

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 4.1 | Accueil | Dashboard adhérent (statut cotisation, Mon Espace) | |
| 4.2 | Équipes | Liste équipes en lecture | |
| 4.3 | Mes Entraînements | Séances visibles | |
| 4.4 | Calendrier | Calendrier affiché | |
| 4.5 | Mes Cotisations | Cotisations de l’utilisateur connecté uniquement | |
| 4.6 | Mon Profil | Infos profil + section cotisation | |
| 4.7 | Messages | Annonces / conversation avec admin | |
| 4.8 | Envoyer message à l’admin | Message envoyé sans erreur | |

---

## 5. Joueur (`joueur1@gmail.com`)

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 5.1 | Accueil | Grille actions (Équipes, Mes Entraînements, Calendrier, …) | |
| 5.2 | Mes Cotisations | Uniquement ses cotisations | |
| 5.3 | Mes Entraînements | Planning joueur | |
| 5.4 | Messages | Accès messagerie équipe | |
| 5.5 | Profil | Affichage correct du rôle JOUEUR | |

---

## 6. Transversal

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 6.1 | Aucun écran « Inscrit » / « En attente de validation » | Espace INSCRIT supprimé | |
| 6.2 | Pull-to-refresh ou rechargement listes | Données se rafraîchissent | |
| 6.3 | Rotation écran (mobile) | Pas de crash, layout acceptable | |
| 6.4 | Retour arrière (bouton système) | Navigation cohérente | |

---

## 7. Compte en activation (optionnel)

Si vous avez un compte `ACTIVATION_REQUISE` :

| # | Action | Résultat attendu | OK/KO |
|---|--------|------------------|-------|
| 7.1 | Login compte non activé | Redirection écran **activation** (token) | |
| 7.2 | Définir mot de passe + activer | Connexion automatique ou retour login OK | |

---

## Rapport de fin

- **Date :** _______________
- **Plateforme :** Windows / Android / Web / iOS
- **Tests OK :** _____ / _____
- **Bugs trouvés :**

| Écran | Étapes | Comportement observé | Gravité |
|-------|--------|----------------------|---------|
|       |        |                      |         |

---

## Relancer les tests API (complément)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\smoke_test_api.ps1
```
