# PKMonitor

[FR](README.md) · [EN](README_en.md)

Prototype natif macOS inspiré d'ActivityLine. Il affiche une sparkline et une
métrique système dans la barre des menus. Les icônes des applications dominantes
du top 5 naissent sur les pics puis se déplacent avec l'historique, sans envoyer
les mesures hors du Mac.

## Lancer

```sh
chmod +x run.sh
./run.sh
```

Le script construit `dist/PKMonitor.app` puis le lance. Il requiert macOS 13 ou
plus récent et les outils de ligne de commande Xcode.

## Utilisation

- Survol ou clic gauche : ouvrir le détail sous la barre des menus.
- Clic droit : choisir une métrique, activer le lancement à la connexion ou quitter.
- Le nom de la métrique est empilé verticalement dans la barre des menus.
- Chaque application peut être localisée dans Moniteur d'activité ou arrêtée après confirmation.

## Réglages

La fenêtre Réglages propose la fréquence d'actualisation, la durée d'historique,
le nombre d'icônes, l'ouverture au survol, le lancement à la connexion, la largeur
et l'épaisseur de la courbe, la taille des icônes et le thème du panneau.

CPU, RAM et réseau utilisent les API système locales. macOS ne fournit pas de
métrique GPU publique et stable : le mode GPU affiche donc `N/A` dans ce prototype.

Voir le [CHANGELOG](CHANGELOG.md) pour l'historique complet.
