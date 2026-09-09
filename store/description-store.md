# PKMonitor — store copy

Version : `2026.09.29`

## Tagline FR
Le moniteur système macOS discret dans la barre des menus.

## Tagline EN
A focused macOS system monitor in your menu bar.

## Description courte FR
CPU, GPU, RAM, réseau et espace disque dans une barre des menus configurable.

## Description courte EN
Configurable menu bar monitoring for CPU, GPU, RAM, network and disk space.

## Description longue FR
PKMonitor affiche les métriques essentielles de votre Mac dans une interface compacte : sparkline temps réel avec icônes des applications dominantes, jauges activables et réordonnables (CPU, GPU, RAM, disque en deux lignes, réseau download/upload), panneau de détail au survol avec arrêt des processus. À la Bartender, descendez n'importe quelle icône de la barre des menus dans la seconde barre : cases à cocher, ordre réglable, clic transféré vers le menu d'origine. À la demande, le conseiller IA analyse les processus gourmands via votre endpoint compatible OpenAI : tableau, légitimité estimée selon nom/bundle/chemin, motifs des alertes et recommandations. La clé API reste dans le Keychain et rien n'est envoyé avant une analyse explicite.

## Description longue EN
PKMonitor shows your Mac's essential metrics in a compact interface: real-time sparkline with dominant app icons, reorderable toggles gauges (CPU, GPU, RAM, two-line disk, download/upload network), and a hover detail panel to quit processes. Bartender-style: lower any menu bar icon into the second bar with checkboxes, set their order, and clicks open the original menu. On demand, the AI advisor analyzes heavy processes through your OpenAI-compatible endpoint: a table, estimated legitimacy from name/bundle/path, alert rationale and recommendations. The API key remains in the Keychain and nothing is sent before an explicit analysis.

## Tags
macOS, menu bar, second bar, bartender, system monitor, CPU, GPU, RAM, disk, network, SwiftUI, status items, AI advisor, OpenAI-compatible

## FAQ

- **macOS requis ?** macOS 13 ou ultérieur.
- **Les données quittent-elles le Mac ?** Par défaut non. Une analyse IA envoie uniquement à l'endpoint configuré les métriques, noms, bundle identifiers et chemins des applications concernées, après un clic explicite ; la clé API reste dans le Keychain.
- **Descendre des icônes tierces ?** Oui — Settings › Menu Bar Items : cochez les icônes à descendre, réordonnez-les, et PKMonitor les restaure au décochage ou à la fermeture.
- **Permissions nécessaires ?** Accessibilité (déplacer les icônes d'origine) et Enregistrement d'écran (redessiner les icônes descendues), demandées uniquement pour cette fonctionnalité.

## Offre

- **Modèle** : Open Source
- **Prix** : Gratuit

## Plateformes

- GitHub Releases : https://github.com/mondary/PKmonitor

## Liens

- **Repo** : https://github.com/mondary/PKmonitor
