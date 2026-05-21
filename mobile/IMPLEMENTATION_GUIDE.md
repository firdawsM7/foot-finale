# Club Foot - Application Mobile Flutter

## 🎨 Palette de Couleurs Moderne
- **Jaune Principal**: `#FFC107` (Amber)
- **Noir**: `#212121` (Almost Black)
- **Blanc**: `#FFFFFF`
- **Gris Foncé**: `#424242`
- **Gris Clair**: `#757575`

## ✅ Fichiers Déjà Créés
1. `main.dart` - Thème moderne jaune/noir/blanc appliqué
2. `login_screen.dart` - Écran de connexion moderne avec gradient et animations

## 📝 Prochaines Étapes - Écrans à Créer

### 1. Écran d'inscription (register_screen.dart)
Créer un formulaire d'inscription moderne avec:
- Photo de profil (optionnelle)
- Champs: nom, prénom, email, téléphone, adresse, date de naissance, mot de passe
- Design cohérent avec login_screen
- Validation des champs

### 2. Home Screen Amélioré
Améliorer `home_screen.dart` avec:
- Cartes d'action fonctionnelles qui naviguent vers les écrans appropriés
- Statistiques en temps réel (nombre de joueurs, matchs à venir, etc.)
- Design moderne avec la palette jaune/noir/blanc

### 3. Écrans pour ADMIN
Créer dans `screens/`:

#### `users/users_screen.dart`
- Liste de tous les utilisateurs avec recherche
- Bouton d'ajout (+) flottant jaune
- Filtres par rôle (ADMIN, ENCADRANT, ADHERENT, JOUEUR)
- Card pour chaque utilisateur avec photo, nom, email, rôle
- Actions: Activer/Désactiver, Modifier rôle, Supprimer
- Bottom Sheet pour édition rapide

#### `joueurs/joueurs_screen.dart`
- Grille de cartes de joueurs avec photos
- Recherche et filtre par poste, équipe
- Fiche détaillée de joueur (dialog ou nouvelle page)
- Formulaire d'ajout/édition
- Statistiques par joueur

#### `equipes/equipes_screen.dart`
- Liste des équipes avec nombre de joueurs
- Création/édition d'équipe
- Assignment d'encadrant
- Vue détaillée avec liste des joueurs de l'équipe

#### `entrainements/entrainements_screen.dart`
- Calendrier des entraînements
- Création rapide d'entraînement
- Changement de statut (PLANIFIE, EN_COURS, TERMINE, ANNULE)
- Détails: équipe, lieu, durée, objectif, exercices

#### `matchs/matchs_screen.dart`
- Liste des matchs avec résultats
- Création de match
- Scorekeeper pour matchs EN_COURS
- Historique et statistiques

#### `cotisations/cotisations_screen.dart`
- Liste des cotisations par adhérent
- Enregistrement de paiement
- Filtres: payé/impayé, mode de paiement
- Statistiques financières

### 4. Écrans pour ENCADRANT
Créer les mêmes écrans mais avec restrictions:
- Voir uniquement ses équipes
- Gérer ses joueurs
- Planifier/modifier ses entraînements et matchs
- Pas d'accès aux utilisateurs ni cotisations

### 5. Écrans pour ADHERENT
- Voir toutes les équipes
- Voir calendrier des événements
- Voir ses cotisations
- Profil personnel éditable

## 🎯 Fonctionnalités par Écran

### Pattern de Design à Suivre:
```dart
// Structure standard d'un écran de liste
Scaffold(
  appBar: AppBar(
    title: Text('Titre'),
    actions: [SearchButton, FilterButton],
  ),
  body: RefreshIndicator(
    onRefresh: _loadData,
    child: ListView/GridView,
  ),
  floatingActionButton: FloatingActionButton(
    backgroundColor: Color(0xFFFFC107),
    foregroundColor: Color(0xFF212121),
    child: Icon(Icons.add),
    onPressed: _showAddDialog,
  ),
)
```

