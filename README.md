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
- **Fiche scène** : performeurs, studio, tags, galeries, marqueurs,
  description, informations techniques du fichier, note (étoiles) et
  compteur O modifiables.
- **Lecteur vidéo** : reprise là où vous vous étiez arrêté, double-tap
  ±10 s, saut aux marqueurs (repères sur la barre de progression), vitesse
  de lecture, choix du flux (direct ou transcodé HLS/DASH/MP4) avec bascule
  automatique sur un flux transcodé si le codec n'est pas supporté.
  La position et le temps de visionnage sont renvoyés à Stash.
- **Performeurs**, **studios**, **tags** : fiches détaillées avec leurs
  scènes, galeries, marqueurs ; ajout/retrait des favoris (performeurs).
- **Galeries** : grille d'images et visionneuse plein écran (glisser,
  pincer pour zoomer, double-tap).
- **Marqueurs** : liste de tous les marqueurs, lecture directe au bon moment.

## Installation

### APK précompilé

Chaque push déclenche le workflow GitHub Actions *Build APK* : téléchargez
l'artefact `stash-android-apk` depuis l'onglet **Actions** du dépôt et
installez l'APK correspondant à votre appareil (en général
`app-arm64-v8a-release.apk`).

### Compiler soi-même

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) (stable)
et le SDK Android.

```bash
flutter pub get
flutter run                 # sur un appareil connecté
flutter build apk --release # APK dans build/app/outputs/flutter-apk/
```

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
