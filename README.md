# PKMonitor

[FR](README.md) · [EN](README_en.md)

Moniteur système macOS natif dans la barre des menus. Sparkline temps réel,
jauges GPU/CPU/RAM/NET cliquables, détail des applications responsables avec
arrêt forcé, et réglages complets.

## Fonctionnalités

- Sparkline temps réel (200 ms par défaut, configurable)
- Mesures CPU, GPU, RAM et réseau (download/upload séparés)
- Quatre jauges cliquables pour basculer la métrique affichée
- Icônes des applications dominantes sur la courbe
- Détail au survol avec arrêt (SIGTERM) ou force kill (SIGKILL)
- Ouverture de Moniteur d'activité filtré par PID
- Seuils de couleur configurables (warning/critical)
- Libellé vertical et jauges positionnables (gauche/droite)
- Lancement à la connexion
- Emplacement de l'icône : menu barre ou seconde barre personnalisable (pilule à droite : fond None/Tint/Hover/Blur, couleur libre, marges 4 côtés, contenu clair/sombre/auto)
- Thème clair/sombre/système

## Utilisation

- Survol : ouvrir le détail sous la barre des menus
- Clic gauche : épingler/détacher le panneau
- Clic droit : menu contextuel avec métriques et réglages
- Clic sur une jauge : basculer vers cette métrique
- Bouton ✕ : quitter le processus (SIGTERM)
- Bouton 💀 : forcer l'arrêt (SIGKILL)

## Réglages

La fenêtre Réglages (clic droit > Settings…) propose :

- **General** : fréquence, historique, top d'icônes, survol, emplacement de l'icône, lancement auto, seuils de couleur
- **Appearance** : largeur/épaisseur de courbe, taille d'icônes, bordure, position du texte et des jauges, thème
- **About** : version et informations

## Build & Package

```sh
chmod +x run.sh
./run.sh
```

Le script construit `dist/PKMonitor.app` puis le lance. Requiert macOS 13+ et
les outils de ligne de commande Xcode.

## Voir le [CHANGELOG](CHANGELOG.md) pour l'historique complet.