### Card Design Standard:
```dart
Card(
  elevation: 3,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: InkWell(
    onTap: () => _showDetails(),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et actions
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFFFC107).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.xxx, color: Color(0xFFFFC107)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Titre', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Sous-titre', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              // Actions
            ],
          ),
          SizedBox(height: 12),
          // Contenu
        ],
      ),
    ),
  ),
)
```

## 🔧 Composants Réutilisables à Créer

### 1. `widgets/custom_app_bar.dart`
AppBar personnalisée avec gradient et actions

### 2. `widgets/stat_card.dart`
Carte de statistique (nombre de joueurs, matchs gagnés, etc.)

### 3. `widgets/player_card.dart`
Card pour afficher un joueur

### 4. `widgets/match_card.dart`
Card pour afficher un match avec score

### 5. `widgets/empty_state.dart`
Widget d'état vide avec icône et message

### 6. `widgets/loading_widget.dart`
Widget de chargement personnalisé

## 📱 Navigation

### Bottom Navigation Bar (pour tous les rôles):
- Index 0: Accueil/Dashboard
- Index 1: Équipes
- Index 2: Joueurs
- Index 3: Profil (ou Utilisateurs pour ADMIN)

### Drawer (Menu latéral optionnel):
- Profil
- Paramètres
- À propos
- Déconnexion

## 🎨 Exemples de Couleurs à Utiliser

```dart
// Couleurs principales
const primaryYellow = Color(0xFFFFC107);
const darkBackground = Color(0xFF212121);
const lightGray = Color(0xFFF5F5F5);

// Couleurs de statut
const statusPlanned = Color(0xFF2196F3);    // Bleu
const statusInProgress = Color(0xFFFFC107); // Jaune
const statusCompleted = Color(0xFF4CAF50);  // Vert
const statusCanceled = Color(0xFFF44336);   // Rouge

// Couleurs de postes (football)
const goalkeeper = Color(0xFF9C27B0);    // Violet
const defender = Color(0xFF2196F3);      // Bleu
const midfielder = Color(0xFF4CAF50);    // Vert
const forward = Color(0xFFF44336);       // Rouge
```

## 🚀 Pour Lancer le Projet

### 1. Backend
```bash
cd backend
./mvnw spring-boot:run
```

### 2. Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## 📊 Données de Test

### Utilisateurs:
- **Admin**: admin@club.com / password
- **Encadrant**: coach@club.com / password
- **Adhérent**: member@club.com / password

### API Endpoints (vérifier dans `api_config.dart`):
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';  // Pour émulateur Android
// ou
static const String baseUrl = 'http://localhost:8080/api';  // Pour iOS simulator
```

## 🎯 Priorités de Développement

1. **Urgent**: Terminer register_screen.dart
2. **Important**: Créer users_screen.dart pour l'ADMIN
3. **Important**: Créer joueurs_screen.dart
4. **Moyen**: Créer equipes_screen.dart
5. **Moyen**: Créer matchs_screen.dart et entrainements_screen.dart
6. **Faible**: Cotisations et statistiques avancées

## 💡 Conseils

1. **Consistance**: Utilisez toujours la même palette de couleurs
2. **Animations**: Ajoutez des transitions douces (Hero animations pour les images)
3. **Feedback**: Toujours donner un feedback visuel (SnackBars, Dialogs)
4. **Loading States**: Gérer les états de chargement avec CircularProgressIndicator
5. **Error Handling**: Afficher des messages d'erreur clairs
6. **Pull to Refresh**: Implementer sur toutes les listes
7. **Empty States**: Afficher des messages et icônes quand il n'y a pas de données

## 📚 Resources Utiles

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)

---

**Note**: Le projet est maintenant bien structuré avec une palette moderne. Il suffit de créer les écrans manquants en suivant le pattern de design établi dans login_screen.dart.
