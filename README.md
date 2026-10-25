# Stash Android

Client Android pour [Stash](https://github.com/stashapp/stash), écrit en
Flutter. Inspiré de [StashAppAndroidTV](https://github.com/damontecres/StashAppAndroidTV),
mais pensé pour les téléphones et tablettes (écran tactile).

L'application dialogue directement avec l'API GraphQL de votre serveur Stash :
aucun service tiers, aucune donnée n'est envoyée ailleurs.

## Fonctionnalités

- **Accueil** : reprendre la lecture, scènes ajoutées récemment, sorties
  récentes, performeurs favoris, sélection aléatoire, galeries récentes et
  statistiques de la bibliothèque.
- **Scènes** : grille avec défilement infini, recherche, tri (date d'ajout,
  date, titre, note, lectures, compteur O, durée, taille, aléatoire),
  aperçu vidéo par appui long.
- **Filtres par champ** : performeurs, tags, studio, groupes (au moins un /
  tous / aucun de / vide / non vide, avec sous-tags, sous-studios et
  sous-groupes), note minimale, résolution minimale, durée, déjà vues ou
  jamais vues, organisées, marqueurs, performeur favori.
- **Vues enregistrées** : une recherche + filtres + tri peut être enregistrée
  (icône signet) et choisie comme page d'accueil ; l'accueil par défaut reste
  accessible par le bouton en haut à droite. Les vues apparaissent aussi en
  lignes sur l'accueil par défaut. Gestion dans **Plus > Vues enregistrées**.
  Exemple : « Groupes : Vide » affiche toutes les scènes hors groupe.
- **Groupes** : onglet dédié, fiche avec jaquettes et scènes dans l'ordre du
  groupe.
- **Fiche scène** : performeurs, studio, tags, galeries, marqueurs,
  description, informations techniques du fichier, note (étoiles) et
  compteur O modifiables.
- **Lecteur vidéo** : reprise là où vous vous étiez arrêté, double-tap
  ±10 s, saut aux marqueurs (repères sur la barre de progression), vitesse
  de lecture, choix du flux (direct ou transcodé HLS/DASH/MP4) avec bascule
  automatique sur un flux transcodé si le codec n'est pas supporté.
  La position et le temps de visionnage sont renvoyés à Stash.
- **Performeurs**, **studios**, **tags**, **galeries** (dans **Plus**) : fiches détaillées avec leurs
  scènes, galeries, marqueurs ; ajout/retrait des favoris (performeurs).
- **Galeries** : grille d'images et visionneuse plein écran (glisser,
  pincer pour zoomer, double-tap).
- **Marqueurs** : liste de tous les marqueurs, lecture directe au bon moment.

## Installation

### Compiler l'APK

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) (stable)
et le SDK Android (le plus simple : installer Android Studio, puis lancer
`flutter doctor --android-licenses`).

```bash
flutter pub get
flutter run                 # sur un appareil connecté
flutter build apk --release --split-per-abi
```

Les APK se trouvent dans `build/app/outputs/flutter-apk/` ; pour la plupart
des téléphones récents, installez `app-arm64-v8a-release.apk`.

### Signature

Les APK de release sont signés avec la clé décrite par `android/key.properties`
(fichier et keystore exclus de git) :

```properties
storePassword=…
keyPassword=…
keyAlias=stash
storeFile=../stash-release.jks
```

Placez `stash-release.jks` et `key.properties` dans `android/` avant de
compiler. Sans eux, l'APK est signé avec la clé de debug et ne pourra pas
mettre à jour une version installée signée avec la clé de release.
**Conservez la clé en lieu sûr** : si elle est perdue, il faudra désinstaller
l'application pour installer une nouvelle version.

## Configuration

1. Au premier lancement, saisissez l'adresse de votre serveur, par exemple
   `http://192.168.1.10:9999`.
2. Si l'authentification est activée sur Stash, générez une clé API dans
   **Paramètres > Sécurité > Clé API** et collez-la dans l'application.

Le trafic HTTP en clair est autorisé pour pouvoir joindre un serveur local ;
utilisez HTTPS (reverse proxy) si votre serveur est exposé sur Internet.

## Structure du code

```
lib/
  api/stash_client.dart      Client GraphQL (auth par clé API, URLs média)
  api/stash_repository.dart  Requêtes et mutations Stash
  models/models.dart         Scene, Performer, Studio, Tag, Gallery…
  services/app_state.dart    Configuration du serveur et préférences
  screens/                   Écrans (accueil, listes, fiches, lecteur…)
  widgets/                   Cartes, grille paginée, images réseau…
test/                        Tests unitaires et de widgets
```

## Licence

Projet indépendant, non affilié à l'équipe Stash.
