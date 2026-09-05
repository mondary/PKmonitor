# PKMonitor — store copy

Version : `2026.09.23`

## Tagline FR
Le moniteur système macOS discret dans la barre des menus.

## Tagline EN
A focused macOS system monitor in your menu bar.

## Description courte FR
CPU, GPU, RAM, réseau et espace disque dans une barre des menus configurable.

## Description courte EN
Configurable menu bar monitoring for CPU, GPU, RAM, network and disk space.

## Description longue FR
PKMonitor affiche les métriques essentielles de votre Mac dans une interface compacte : sparkline temps réel avec icônes des applications dominantes, jauges activables et réordonnables (CPU, GPU, RAM, disque en deux lignes, réseau download/upload), panneau de détail au survol avec arrêt des processus. À la Bartender, descendez n'importe quelle icône de la barre des menus dans la seconde barre : cases à cocher, ordre réglable, clic transféré vers le menu d'origine. Les réglages restent locaux, chaque module peut être affiché ou masqué, et les icônes d'origine sont restaurées à la sortie.

## Description longue EN
PKMonitor shows your Mac's essential metrics in a compact interface: real-time sparkline with dominant app icons, reorderable toggles gauges (CPU, GPU, RAM, two-line disk, download/upload network), and a hover detail panel to quit processes. Bartender-style: lower any menu bar icon into the second bar with checkboxes, set their order, and clicks open the original menu. Everything stays local, every module can be shown or hidden, and original icons are restored on quit.

## Tags
macOS, menu bar, second bar, bartender, system monitor, CPU, GPU, RAM, disk, network, SwiftUI, status items

## FAQ

- **macOS requis ?** macOS 13 ou ultérieur.
- **Les données quittent-elles le Mac ?** Non, toutes les mesures restent locales.
- **Descendre des icônes tierces ?** Oui — Settings › Menu Bar Items : cochez les icônes à descendre, réordonnez-les, et PKMonitor les restaure au décochage ou à la fermeture.
- **Permissions nécessaires ?** Accessibilité (déplacer les icônes d'origine) et Enregistrement d'écran (redessiner les icônes descendues), demandées uniquement pour cette fonctionnalité.
